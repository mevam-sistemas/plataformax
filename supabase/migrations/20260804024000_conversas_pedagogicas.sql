-- Conversas pedagógicas do MODOX.
-- Não existem mensagens diretas entre alunos: eles conversam apenas no mural
-- público da própria turma, depois que um professor/gestor participa.

create table if not exists public.conversas (
  id uuid primary key default gen_random_uuid(),
  turma_id uuid not null references public.turmas(id) on delete cascade,
  aula_id uuid references public.aulas(id) on delete set null,
  criada_por uuid not null references public.pessoas(id),
  destino text not null check (destino in ('professor','gestao','turma')),
  publica boolean not null default false,
  encerrada_em timestamptz,
  criado_em timestamptz not null default now()
);

create table if not exists public.conversa_mensagens (
  id uuid primary key default gen_random_uuid(),
  conversa_id uuid not null references public.conversas(id) on delete cascade,
  autor_id uuid not null references public.pessoas(id),
  texto text,
  audio_url text,
  anexo_url text,
  criado_em timestamptz not null default now(),
  check (nullif(trim(coalesce(texto,'')),'') is not null or audio_url is not null or anexo_url is not null)
);
alter table public.conversa_mensagens add column if not exists anexo_url text;
alter table public.conversas drop constraint if exists conversas_destino_check;
alter table public.conversas add constraint conversas_destino_check check(destino in ('professor','gestao','turma'));
alter table public.conversa_mensagens drop constraint if exists conversa_mensagens_check;
alter table public.conversa_mensagens add constraint conversa_mensagens_check check(nullif(trim(coalesce(texto,'')),'') is not null or audio_url is not null or anexo_url is not null);

create table if not exists public.conversa_leituras (
  conversa_id uuid not null references public.conversas(id) on delete cascade,
  pessoa_id uuid not null references public.pessoas(id) on delete cascade,
  lida_em timestamptz not null default now(),
  primary key (conversa_id,pessoa_id)
);

create index if not exists conversas_turma_idx on public.conversas(turma_id,criado_em desc);
create index if not exists conversa_mensagens_conversa_idx on public.conversa_mensagens(conversa_id,criado_em);
create index if not exists conversa_leituras_pessoa_idx on public.conversa_leituras(pessoa_id,lida_em);

-- As perguntas que já existiam continuam disponíveis como conversas.
insert into public.conversas(id,turma_id,aula_id,criada_por,destino,publica,criado_em)
select p.id,p.turma_id,p.aula_id,p.pessoa_id,'professor',p.publica,p.criado_em from public.perguntas p
on conflict(id) do nothing;
insert into public.conversa_mensagens(conversa_id,autor_id,texto,criado_em)
select p.id,p.pessoa_id,p.texto,p.criado_em from public.perguntas p
where not exists(select 1 from public.conversa_mensagens cm where cm.conversa_id=p.id and cm.autor_id=p.pessoa_id and cm.criado_em=p.criado_em);
insert into public.conversa_mensagens(conversa_id,autor_id,texto,criado_em)
select p.id,p.respondida_por,p.resposta,coalesce(p.respondida_em,p.criado_em) from public.perguntas p
where p.resposta is not null and p.respondida_por is not null
  and not exists(select 1 from public.conversa_mensagens cm where cm.conversa_id=p.id and cm.autor_id=p.respondida_por and cm.criado_em=coalesce(p.respondida_em,p.criado_em));

alter table public.conversas enable row level security;
alter table public.conversa_mensagens enable row level security;
alter table public.conversa_leituras enable row level security;
revoke all on public.conversas, public.conversa_mensagens, public.conversa_leituras from anon, authenticated;

create or replace function public.nome_colega(p_nome text)
returns text language sql immutable set search_path=public as $function$
  select case
    when cardinality(regexp_split_to_array(trim(coalesce(p_nome,'Aluno')), '\s+')) > 1
      then split_part(trim(p_nome),' ',1) || ' ' || left((regexp_split_to_array(trim(p_nome),'\s+'))[2],1) || '.'
    else split_part(trim(coalesce(p_nome,'Aluno')),' ',1)
  end
$function$;

create or replace function public.texto_tem_contato(p_texto text)
returns boolean language sql immutable set search_path=public as $function$
  select coalesce(p_texto,'') ~* '([[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}|https?://|www\.|wa\.me|whats(app)?|telegram|instagram|(^|[^0-9])([0-9][ ()+.-]*){8,}([^0-9]|$))'
$function$;

