import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {'content-type':'application/json'};
const primeiroNome=(nome:string)=>(nome||'').trim().split(/\s+/)[0]||'Olá';
const escapar=(s:string)=>String(s||'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]!));

function mensagem(p:any){
  const nome=escapar(primeiroNome(p.nome)), inst=escapar(p.instituicao);
  const abertura=p.papel==='professor'
      ? `Feliz aniversário, professor(a) ${nome}! Sua presença, sua escuta e cada aula preparada ajudam outras pessoas a avançar.`
      : ['direcao','gestao'].includes(p.papel)
        ? `Feliz aniversário, ${nome}! Liderar também é servir, abrir caminhos e sustentar sonhos. Obrigado por construir essa história com ${inst}.`
        : `Feliz aniversário, ${nome}! Que alegria acompanhar seus passos, aprendizados e conquistas nesta caminhada.`;
  const fechamento='Obrigado pela caminhada com Jesus Cristo. Que este novo ciclo traga sabedoria, saúde, bons encontros e motivos sinceros para celebrar.';
  return `<div style="background:#faf9f7;padding:32px 16px;font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif"><div style="max-width:520px;margin:auto;background:#fff;border:1px solid #ececf2;border-radius:20px;padding:34px;color:#17171a"><div style="font-size:13px;font-weight:800;letter-spacing:.12em;color:#d85b12">MODOX</div><h1 style="font-size:27px;line-height:1.2;margin:18px 0 14px">Um dia especial para agradecer pela sua vida.</h1><p style="font-size:16px;line-height:1.7;color:#55545d">${abertura}</p><p style="font-size:16px;line-height:1.7;color:#55545d">${fechamento}</p><blockquote style="margin:24px 0;padding:18px 20px;border-left:4px solid #f26a1b;background:#fff7f0;color:#3e352f;font-size:16px;line-height:1.6">“O Senhor te abençoe e te guarde; o Senhor faça resplandecer o seu rosto sobre ti e tenha misericórdia de ti.”<br><b>Números 6:24–25</b></blockquote><p style="font-size:16px;line-height:1.7;color:#55545d">Desejamos que esta data seja cheia de afeto, presença e esperança. Feliz aniversário!</p><p style="margin-top:26px;font-size:13px;color:#8b8991">Com carinho, equipe MODOX.</p></div></div>`;
}

Deno.serve(async(req)=>{
  if(req.headers.get('x-cron-secret')!==Deno.env.get('BIRTHDAY_CRON_SECRET')) return new Response('não autorizado',{status:401});
  const sb=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const {data,error}=await sb.rpc('aniversariantes_pendentes');
  if(error)return new Response(JSON.stringify({error:error.message}),{status:500,headers:cors});
  let enviados=0,falhas=0;
  for(const p of data||[]){
    const assunto=`Feliz aniversário, ${primeiroNome(p.nome)}!`;
    const r=await fetch('https://api.brevo.com/v3/smtp/email',{method:'POST',headers:{'api-key':Deno.env.get('BREVO_API_KEY')!,'content-type':'application/json'},body:JSON.stringify({sender:{name:'MODOX',email:'contato@arborlabs.com.br'},to:[{email:p.email,name:p.nome}],subject:assunto,htmlContent:mensagem(p)})});
    if(!r.ok){falhas++;console.error('aniversário',p.produto,p.pessoa_id,r.status,await r.text());continue;}
    const ano=Number(new Intl.DateTimeFormat('en',{year:'numeric',timeZone:'America/Sao_Paulo'}).format(new Date()));
    const {error:eLog}=await sb.from('aniversarios_enviados').insert({produto:p.produto,pessoa_id:p.pessoa_id,ano,destinatario:p.email});
    if(eLog){falhas++;console.error('log aniversário',p.produto,p.pessoa_id,eLog.message);}else enviados++;
  }
  return new Response(JSON.stringify({ok:true,encontrados:(data||[]).length,enviados,falhas}),{headers:cors});
});
