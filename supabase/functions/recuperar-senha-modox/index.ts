import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors={
  'access-control-allow-origin':'https://modox.com.br',
  'access-control-allow-headers':'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods':'POST, OPTIONS',
};
const json=(body:Record<string,unknown>,status=200)=>new Response(JSON.stringify(body),{
  status,headers:{...cors,'content-type':'application/json'},
});
const resposta={ok:true,mensagem:'Se o e-mail estiver cadastrado, enviaremos as instruções de recuperação.'};
const esc=(s:string)=>String(s||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]!));
const sha=async(s:string)=>Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(s))))
  .map(b=>b.toString(16).padStart(2,'0')).join('');

Deno.serve(async req=>{
  if(req.method==='OPTIONS')return new Response('ok',{headers:cors});
  if(req.method!=='POST')return json({error:'método inválido'},405);

  let email='';
  try{email=String((await req.json())?.email||'').trim().toLowerCase()}catch{return json(resposta)}
  if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)||email.length>254)return json(resposta);

  const admin=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const ip=(req.headers.get('x-forwarded-for')||'').split(',')[0].trim();
  const chave=await sha(`${email}|${ip}`);
  const desde=new Date(Date.now()-15*60*1000).toISOString();
  const {count}=await admin.from('recuperacoes_senha').select('id',{count:'exact',head:true})
    .eq('chave',chave).in('status',['recebida','aceita_provedor']).gte('criado_em',desde);
  if((count||0)>=3)return json(resposta);
  const {data:tentativa}=await admin.from('recuperacoes_senha').insert({chave,status:'recebida'}).select('id').single();

  const {data:pessoa}=await admin.from('pessoas').select('id,nome,auth_user_id').ilike('email',email).limit(1).maybeSingle();
  const {data:vinculo}=pessoa?await admin.from('vinculos').select('id').eq('pessoa_id',pessoa.id).eq('ativo',true).limit(1).maybeSingle():{data:null};
  if(!pessoa||!vinculo){
    if(tentativa?.id)await admin.from('recuperacoes_senha').update({status:'sem_conta'}).eq('id',tentativa.id);
    return json(resposta);
  }

  let authUid=pessoa.auth_user_id as string|null;
  if(!authUid){
    const {data:usuarios}=await admin.auth.admin.listUsers({page:1,perPage:1000});
    const existente=(usuarios?.users||[]).find((u:any)=>String(u.email||'').toLowerCase()===email);
    if(existente){
      authUid=existente.id;
      await admin.from('pessoas').update({auth_user_id:authUid}).eq('id',pessoa.id).is('auth_user_id',null);
    }
  }
  const tipo=authUid?'recovery':'invite';
  const {data:link,error}=await admin.auth.admin.generateLink({
    type:tipo,email,options:{redirectTo:'https://modox.com.br/app/',data:{nome:pessoa.nome,origem:'equipe_modox'}},
  });
  if(error||!link?.properties?.action_link){
    if(tentativa?.id)await admin.from('recuperacoes_senha').update({status:'sem_conta'}).eq('id',tentativa.id);
    console.log('Recuperação MODOX sem conta correspondente',{email_hash:(await sha(email)).slice(0,12)});
    return json(resposta);
  }
  if(tipo==='invite'&&link.user?.id){
    const {error:erroVinculo}=await admin.from('pessoas').update({auth_user_id:link.user.id}).eq('id',pessoa.id).is('auth_user_id',null);
    if(erroVinculo){
      await admin.auth.admin.deleteUser(link.user.id).catch(()=>{});
      if(tentativa?.id)await admin.from('recuperacoes_senha').update({status:'falha_provedor'}).eq('id',tentativa.id);
      return json(resposta);
    }
  }

  const nome=String(pessoa.nome||link.user?.user_metadata?.nome||'').trim().split(/\s+/)[0];
  const saudacao=nome?`Olá, ${esc(nome)}.`:'Olá.';
  const html=`<div style="background:#f7f7f8;padding:36px 16px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif"><div style="max-width:520px;margin:auto;background:#fff;border:1px solid #e5e7eb;border-radius:20px;overflow:hidden;color:#141416;box-shadow:0 12px 36px rgba(20,20,22,.08)"><div style="height:6px;background:#f26a1b"></div><div style="padding:32px 30px"><div style="font-size:23px;font-weight:850;letter-spacing:-.5px">MODO<span style="color:#f26a1b">X</span></div><p style="margin:28px 0 8px;color:#c94e0c;font-size:11px;font-weight:800;letter-spacing:.12em;text-transform:uppercase">Acesso seguro</p><h1 style="font-size:26px;line-height:1.2;margin:0 0 12px">${saudacao} ${tipo==='invite'?'Crie sua senha de acesso.':'Vamos recuperar seu acesso.'}</h1><p style="color:#62636b;font-size:15px;line-height:1.65">${tipo==='invite'?'Seu cadastro já estava ativo na instituição. Falta apenas escolher uma senha para entrar no MODOX.':'Recebemos um pedido para criar uma nova senha no MODOX. Use o botão abaixo e escolha uma senha exclusiva.'}</p><a href="${link.properties.action_link}" style="display:block;text-align:center;background:#f26a1b;color:#fff;text-decoration:none;border-radius:12px;padding:15px;margin-top:24px;font-weight:800">${tipo==='invite'?'Criar minha senha':'Criar nova senha'}</a><p style="font-size:12.5px;color:#7b7c84;line-height:1.55;margin-top:22px">Este link é pessoal e temporário. Se você não pediu o acesso, ignore esta mensagem.</p><div style="border-top:1px solid #e5e7eb;margin-top:27px;padding-top:18px;color:#7b7c84;font-size:12px">MODOX · um produto Arbor Labs · desenvolvido no Brasil</div></div></div></div>`;
  const envio=await fetch('https://api.brevo.com/v3/smtp/email',{
    method:'POST',headers:{'api-key':Deno.env.get('BREVO_API_KEY')!,'content-type':'application/json'},
    body:JSON.stringify({sender:{name:'MODOX · Arbor Labs',email:'contato@arborlabs.com.br'},replyTo:{name:'Arbor Labs',email:'contato@arborlabs.com.br'},to:[{email}],subject:'RECUPERAÇÃO DE SENHA - MODOX',htmlContent:html,tags:['modox','recuperacao']}),
  });
  if(!envio.ok){
    if(tentativa?.id)await admin.from('recuperacoes_senha').update({status:'falha_provedor'}).eq('id',tentativa.id);
    console.error('Falha no envio de recuperação MODOX',{status:envio.status,detalhe:(await envio.text()).slice(0,300)});
    return json(resposta);
  }
  const comprovante=await envio.json().catch(()=>({}));
  if(tentativa?.id)await admin.from('recuperacoes_senha').update({status:'aceita_provedor',provedor_id:comprovante?.messageId||null}).eq('id',tentativa.id);
  console.log('Recuperação MODOX aceita pelo provedor',{email_hash:(await sha(email)).slice(0,12),message_id:comprovante?.messageId||null});
  return json(resposta);
});
