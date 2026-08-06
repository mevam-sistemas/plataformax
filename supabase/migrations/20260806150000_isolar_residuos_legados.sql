-- O Modox não expõe nem executa objetos dos produtos que historicamente
-- compartilharam este projeto. Os dados permanecem no backup restaurável,
-- mas deixam de ser alcançáveis pelos papéis da aplicação e por URL pública.
do $$
declare fn record;
begin
  if exists (select 1 from pg_namespace where nspname = 'social') then
    revoke all on all tables in schema social from public, anon, authenticated;
    revoke all on all sequences in schema social from public, anon, authenticated;
    for fn in
      select p.oid::regprocedure as assinatura
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'social'
    loop
      execute format('revoke all on function %s from public, anon, authenticated', fn.assinatura);
    end loop;
    revoke usage on schema social from public, anon, authenticated;
  end if;
end $$;

update storage.buckets
set public = false
where id like 'ct360-%'
   or id = 'logos-instituicoes';
