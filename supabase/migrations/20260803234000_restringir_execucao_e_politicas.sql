-- Reduz a superfície pública sem alterar as permissões efetivas de quem está
-- autenticado. O snapshot temporário precisa ocorrer antes do REVOKE porque
-- muitas funções herdavam EXECUTE do pseudo-papel PUBLIC.

create temporary table _modox_auth_exec (assinatura text primary key) on commit drop;

insert into _modox_auth_exec (assinatura)
select p.oid::regprocedure::text
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and has_function_privilege('authenticated', p.oid, 'EXECUTE');

revoke execute on all functions in schema public from public, anon, authenticated;

do $block$
declare item record;
begin
  for item in select assinatura from _modox_auth_exec loop
    execute format('grant execute on function %s to authenticated', item.assinatura);
  end loop;
end
$block$;

-- Funções de backend continuam disponíveis ao service_role, que é usado
-- somente em funções protegidas do servidor e nunca no navegador.
grant execute on all functions in schema public to service_role;

-- Únicas operações que fazem parte de jornadas realmente públicas.
grant execute on function public.checkin_info(text) to anon, authenticated;
grant execute on function public.confirmar_presenca_qr(text, text) to anon, authenticated;
grant execute on function public.inscrever_publico(text, text, text, text, text, jsonb, text) to anon, authenticated;
grant execute on function public.inscricao_info(text) to anon, authenticated;
grant execute on function public.pagina_publica(text) to anon, authenticated;
grant execute on function public.pagina_vista(text) to anon, authenticated;
grant execute on function public.status_inscricao(uuid) to anon, authenticated;
grant execute on function public.validar_certificado(text) to anon, authenticated;

-- As páginas públicas usam RPCs SECURITY DEFINER. Portanto nenhuma política
-- de tabela do esquema public precisa aceitar o papel anônimo diretamente.
do $block$
declare item record;
begin
  for item in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public' and 'public' = any(roles)
  loop
    execute format(
      'alter policy %I on %I.%I to authenticated',
      item.policyname, item.schemaname, item.tablename
    );
  end loop;
end
$block$;

-- Novas funções não devem voltar a receber EXECUTE público por padrão.
alter default privileges for role postgres in schema public
  revoke execute on functions from public;
