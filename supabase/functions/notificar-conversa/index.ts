import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import webpush from 'npm:web-push@3.6.7';

const origem='https://modox.com.br';
const cors={'Access-Control-Allow-Origin':origem,'Access-Control-Allow-Headers':'authorization, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS'};
const resposta=(body:unknown,status=200)=>Response.json(body,{status,headers:cors});

Deno.serve(async(req)=>{
  if(req.method==='OPTIONS')return new Response('ok',{headers:cors});
  if(req.method!=='POST')return resposta({error:'método não permitido'},405);
  try{
    const url=Deno.env.get('SUPABASE_URL')!,anon=Deno.env.get('SUPABASE_ANON_KEY')!,service=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const authHeader=req.headers.get('Authorization')||'';
    const usuario=createClient(url,anon,{global:{headers:{Authorization:authHeader}}});
    const {data:{user},error:authError}=await usuario.auth.getUser();
    if(authError||!user)throw new Erro('não autenticado',401);
    const {conversa_id,mensagem_id}=await req.json().catch(()=>({}));
    if(!uuid(conversa_id)||!uuid(mensagem_id))throw new Erro('mensagem inválida',400);
    const admin=createClient(url,service);
    const {data:autor}=await admin.from('pessoas').select('id,nome').eq('auth_user_id',user.id).single();
    if(!autor)throw new Erro('cadastro não encontrado',403);
    const {data:mensagem}=await admin.from('conversa_mensagens').select('id,conversa_id,autor_id,texto').eq('id',mensagem_id).eq('conversa_id',conversa_id).single();
    if(!mensagem||mensagem.autor_id!==autor.id)throw new Erro('mensagem não pertence ao usuário',403);
    const {data:conversa}=await admin.from('conversas').select('id,turma_id,criada_por,destino,publica').eq('id',conversa_id).single();
    if(!conversa)throw new Erro('conversa não encontrada',404);
    const {data:turma}=await admin.from('turmas').select('id,nome,curso_id,cursos(escola_id)').eq('id',conversa.turma_id).single();
    const escolaId=(turma as any)?.cursos?.escola_id;
    const ids=new Set<string>();
    if(conversa.destino==='turma'){
      const [{data:alunos},{data:professores},{data:equipe}]=await Promise.all([
        admin.from('matriculas').select('pessoa_id').eq('turma_id',conversa.turma_id).in('status',['ativa','concluida']),
        admin.from('turma_professores').select('pessoa_id').eq('turma_id',conversa.turma_id),
        admin.from('vinculos').select('pessoa_id').eq('escola_id',escolaId).eq('ativo',true).in('papel',['gestor','admin']),
      ]);
      [...(alunos||[]),...(professores||[]),...(equipe||[])].forEach((x:any)=>ids.add(x.pessoa_id));
    }else if(autor.id===conversa.criada_por){
      if(conversa.destino==='professor'){
        const {data}=await admin.from('turma_professores').select('pessoa_id').eq('turma_id',conversa.turma_id);
        (data||[]).forEach((x:any)=>ids.add(x.pessoa_id));
      }else{
        const {data}=await admin.from('vinculos').select('pessoa_id').eq('escola_id',escolaId).eq('ativo',true).in('papel',['gestor','admin']);
        (data||[]).forEach((x:any)=>ids.add(x.pessoa_id));
      }
    }else ids.add(conversa.criada_por);
    ids.delete(autor.id);
    const {data:subs}=ids.size?await admin.from('push_inscricoes').select('*').in('pessoa_id',[...ids]):{data:[]};
    webpush.setVapidDetails('mailto:contato@arborlabs.com.br',Deno.env.get('VAPID_PUBLIC_KEY')!,Deno.env.get('VAPID_PRIVATE_KEY')!);
    const payload=JSON.stringify({titulo:conversa.destino==='turma'?'Nova orientação da turma':'Nova mensagem no MODOX',texto:(mensagem.texto||'Há uma nova interação aguardando você.').slice(0,180),conversa_id:conversa.id});
    await Promise.allSettled((subs||[]).map(async(s:any)=>{try{await webpush.sendNotification({endpoint:s.endpoint,keys:{p256dh:s.p256dh,auth:s.auth}},payload);}catch(e){if((e as any)?.statusCode===404||(e as any)?.statusCode===410)await admin.from('push_inscricoes').delete().eq('id',s.id);else throw e;}}));
    return resposta({ok:true,enviadas:(subs||[]).length});
  }catch(e){return resposta({error:e instanceof Error?e.message:'erro inesperado'},e instanceof Erro?e.status:400);}
});

const uuid=(v:unknown)=>/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(String(v||''));
class Erro extends Error{constructor(message:string,public status:number){super(message)}}
