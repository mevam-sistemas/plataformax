# Histórico de versões do MODOX

Este arquivo registra mudanças publicadas no produto. A versão segue o formato
`MAIOR.MENOR.CORREÇÃO`: incompatibilidade, funcionalidade e correção,
respectivamente.

## 1.4.4 — 2026-08-04

- A governança do banco compartilhado passa a apontar o CT360 como fonte canônica das 44 migrações alinhadas.
- Este repositório deixa de ser origem autorizada para `supabase db push`, reduzindo o risco de históricos divergentes.
- A documentação de restauração registra a cobertura comprovada dos schemas `public` e `social`.

## 1.4.3 — 2026-08-04

- O arquivo canônico de versão deixa de permanecer no cache da CDN, permitindo que o PWA reconheça a publicação nova imediatamente.
- A validação do release passa a exigir cache desativado tanto no service worker quanto na fonte de versão.

## 1.4.2 — 2026-08-04

- Política de Segurança de Conteúdo passa a limitar scripts, conexões, imagens, mídias, quadros e formulários aos serviços usados pelo MODOX.
- Incorporação por outros sites, plugins legados e conteúdo misto passam a ser bloqueados também pelo navegador.
- Validação do release passa a impedir a publicação sem CSP, HSTS e proteção contra iframe.

## 1.4.1 — 2026-08-04

- Convite de professor, gestor ou administrador passa a vincular o UID criado no Supabase ao cadastro da pessoa antes do primeiro acesso.
- Contas de autenticação já existentes são localizadas pelo e-mail e ligadas ao cadastro correto.
- Em caso de falha no vínculo de um convite novo, o usuário órfão é removido e nenhum e-mail quebrado é enviado.
- Textos da equipe passam a descrever corretamente o acesso por e-mail e senha.

## 1.4.0 — 2026-08-04

- Instituição e módulos podem ser renomeados; cursos, aulas e turmas mantêm seus editores.
- Listas numeradas preservam 1, 2, 3 mesmo com linhas em branco entre os itens.
- Cadastro de professor, gestor ou administrador deixa de falhar por ambiguidade da coluna de e-mail.
- Aluno sem foto recebe uma pendência com atalho para completar o perfil.
- E-mail de confirmação passa a servir corretamente a contratantes, equipe e alunos, sem tratar todos como estudantes.
- Felicitação cristã de aniversário por e-mail, com linguagem própria para direção, professor e aluno, controle anual contra duplicidade e sem envio quando a data não foi informada.

## 1.3.1 — 2026-08-04

- Alunos da mesma turma podem ver as fotos de perfil uns dos outros.
- Nomes continuam abreviados e nenhum dado de contato é compartilhado entre alunos.
- Política do Storage autoriza a foto somente para colegas com matrícula ativa na mesma turma.

## 1.3.0 — 2026-08-04

- Painéis de turma com alunos interagindo, sem interação, progresso e último contato.
- Perguntas públicas da turma e perguntas privadas para professor ou gestão.
- Conversas contínuas depois da primeira resposta da equipe, com texto, áudio,
  imagem, autor, data, hora e controle de leitura.
- Orientações do professor, gestão ou direção para a turma.
- Bloqueio no servidor para telefone, e-mail, rede social e links enviados por alunos.
- Alunos veem colegas apenas pelo primeiro nome e inicial seguinte; WhatsApp continua
  restrito a professor, gestão e direção.
- Cabeçalho de aluno e professor usa a logo da instituição, com MODOX como substituta.
- Versão única compartilhada pelo rodapé e pelo cache do PWA.

## 1.2.0 — 2026-08-04

- Entrada direta no painel para contratos com uma instituição.
- Resumo operacional e pendências reais de logo, professor e matrículas.
- Melhorias gerais de responsividade, espaçamento e hierarquia visual.

## 1.1.0 — 2026-08-04

- Primeiro acesso direcionado a diretores e responsáveis pela contratação.
- Alunos passam a entrar exclusivamente por convite ou link de inscrição.
- Cadastro da escola com escolha PF/PJ, validação de CPF/CNPJ e logo obrigatória.
- Foto privada de perfil para direção, professores, secretaria e alunos, com
  captura pelo celular, limite de 12 MB e compressão para aproximadamente 320 KB.
- Permissões do Storage corrigidas para o dono e a equipe autorizada da escola.
- Interface de gestão atualizada para uma identidade mais sóbria, quente e
  alinhada ao laranja da marca, reduzindo o azul e refinando botões e destaques.

## 1.0.0 — 2026-08-03

- Aplicativo instalável como PWA em celular, tablet e computador.
- Atualização automática do aplicativo instalado quando uma nova versão assume
  o controle.
- Funcionamento de contingência para abrir a estrutura básica do aplicativo
  quando a conexão cair.
- Início do versionamento formal do MODOX.
- Validação automática de pull requests e publicações em `main`.
- Cabeçalhos de segurança e política explícita para câmera e microfone.
- Procedimento operacional e relação do backup compartilhado documentados.
- Baseline do banco registrado e migrações Supabase iniciadas.
- Execução anônima reduzida às oito jornadas públicas necessárias.
- Políticas das tabelas do MODOX restritas a usuários autenticados.
