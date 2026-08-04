import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const json=(body:any,status=200)=>new Response(JSON.stringify(body),{status,headers:{'content-type':'application/json'}});
const esc=(s:string)=>String(s||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]!));

Deno.serve(async req=>{
  if(req.method!=='POST')return json({error:'método inválido'},405);
  const token=(req.headers.get('authorization')||'').replace(/^Bearer\s+/i,'');
  const admin=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const {data:{user}}=await admin.auth.getUser(token);
  if(!user)return json({error:'não autorizado'},401);
  const {pessoa_id,escola_id,papel}=await req.json();
  const {data:autor}=await admin.from('pessoas').select('id').eq('auth_user_id',user.id).maybeSingle();
  const {data:permissao}=autor?await admin.from('vinculos').select('id').eq('pessoa_id',autor.id).eq('escola_id',escola_id).eq('ativo',true).in('papel',['admin','gestor']).limit(1).maybeSingle():{data:null};
  if(!permissao)return json({error:'sem permissão'},403);
  const [{data:pessoa},{data:escola}]=await Promise.all([
    admin.from('pessoas').select('id,nome,email,auth_user_id').eq('id',pessoa_id).single(),
    admin.from('escolas').select('nome').eq('id',escola_id).single()
  ]);
  if(!pessoa?.email)return json({error:'cadastro sem e-mail'},400);
  let authUid=pessoa.auth_user_id as string|null;
  if(!authUid){
    const {data:usuarios,error:erroUsuarios}=await admin.auth.admin.listUsers({page:1,perPage:1000});
    if(erroUsuarios)return json({error:'não foi possível conferir o acesso existente'},502);
    const existente=(usuarios?.users||[]).find((u:any)=>String(u.email||'').toLowerCase()===String(pessoa.email).toLowerCase());
    if(existente){
      authUid=existente.id;
      const {error:erroVinculo}=await admin.from('pessoas').update({auth_user_id:authUid}).eq('id',pessoa.id).is('auth_user_id',null);
      if(erroVinculo)return json({error:'não foi possível vincular o acesso ao cadastro'},502);
    }
  }
  const tipo=authUid?'recovery':'invite';
  const {data:link,error}=await admin.auth.admin.generateLink({type:tipo,email:pessoa.email,options:{redirectTo:'https://modox.com.br/app/',data:{nome:pessoa.nome,origem:'equipe_modox',papel}}});
  if(error||!link?.properties?.action_link)return json({error:error?.message||'não foi possível criar o acesso'},400);
  if(tipo==='invite'){
    const novoUid=link.user?.id;
    if(!novoUid)return json({error:'o acesso foi criado sem identificação'},502);
    const {error:erroVinculo}=await admin.from('pessoas').update({auth_user_id:novoUid}).eq('id',pessoa.id).is('auth_user_id',null);
    if(erroVinculo){
      await admin.auth.admin.deleteUser(novoUid).catch(()=>{});
      return json({error:'não foi possível vincular o acesso ao cadastro'},502);
    }
  }
  const professor=papel==='professor';
  const titulo=professor?`Professor(a) ${esc(pessoa.nome.split(/\s+/)[0])}, sua sala no MODOX está pronta`:`Seu acesso à gestão de ${esc(escola?.nome||'sua instituição')} está pronto`;
  const texto=professor
    ? `Você foi recebido como professor(a) de <b>${esc(escola?.nome||'sua instituição')}</b>. Ao entrar, encontrará suas turmas, alunos, perguntas e pendências pedagógicas — sem telas de contrato ou cobrança.`
    : `Você foi recebido como <b>${papel==='admin'?'administrador(a)':'gestor(a)'}</b> de ${esc(escola?.nome||'sua instituição')}. Seu painel reúne as decisões e pendências necessárias para cuidar da operação.`;
  const html=`<div style="background:#faf9f7;padding:32px 16px;font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif"><div style="max-width:510px;margin:auto;background:#fff;border:1px solid #ececf2;border-radius:20px;padding:34px"><div style="font-size:22px;font-weight:800">MODO<span style="color:#f26a1b">X</span></div><h1 style="font-size:25px;line-height:1.25;margin:25px 0 12px">${titulo}</h1><p style="color:#5d5c65;font-size:15.5px;line-height:1.7">${texto}</p><p style="color:#5d5c65;font-size:15.5px;line-height:1.7">Que bom ter você nesta equipe. Seu trabalho importa, e queremos que a tecnologia deixe o caminho mais leve.</p><a href="${link.properties.action_link}" style="display:block;text-align:center;background:#f26a1b;color:#fff;text-decoration:none;border-radius:999px;padding:15px;margin-top:24px;font-weight:700">${tipo==='invite'?'Criar minha senha e entrar':'Entrar com uma nova senha'}</a><p style="font-size:12.5px;color:#898790;margin-top:22px">Este link é pessoal. Não encaminhe para outra pessoa.</p></div></div>`;
  const envio=await fetch('https://api.brevo.com/v3/smtp/email',{method:'POST',headers:{'api-key':Deno.env.get('BREVO_API_KEY')!,'content-type':'application/json'},body:JSON.stringify({sender:{name:'MODOX',email:'contato@arborlabs.com.br'},to:[{email:pessoa.email,name:pessoa.nome}],subject:professor?'Sua turma espera por você no MODOX':'Seu acesso de gestão ao MODOX',htmlContent:html})});
  if(!envio.ok)return json({error:'não foi possível enviar o convite'},502);
  return json({ok:true,status:tipo==='invite'?'convite_enviado':'recuperacao_enviada'});
});