create or replace function public.ranking_turma(p_turma uuid)
returns table(nome text,foto_url text,pontos integer,aulas integer,eu boolean)
language sql stable security definer set search_path=public as $function$
  select case when p.id=pessoa_atual() then p.nome else nome_colega(p.nome) end,
    case when na_turma(p_turma) and p.id<>pessoa_atual() then null else p.foto_url end,
    coalesce(g.pontos,0),
    (select count(*)::int from progresso pr join aulas a on a.id=pr.aula_id join modulos mo on mo.id=a.modulo_id join turmas t2 on t2.curso_id=mo.curso_id
      where pr.pessoa_id=p.id and pr.concluida_em is not null and t2.id=p_turma),p.id=pessoa_atual()
  from matriculas m join pessoas p on p.id=m.pessoa_id join turmas t on t.id=m.turma_id join cursos c on c.id=t.curso_id
  left join gamificacao g on g.pessoa_id=p.id and g.escola_id=c.escola_id
  where m.turma_id=p_turma and m.status in('ativa','concluida') and(na_turma(p_turma) or tem_papel(c.escola_id,array['professor','gestor','admin']::papel[]))
  order by coalesce(g.pontos,0) desc,p.nome limit 50
$function$;

create or replace function public.conversa_pode_ver(p_conversa uuid, p_pessoa uuid default public.pessoa_atual())
returns boolean language sql stable security definer set search_path=public as $function$
  select exists (
    select 1 from conversas cv
    join turmas t on t.id=cv.turma_id
    join cursos c on c.id=t.curso_id
    where cv.id=p_conversa and (
      cv.criada_por=p_pessoa
      or (cv.publica and exists(select 1 from matriculas m where m.turma_id=cv.turma_id and m.pessoa_id=p_pessoa and m.status in ('ativa','concluida')))
      or (cv.destino='professor' and exists(select 1 from turma_professores tp where tp.turma_id=cv.turma_id and tp.pessoa_id=p_pessoa))
      or (cv.destino='gestao' and exists(select 1 from vinculos v where v.escola_id=c.escola_id and v.pessoa_id=p_pessoa and v.ativo and v.papel in ('gestor','admin')))
      or exists(select 1 from vinculos v where v.escola_id=c.escola_id and v.pessoa_id=p_pessoa and v.ativo and v.papel='admin')
    )
  )
$function$;

create or replace function public.criar_conversa(
  p_turma uuid, p_aula uuid, p_destino text, p_publica boolean, p_texto text
) returns jsonb language plpgsql security definer set search_path=public as $function$
declare pid uuid; cid uuid; mid uuid; v_publica boolean; begin
  pid:=pessoa_atual();
  if pid is null then raise exception 'Faça login para enviar sua pergunta.'; end if;
  if p_destino not in ('professor','gestao') then raise exception 'Destinatário inválido.'; end if;
  if not exists(select 1 from matriculas where turma_id=p_turma and pessoa_id=pid and status in ('ativa','concluida')) then
    raise exception 'Você não está matriculado nesta turma.';
  end if;
  if p_aula is not null and not exists(select 1 from aulas a join modulos mo on mo.id=a.modulo_id join turmas t on t.curso_id=mo.curso_id where a.id=p_aula and t.id=p_turma) then
    raise exception 'A aula não pertence à sua turma.';
  end if;
  if coalesce(length(trim(p_texto)),0)<2 then raise exception 'Escreva sua pergunta.'; end if;
  if texto_tem_contato(p_texto) then raise exception 'Por segurança, não envie telefone, e-mail, rede social ou link de contato.'; end if;
  v_publica:=coalesce(p_publica,false) and p_destino='professor';
  insert into conversas(turma_id,aula_id,criada_por,destino,publica) values(p_turma,p_aula,pid,p_destino,v_publica) returning id into cid;
  insert into conversa_mensagens(conversa_id,autor_id,texto) values(cid,pid,trim(p_texto)) returning id into mid;
  insert into conversa_leituras(conversa_id,pessoa_id) values(cid,pid) on conflict do nothing;
  return jsonb_build_object('conversa_id',cid,'mensagem_id',mid);
end $function$;

