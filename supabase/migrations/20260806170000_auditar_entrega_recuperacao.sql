alter table public.recuperacoes_senha
  add column if not exists status text not null default 'recebida'
    check (status in ('recebida','sem_conta','falha_provedor','aceita_provedor')),
  add column if not exists provedor_id text;

comment on column public.recuperacoes_senha.provedor_id is
  'Comprovante técnico do provedor, sem URL ou conteúdo da recuperação.';
