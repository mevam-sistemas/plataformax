-- Evita colisão entre a coluna pessoas.email e o parâmetro de saída email.
create or replace function public.convidar_equipe(
  p_escola uuid, p_email text, p_nome text, p_papel papel
) returns table(pessoa_id uuid, ja_existia boolean, nome text, email text)
language plpgsql security definer set search_path = public
as $$
declare
  v_pid uuid;
  v_existia boolean := false;
  v_email text;
begin
  if not public.tem_papel(p_escola, array['gestor','admin']::papel[]) then
    raise exception 'sem permissão';
  end if;
  if p_papel not in ('professor'::papel, 'gestor'::papel, 'admin'::papel) then
    raise exception 'papel inválido';
  end if;
  v_email := lower(trim(p_email));
  if v_email = '' or position('@' in v_email) = 0 then
    raise exception 'e-mail inválido';
  end if;

  select pe.id into v_pid
    from public.pessoas pe
   where lower(pe.email) = v_email
   limit 1;

  if v_pid is null then
    insert into public.pessoas(nome, email)
      values (trim(p_nome), v_email)
      returning id into v_pid;
  else
    v_existia := true;
    update public.pessoas pe
       set nome = case when trim(coalesce(pe.nome,'')) = '' then trim(p_nome) else pe.nome end
     where pe.id = v_pid;
  end if;

  insert into public.vinculos(pessoa_id, escola_id, papel, ativo)
    values (v_pid, p_escola, p_papel, true)
  on conflict on constraint vinculos_pessoa_id_escola_id_papel_key
    do update set ativo = true;

  return query
    select pe.id, v_existia, pe.nome, pe.email
      from public.pessoas pe
     where pe.id = v_pid;
end;
$$;

revoke all on function public.convidar_equipe(uuid,text,text,papel) from public, anon;
grant execute on function public.convidar_equipe(uuid,text,text,papel) to authenticated, service_role;
