-- Depois da separação física dos produtos, o Modox consulta e registra apenas
-- aniversariantes do próprio banco. Nenhuma rotina daqui depende do 360social.
create or replace function public.aniversariantes_pendentes()
returns table(produto text, pessoa_id uuid, nome text, email text, papel text, instituicao text)
language sql security definer set search_path=public
as $$
  with papel_modox as (
    select p.id,
      case when bool_or(v.ativo and v.papel='admin') then 'direcao'
           when bool_or(v.ativo and v.papel='gestor') then 'gestao'
           when bool_or(v.ativo and v.papel='professor') then 'professor'
           else 'aluno' end papel,
      coalesce(max(e.nome) filter (where v.ativo),max(ec.nome),'sua instituição') instituicao
    from public.pessoas p
    left join public.vinculos v on v.pessoa_id=p.id
    left join public.escolas e on e.id=v.escola_id
    left join public.matriculas m on m.pessoa_id=p.id and m.status in ('ativa','concluida')
    left join public.turmas t on t.id=m.turma_id
    left join public.cursos c on c.id=t.curso_id
    left join public.escolas ec on ec.id=c.escola_id
    group by p.id
  )
  select 'modox',p.id,p.nome,p.email,pm.papel,pm.instituicao
    from public.pessoas p join papel_modox pm on pm.id=p.id
   where p.nascimento is not null and p.email is not null
     and extract(month from p.nascimento)=extract(month from timezone('America/Sao_Paulo',now()))
     and extract(day from p.nascimento)=extract(day from timezone('America/Sao_Paulo',now()))
     and not exists (
       select 1 from public.aniversarios_enviados a
        where a.produto='modox' and a.pessoa_id=p.id
          and a.ano=extract(year from timezone('America/Sao_Paulo',now()))::int
     );
$$;

revoke all on function public.aniversariantes_pendentes() from public,anon,authenticated;
grant execute on function public.aniversariantes_pendentes() to service_role;
