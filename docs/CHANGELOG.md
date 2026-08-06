# Histórico de versões do MODOX

Este arquivo registra mudanças publicadas no produto. A versão segue o formato
`MAIOR.MENOR.CORREÇÃO`: incompatibilidade, funcionalidade e correção,
respectivamente.

## 1.6.0 — 2026-08-06

- Cada turma passa a aceitar vários professores responsáveis, todos com acesso
  pedagógico integral aos alunos, presença, perguntas e interações da turma.
- Um professor pode conduzir várias turmas sem ser removido automaticamente da
  anterior, e gestores selecionam os responsáveis por caixas de seleção.
- Listagens, cartões e impressão do QR passam a exibir conjuntamente os nomes de
  todos os professores vinculados.

## 1.5.9 — 2026-08-06

- A tela de turmas elimina a mistura decorativa de verde, terracota e laranja:
  metadados de alunos e professor passam a usar a identidade MODOX.
- Botões secundários passam a ter texto neutro e os botões laranja recebem texto
  branco, mantendo uma hierarquia visual simples entre ação principal e apoio.
- Recuperação de senha passa pelo remetente transacional da Arbor Labs, com
  identidade MODOX, resposta neutra e limitação contra abuso.

## 1.5.8 — 2026-08-06

- Ações principais passam a usar o laranja oficial da marca MODOX em todas as
  visões, eliminando o antigo tom terroso da gestão.
- Botões, cartões, abas, bordas e sombras recebem acabamento visual unificado,
  mais leve e responsivo, com estados claros de foco, toque e indisponibilidade.
- Verde, amarelo e vermelho ficam reservados a mensagens de sucesso, atenção e
  erro, tornando a leitura da interface mais previsível.

## 1.5.7 — 2026-08-06

- O Painel Arbor Labs recebe recuperação com identidade própria mesmo usando a
  infraestrutura de autenticação compartilhada com o MODOX.
- Endereços de retorno do painel passam a integrar a lista segura do provedor.

## 1.5.6 — 2026-08-06

- Cadastro, convite, recuperação de senha e aniversário passam a usar remetente,
  linguagem, acabamento visual e rodapé únicos do MODOX e da Arbor Labs.
- Remetente SMTP deixa de usar endereço pessoal e passa a responder oficialmente
  por `contato@arborlabs.com.br`, melhorando consistência e entregabilidade.
- Falhas e confirmações do provedor de convite passam a registrar diagnóstico e
  identificador da mensagem para suporte.

## 1.5.5 — 2026-08-06

- Download do QR de presença passa a usar a biblioteca local correta, sem depender
  de serviço externo e sem falhar ao preparar a folha A4.
- QR, instruções e botão de download recebem alinhamento central, proporções
  consistentes e adaptação para celular.

## 1.5.4 — 2026-08-06

- A inscrição pública deixa de alterar nome, telefone, endereço ou foto de um cadastro existente apenas pela coincidência de e-mail.
- Entradas públicas passam a validar limites de texto, respostas e caminho da foto no servidor.
- A reserva de vagas é serializada para impedir exceder a capacidade da turma em inscrições simultâneas.

## 1.5.3 — 2026-08-06

- “Esqueci minha senha” passa a abrir uma tela própria, com e-mail, instruções e retorno acessível.
- A resposta não revela se determinado endereço possui ou não uma conta cadastrada.

## 1.5.2 — 2026-08-06

- Resíduos arquivados de produtos que já compartilharam o projeto deixam de ser acessíveis aos papéis do Modox.
- Buckets legados do CT360 e do 360social deixam de servir arquivos por URL pública.
- Os dados históricos continuam preservados apenas no backup restaurável, sem participação na aplicação atual.
- Bibliotecas do Supabase e QR Code passam a ser servidas pelo próprio Modox, retirando dependências executáveis de CDN.

## 1.5.1 — 2026-08-06

- A ação de notificações recebe um rótulo compacto no cabeçalho para não comprimir a navegação em celulares.

## 1.5.0 — 2026-08-06

- Professores, gestão e alunos podem ativar notificações push no PWA pelo próprio cabeçalho.
- Novas perguntas, respostas e orientações notificam apenas os participantes adequados à turma e ao tipo de conversa.
- O servidor confere autoria e vínculo antes de enviar, e remove automaticamente inscrições expiradas.

## 1.4.9 — 2026-08-06

- Criação de conta, matrícula e redefinição passam a validar os mesmos 10 caracteres exigidos pelo servidor.
- A interface deixa de aceitar uma senha que o banco recusaria em seguida.

## 1.4.8 — 2026-08-06

- O PWA deixa de recarregar sozinho no meio de um formulário ou atividade.
- Novas versões exibem um aviso acessível e só assumem o controle quando a pessoa toca em “Atualizar agora”.

## 1.4.7 — 2026-08-06

- Autenticação fica limitada ao domínio oficial do MODOX, exige senha de 10 caracteres e verifica credenciais conhecidas em vazamentos.
- O banco deixa de expor o schema histórico do 360social e passa a operar exclusivamente o domínio educacional.
- Aniversários consultam e enviam somente pessoas do MODOX, eliminando dependências entre produtos.
- Backup diário cifrado passa a preservar banco, autenticação e arquivos em retenção independente.

## 1.4.6 — 2026-08-06

- Login e recuperação recebem associação semântica entre rótulos e campos.
- Botões compactos, navegação e marca interativa passam a respeitar alvos de toque de 44 px.
- Auditoria de segurança inicia a separação definitiva do banco usado pelo 360social.

## 1.4.5 — 2026-08-04

- Recuperação de senha passa a retornar sempre ao domínio canônico do MODOX.
- Assuntos e mensagens de autenticação ganham identidade própria e linguagem adequada a gestor, professor e aluno.

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
