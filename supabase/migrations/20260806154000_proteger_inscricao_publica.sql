-- A inscrição pública pode criar uma pessoa, mas nunca alterar o cadastro de
-- alguém que já exista apenas porque o visitante conhece seu e-mail.
create or replace function public.inscrever_publico(
  p_slug text,
  p_nome text,
  p_email text,
  p_whatsapp text,
  p_sobre text,
  p_respostas jsonb default '{}'::jsonb,
  p_foto text default null::text
)
returns table(situacao public.status_matricula, matricula_id uuid)
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  f record;
  tid uuid;
  pid uuid;
  st public.status_matricula;
  preco int;
  vmax int;
  ocup int;
  mid uuid;
  ende jsonb;
  email_normalizado text := lower(trim(coalesce(p_email, '')));
  respostas_seguras jsonb := coalesce(p_respostas, '{}'::jsonb);
begin
  if p_slug is null or length(p_slug) not between 1 and 120 then
    raise exception 'formulário inválido';
  end if;
  if p_nome is null or length(trim(p_nome)) not between 3 and 160 then
    raise exception 'nome inválido';
  end if;
  if length(email_normalizado) > 254
     or email_normalizado !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' then
    raise exception 'e-mail inválido';
  end if;
  if length(coalesce(p_whatsapp, '')) > 30 then
    raise exception 'telefone inválido';
  end if;
  if length(coalesce(p_sobre, '')) > 5000 then
    raise exception 'texto muito longo';
  end if;
  if jsonb_typeof(respostas_seguras) <> 'object'
     or octet_length(respostas_seguras::text) > 20000 then
    raise exception 'respostas inválidas';
  end if;
  if p_foto is not null
     and p_foto !~ '^inscricoes/[0-9a-f-]{36}/foto-[A-Za-z0-9_-]+[.]jpg$' then
    raise exception 'foto inválida';
  end if;

  select * into f from public.formularios where formularios.slug = p_slug;
  if f.id is null then raise exception 'formulário não encontrado'; end if;

  if (f.destino->>'tipo') = 'turma' then
    tid := (f.destino->>'id')::uuid;
  elsif (f.destino->>'tipo') = 'curso' then
    select id into tid from public.turmas
      where curso_id = (f.destino->>'id')::uuid
      order by criado_em desc limit 1;
  end if;
  if tid is null then raise exception 'turma não encontrada'; end if;

  -- Serializa inscrições concorrentes da mesma turma antes de contar vagas.
  select t.max_inscricoes, coalesce(c.valor_cents, 0) into vmax, preco
    from public.turmas t
    join public.cursos c on c.id = t.curso_id
    where t.id = tid
    for update of t;

  ende := jsonb_strip_nulls(jsonb_build_object(
    'rua', respostas_seguras->>'Endereço',
    'cep', respostas_seguras->>'CEP',
    'cidade', respostas_seguras->>'Cidade'
  ));

  select id into pid from public.pessoas where email = email_normalizado;
  if pid is null then
    insert into public.pessoas (nome, email, telefone, foto_url, endereco)
    values (
      trim(p_nome),
      email_normalizado,
      nullif(trim(coalesce(p_whatsapp, '')), ''),
      p_foto,
      coalesce(ende, '{}'::jsonb)
    )
    returning id into pid;
  end if;

  select m.status, m.id into st, mid
    from public.matriculas m
    where m.pessoa_id = pid and m.turma_id = tid
    limit 1;
  if mid is not null then
    return query select st, mid;
    return;
  end if;

  if vmax is not null then
    select count(*)::int into ocup
      from public.matriculas m
      where m.turma_id = tid
        and (
          m.status in ('ativa', 'pendente', 'aprovada')
          or (m.status = 'aguardando_pagamento'
              and m.criado_em > now() - interval '30 minutes')
        );
    if ocup >= vmax then raise exception 'turma lotada'; end if;
  end if;

  st := case
    when preco > 0 then 'aguardando_pagamento'::public.status_matricula
    when f.tipo = 'gratuita' then 'ativa'::public.status_matricula
    else 'pendente'::public.status_matricula
  end;

  insert into public.matriculas (pessoa_id, turma_id, status, respostas)
  values (
    pid,
    tid,
    st,
    jsonb_build_object('sobre', coalesce(p_sobre, '')) || respostas_seguras
  )
  returning id into mid;

  return query select st, mid;
end
$function$;

revoke all on function public.inscrever_publico(text, text, text, text, text, jsonb, text) from public;
grant execute on function public.inscrever_publico(text, text, text, text, text, jsonb, text) to anon, authenticated;
