create table if not exists public.recuperacoes_senha (
  id bigint generated always as identity primary key,
  chave text not null check (length(chave)=64),
  criado_em timestamptz not null default now()
);

alter table public.recuperacoes_senha enable row level security;
revoke all on public.recuperacoes_senha from anon, authenticated;
create index if not exists recuperacoes_senha_chave_criado_idx
  on public.recuperacoes_senha(chave, criado_em desc);

comment on table public.recuperacoes_senha is
  'Controle interno de frequência para recuperação de senha; não armazena o e-mail.';