drop function if exists public.adicionar_mensagem_conversa(uuid,text,boolean);
create or replace function public.adicionar_mensagem_conversa(p_conversa uuid, p_texto text default null, p_tem_audio boolean default false, p_tem_anexo boolean default false)
returns jsonb language plpgsql security definer set search_path=public as $function$
declare pid uuid; cv conversas%rowtype; mid uuid; estudante boolean; houve_staff boolean; begin
  pid:=pessoa_atual(); select * into cv from conversas where id=p_conversa;
  if cv.id is null or not conversa_pode_ver(p_conversa,pid) then raise exception 'Conversa indisponível.'; end if;
  if cv.encerrada_em is not null then raise exception 'Esta conversa foi encerrada.'; end if;
  estudante:=exists(select 1 from matriculas where turma_id=cv.turma_id and pessoa_id=pid and status in ('ativa','concluida'));
  if estudante and not cv.publica and cv.criada_por<>pid then raise exception 'Perguntas privadas pertencem somente ao autor.'; end if;
  if estudante and cv.publica then
    select exists(select 1 from conversa_mensagens cm where cm.conversa_id=cv.id and cm.autor_id<>cv.criada_por and (
      exists(select 1 from turma_professores tp where tp.turma_id=cv.turma_id and tp.pessoa_id=cm.autor_id)
      or exists(select 1 from turmas t join cursos c on c.id=t.curso_id join vinculos v on v.escola_id=c.escola_id and v.pessoa_id=cm.autor_id and v.ativo and v.papel in ('gestor','admin') where t.id=cv.turma_id)
    )) into houve_staff;
    if not houve_staff then raise exception 'A conversa da turma abre depois da primeira resposta do professor.'; end if;
  end if;
  if coalesce(length(trim(p_texto)),0)<1 and not coalesce(p_tem_audio,false) and not coalesce(p_tem_anexo,false) then raise exception 'Escreva uma mensagem, grave um áudio ou envie um anexo.'; end if;
  if estudante and texto_tem_contato(p_texto) then raise exception 'Por segurança, não envie telefone, e-mail, rede social ou link de contato.'; end if;
  insert into conversa_mensagens(conversa_id,autor_id,texto,audio_url,anexo_url)
  values(cv.id,pid,nullif(trim(coalesce(p_texto,'')),''),case when p_tem_audio then 'enviando' else null end,case when p_tem_anexo then 'enviando' else null end) returning id into mid;
  insert into conversa_leituras(conversa_id,pessoa_id,lida_em) values(cv.id,pid,now()) on conflict(conversa_id,pessoa_id) do update set lida_em=excluded.lida_em;
  return jsonb_build_object('conversa_id',cv.id,'mensagem_id',mid);
end $function$;

create or replace function public.publicar_orientacao(p_turma uuid,p_texto text)
returns jsonb language plpgsql security definer set search_path=public as $function$
declare pid uuid; cid uuid; curso uuid; mid uuid; begin
  pid:=pessoa_atual();select t.curso_id into curso from turmas t where t.id=p_turma;
  if not(prof_da_turma(p_turma) or staff_do_curso(curso)) then raise exception 'Você não conduz esta turma.'; end if;
  if coalesce(length(trim(p_texto)),0)<2 then raise exception 'Escreva a orientação.'; end if;
  insert into conversas(turma_id,criada_por,destino,publica) values(p_turma,pid,'turma',true) returning id into cid;
  insert into conversa_mensagens(conversa_id,autor_id,texto) values(cid,pid,trim(p_texto)) returning id into mid;
  insert into conversa_leituras(conversa_id,pessoa_id) values(cid,pid) on conflict do nothing;
  return jsonb_build_object('conversa_id',cid,'mensagem_id',mid);
end $function$;

create or replace function public.anexar_audio_conversa(p_mensagem uuid, p_caminho text)
returns void language plpgsql security definer set search_path=public as $function$
begin
  if not exists(select 1 from conversa_mensagens where id=p_mensagem and autor_id=pessoa_atual()) then raise exception 'Mensagem indisponível.'; end if;
  if p_caminho not like 'conversas/'||(select conversa_id from conversa_mensagens where id=p_mensagem)::text||'/'||p_mensagem::text||'.%' then raise exception 'Caminho de áudio inválido.'; end if;
  update conversa_mensagens set audio_url=p_caminho where id=p_mensagem;
end $function$;

create or replace function public.anexar_imagem_conversa(p_mensagem uuid, p_caminho text)
returns void language plpgsql security definer set search_path=public as $function$
begin
  if not exists(select 1 from conversa_mensagens where id=p_mensagem and autor_id=pessoa_atual()) then raise exception 'Mensagem indisponível.'; end if;
  if p_caminho not like 'conversas/'||(select conversa_id from conversa_mensagens where id=p_mensagem)::text||'/'||p_mensagem::text||'.%' then raise exception 'Caminho de anexo inválido.'; end if;
  update conversa_mensagens set anexo_url=p_caminho where id=p_mensagem;
