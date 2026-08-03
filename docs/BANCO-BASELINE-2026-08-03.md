# Baseline do banco MODOX — 2026-08-03

Inventário obtido dos catálogos do PostgreSQL do projeto Supabase de produção,
sem consultar registros de usuários ou dados das escolas.

## Estado encontrado

- 33 tabelas no esquema `public`.
- RLS habilitado nas 33 tabelas.
- `codigos_2fa` e `escolas_pagamento` sem políticas: permanecem fechadas para
  acesso pelo navegador.
- Nenhuma tabela do esquema `public` concede privilégio direto ao papel `anon`.
- Funções `SECURITY DEFINER` possuem `search_path` fixado em `public` (uma delas
  também usa `extensions`).
- Muitas funções herdavam `EXECUTE` do pseudo-papel PostgreSQL `PUBLIC`, o que
  incluía `anon` mesmo quando a jornada não era pública.
- Políticas antigas usavam o papel `PUBLIC`; as expressões faziam verificação
  de identidade, mas deixavam uma superfície desnecessariamente ampla.

## Decisão de segurança

A migração `20260803234000_restringir_execucao_e_politicas.sql`:

1. preserva as funções que o papel `authenticated` já podia executar;
2. remove a concessão genérica de `PUBLIC` e `anon`;
3. libera ao anônimo somente check-in, inscrição, página pública, consulta do
   andamento da inscrição e validação de certificado;
4. restringe as políticas das tabelas do MODOX a `authenticated`;
5. impede que novas funções criadas por `postgres` voltem a nascer públicas.

Os acessos públicos continuam passando por funções com parâmetros controlados
e validações internas. O `service_role` permanece exclusivo do backend.

## Regra para próximas mudanças

- Toda alteração estrutural deve ser um arquivo novo em `supabase/migrations`.
- Nunca editar uma migração que já foi aplicada em produção.
- Função nova começa sem acesso público e recebe `GRANT EXECUTE` somente para o
  papel necessário.
- Tabela nova deve habilitar RLS antes de receber dados.
- Mudanças de permissão precisam de teste anônimo, autenticado e administrativo.
