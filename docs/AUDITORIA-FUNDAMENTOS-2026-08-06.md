# Auditoria dos fundamentos — 6 de agosto de 2026

Escopo: segurança, isolamento, experiência responsiva, acessibilidade, PWA,
notificações, e-mails, versionamento, desempenho e continuidade operacional.

## Evidências verificadas

- O Modox usa o projeto Supabase exclusivo `lshjtlzlywipxtfwbxxe`.
- As 38 tabelas públicas possuem RLS ativo. Tabelas internas sem política pública
  permanecem acessíveis apenas ao servidor.
- O schema legado `social` teve uso e execução revogados para `anon` e
  `authenticated`; buckets legados foram tornados privados.
- Funções públicas mantidas para inscrição, presença, certificado e páginas
  públicas têm `search_path` explícito. A inscrição pública não altera PII de
  pessoa preexistente e serializa a contagem de vagas.
- Senhas exigem no mínimo 10 caracteres no cliente e no servidor, com proteção
  contra senhas comprometidas habilitada.
- Dependências JavaScript críticas são locais; CSP, HSTS, bloqueio de iframe,
  `nosniff` e política de permissões são enviados em produção.
- O PWA oferece atualização controlada, push autenticado e uma tela dedicada de
  recuperação de senha. E-mails são próprios do produto.
- O release impõe orçamento aos arquivos críticos e não executa scripts remotos.
- Backup diário cifrado e teste periódico de restauração são executados pelo
  GitHub Actions, sem tornar dados pessoais públicos.

## Regra de manutenção

Toda mudança de banco deve chegar por migration versionada, manter o isolamento
por escola e incluir teste de regressão quando alterar autenticação, cadastro
público, cobrança, arquivos ou permissões.