end $function$;

create or replace function public.marcar_conversa_lida(p_conversa uuid)
returns void language plpgsql security definer set search_path=public as $function$
begin
  if not conversa_pode_ver(p_conversa) then raise exception 'Conversa indisponível.'; end if;
  insert into conversa_leituras(conversa_id,pessoa_id,lida_em) values(p_conversa,pessoa_atual(),now())
  on conflict(conversa_id,pessoa_id) do update set lida_em=excluded.lida_em;
end $function$;

create or replace function public.conversas_turma(p_turma uuid default null, p_aula uuid default null)
returns jsonb language sql stable security definer set search_path=public as $function$
with eu as (select pessoa_atual() pid), acessiveis as (
  select cv.*, t.nome turma, c.titulo curso,
    exists(select 1 from matriculas m,eu where m.turma_id=cv.turma_id and m.pessoa_id=eu.pid and m.status in ('ativa','concluida')) sou_aluno,
    coalesce((select lida_em from conversa_leituras cl,eu where cl.conversa_id=cv.id and cl.pessoa_id=eu.pid),'epoch'::timestamptz) lida_em
  from conversas cv join turmas t on t.id=cv.turma_id join cursos c on c.id=t.curso_id
  where (p_turma is null or cv.turma_id=p_turma) and (p_aula is null or cv.aula_id=p_aula) and conversa_pode_ver(cv.id)
), dados as (
  select a.*, pe.nome autor_nome,
    (select max(cm.criado_em) from conversa_mensagens cm where cm.conversa_id=a.id) ultima_em,
    exists(select 1 from conversa_mensagens cm where cm.conversa_id=a.id and cm.criado_em>a.lida_em and cm.autor_id<>(select pid from eu)) nao_lida,
    (select jsonb_agg(jsonb_build_object('id',cm.id,'texto',cm.texto,'audio_url',cm.audio_url,'criado_em',cm.criado_em,
      'anexo_url',cm.anexo_url,'minha',cm.autor_id=(select pid from eu),'autor',case when a.sou_aluno and cm.autor_id<>(select pid from eu)
        and exists(select 1 from matriculas mx where mx.turma_id=a.turma_id and mx.pessoa_id=cm.autor_id) then nome_colega(pm.nome) else pm.nome end,
      'autor_tipo',case when exists(select 1 from matriculas mx where mx.turma_id=a.turma_id and mx.pessoa_id=cm.autor_id) then 'aluno' else 'equipe' end)
      order by cm.criado_em) from conversa_mensagens cm join pessoas pm on pm.id=cm.autor_id where cm.conversa_id=a.id) mensagens
  from acessiveis a join pessoas pe on pe.id=a.criada_por
)
select coalesce(jsonb_agg(jsonb_build_object('id',id,'turma_id',turma_id,'aula_id',aula_id,'turma',turma,'curso',curso,
  'destino',destino,'publica',publica,'autor',case when sou_aluno then nome_colega(autor_nome) else autor_nome end,
  'minha',criada_por=(select pid from eu),'nao_lida',nao_lida,'criado_em',criado_em,'ultima_em',ultima_em,'mensagens',coalesce(mensagens,'[]'::jsonb)) order by ultima_em desc),'[]'::jsonb) from dados
$function$;

create or replace function public.colegas_turma(p_turma uuid)
returns table(nome text) language sql stable security definer set search_path=public as $function$
  select nome_colega(p.nome) from matriculas m join pessoas p on p.id=m.pessoa_id
  where m.turma_id=p_turma and m.status in ('ativa','concluida')
    and exists(select 1 from matriculas eu where eu.turma_id=p_turma and eu.pessoa_id=pessoa_atual() and eu.status in ('ativa','concluida'))
  order by p.nome
$function$;

create or replace function public.pendencias_conversas(p_escola uuid)
returns jsonb language sql stable security definer set search_path=public as $function$
with cs as (
 select cv.id,cv.turma_id,cv.destino,cv.publica,cv.criado_em,t.nome turma,c.titulo curso,nome_colega(p.nome) autor,
   (select cm.texto from conversa_mensagens cm where cm.conversa_id=cv.id order by cm.criado_em limit 1) texto,
   coalesce((select cl.lida_em from conversa_leituras cl where cl.conversa_id=cv.id and cl.pessoa_id=pessoa_atual()),'epoch'::timestamptz) lida_em,
   (select max(cm.criado_em) from conversa_mensagens cm where cm.conversa_id=cv.id) ultima_em
 from conversas cv join turmas t on t.id=cv.turma_id join cursos c on c.id=t.curso_id join pessoas p on p.id=cv.criada_por
 where c.escola_id=p_escola and conversa_pode_ver(cv.id)
), pend as (select * from cs where ultima_em>lida_em)
select coalesce(jsonb_agg(jsonb_build_object('id',id,'turma_id',turma_id,'destino',destino,'publica',publica,'autor',autor,'turma',turma,'curso',curso,'texto',texto,'ultima_em',ultima_em) order by ultima_em),'[]'::jsonb) from pend
$function$;

