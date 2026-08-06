create table if not exists public.push_inscricoes (
  id uuid primary key default gen_random_uuid(),
  pessoa_id uuid not null references public.pessoas(id) on delete cascade,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  agente text,
  atualizada_em timestamptz not null default now()
);

create index if not exists push_inscricoes_pessoa_idx on public.push_inscricoes(pessoa_id);
alter table public.push_inscricoes enable row level security;
revoke all on public.push_inscricoes from public,anon,authenticated;
grant all on public.push_inscricoes to service_role;

create or replace function public.registrar_push(
  p_endpoint text,p_p256dh text,p_auth text,p_agente text default null
) returns void language plpgsql security definer set search_path=public as $$
declare pid uuid:=public.pessoa_atual(); begin
  if pid is null then raise exception 'Faça login para ativar as notificações.'; end if;
  if length(coalesce(p_endpoint,''))<20 or length(coalesce(p_p256dh,''))<20 or length(coalesce(p_auth,''))<8 then
    raise exception 'Inscrição de notificação inválida.';
  end if;
  insert into public.push_inscricoes(pessoa_id,endpoint,p256dh,auth,agente)
  values(pid,p_endpoint,p_p256dh,p_auth,left(p_agente,500))
  on conflict(endpoint) do update set pessoa_id=excluded.pessoa_id,p256dh=excluded.p256dh,
    auth=excluded.auth,agente=excluded.agente,atualizada_em=now();
end $$;

revoke all on function public.registrar_push(text,text,text,text) from public,anon;
grant execute on function public.registrar_push(text,text,text,text) to authenticated;
