-- Uma turma pode ter mais de um professor responsável. Todos recebem o mesmo
-- acesso pedagógico à turma, sem limitar cada professor a uma única turma.
create or replace function public.definir_professores_turma(
  p_turma uuid,
  p_professores uuid[] default '{}'::uuid[]
)
returns void
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_escola uuid;
  v_professores uuid[] := coalesce(p_professores, '{}'::uuid[]);
begin
  select c.escola_id into v_escola
    from public.turmas t
    join public.cursos c on c.id = t.curso_id
   where t.id = p_turma;

  if v_escola is null then
    raise exception 'Turma não encontrada.';
  end if;
  if not public.tem_papel(v_escola, array['gestor','admin']::public.papel[]) then
    raise exception 'Você não pode definir os professores desta turma.';
  end if;
  if cardinality(v_professores) > 10 then
    raise exception 'Uma turma pode ter no máximo 10 professores responsáveis.';
  end if;
  if exists (
    select 1
      from unnest(v_professores) professor_id
     where professor_id is null
        or not exists (
          select 1 from public.vinculos v
           where v.escola_id = v_escola
             and v.pessoa_id = professor_id
             and v.ativo
             and v.papel in ('professor','gestor','admin')
        )
  ) then
    raise exception 'Um dos professores não possui acesso ativo a esta escola.';
  end if;

  delete from public.turma_professores where turma_id = p_turma;
  insert into public.turma_professores(turma_id, pessoa_id)
  select p_turma, professor_id
    from (select distinct unnest(v_professores) professor_id) professores;
end
$function$;

revoke all on function public.definir_professores_turma(uuid,uuid[]) from public, anon;
grant execute on function public.definir_professores_turma(uuid,uuid[]) to authenticated, service_role;