create or replace function public.painel_engajamento_turma(p_turma uuid)
returns jsonb language plpgsql stable security definer set search_path=public as $function$
declare cid uuid; eid uuid; begin
  select t.curso_id,c.escola_id into cid,eid from turmas t join cursos c on c.id=t.curso_id where t.id=p_turma;
  if not (prof_da_turma(p_turma) or staff_do_curso(cid)) then raise exception 'Turma indisponível.'; end if;
  return coalesce((select jsonb_agg(jsonb_build_object('matricula_id',m.id,'pessoa_id',p.id,'nome',p.nome,'telefone',p.telefone,
      'foto_url',p.foto_url,'aulas_iniciadas',(select count(*) from progresso pr join aulas a on a.id=pr.aula_id join modulos mo on mo.id=a.modulo_id where pr.pessoa_id=p.id and mo.curso_id=cid),
      'aulas_concluidas',(select count(*) from progresso pr join aulas a on a.id=pr.aula_id join modulos mo on mo.id=a.modulo_id where pr.pessoa_id=p.id and mo.curso_id=cid and pr.concluida_em is not null),
      'ultima_interacao',greatest(
        coalesce((select max(pr.concluida_em) from progresso pr join aulas a on a.id=pr.aula_id join modulos mo on mo.id=a.modulo_id where pr.pessoa_id=p.id and mo.curso_id=cid),'epoch'::timestamptz),
        coalesce((select max(cm.criado_em) from conversa_mensagens cm join conversas cv on cv.id=cm.conversa_id where cm.autor_id=p.id and cv.turma_id=p_turma),'epoch'::timestamptz)
      )) order by p.nome)
    from matriculas m join pessoas p on p.id=m.pessoa_id where m.turma_id=p_turma and m.status='ativa'),'[]'::jsonb);
end $function$;

revoke all on function public.nome_colega(text), public.texto_tem_contato(text), public.conversa_pode_ver(uuid,uuid),
  public.criar_conversa(uuid,uuid,text,boolean,text), public.adicionar_mensagem_conversa(uuid,text,boolean,boolean), public.publicar_orientacao(uuid,text),
  public.anexar_audio_conversa(uuid,text), public.anexar_imagem_conversa(uuid,text), public.marcar_conversa_lida(uuid), public.conversas_turma(uuid,uuid),
  public.colegas_turma(uuid), public.pendencias_conversas(uuid), public.painel_engajamento_turma(uuid) from public,anon;
grant execute on function public.criar_conversa(uuid,uuid,text,boolean,text), public.adicionar_mensagem_conversa(uuid,text,boolean,boolean), public.publicar_orientacao(uuid,text),
  public.anexar_audio_conversa(uuid,text), public.anexar_imagem_conversa(uuid,text), public.marcar_conversa_lida(uuid), public.conversas_turma(uuid,uuid),
  public.colegas_turma(uuid), public.pendencias_conversas(uuid), public.painel_engajamento_turma(uuid) to authenticated,service_role;
grant execute on function public.conversa_pode_ver(uuid,uuid), public.nome_colega(text), public.texto_tem_contato(text) to authenticated,service_role;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('conversas','conversas',false,5242880,array['audio/webm','audio/mp4','audio/ogg','audio/mpeg','image/jpeg','image/webp','image/png'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists modox_conversa_audio_inserir on storage.objects;
create policy modox_conversa_audio_inserir on storage.objects for insert to authenticated with check(
 bucket_id='conversas' and (storage.foldername(name))[1]='conversas'
 and public.conversa_pode_ver(((storage.foldername(name))[2])::uuid)
);
drop policy if exists modox_conversa_audio_ler on storage.objects;
create policy modox_conversa_audio_ler on storage.objects for select to authenticated using(
 bucket_id='conversas' and public.conversa_pode_ver(((storage.foldername(name))[2])::uuid)
);
