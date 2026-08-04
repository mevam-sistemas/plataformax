# Operação segura do MODOX

## Arquitetura atual

- O site e o aplicativo são arquivos estáticos publicados pelo Cloudflare Pages.
- A aplicação usa o projeto Supabase compartilhado com o 360social.
- As tabelas do MODOX estão no esquema `public`; autenticação e arquivos usam
  os esquemas e serviços `auth` e `storage`.
- A chave pública do Supabase pode existir no navegador. Chaves `service_role`,
  senhas de banco, credenciais do R2 e segredos de pagamentos jamais podem ser
  colocados neste repositório ou no código do navegador.

## Publicação

1. Criar uma branch a partir de `main`.
2. Abrir pull request e aguardar `Validar aplicação` e a prévia do Cloudflare.
3. Testar na prévia os fluxos alterados.
4. Fazer merge somente depois das duas validações.
5. Confirmar a produção e registrar a mudança em `CHANGELOG.md`.
6. Para uma nova versão, atualizar somente `MODOX_VERSION` em `app/version.js`.
   O rodapé e o service worker leem essa mesma fonte; o PWA instalado substitui
   o cache anterior automaticamente.

O Cloudflare atualmente publica `main` automaticamente. Por isso não se deve
fazer commit direto em `main`.

## Backup compartilhado

O workflow `Backup independente`, no repositório `mevam-sistemas/social360`, é
o backup oficial do projeto Supabase compartilhado. Ele inclui:

- esquemas `public`, `social`, `auth` e `storage`;
- todos os buckets e objetos do Supabase Storage;
- manifesto e checksums SHA-256;
- pacote cifrado antes do envio ao bucket privado no Cloudflare R2.

Executar outro workflow neste repositório copiaria o mesmo banco e os mesmos
arquivos, aumentando complexidade sem melhorar a recuperação. O alerta e a
responsabilidade operacional do backup devem ser tratados como compartilhados
pelos dois produtos.

O teste automatizado atual comprova trimestralmente a restauração do esquema
`social`. O dump contém o esquema `public` do MODOX, mas ainda falta um ensaio
automatizado específico de restauração desse esquema. Até esse ensaio passar,
não considerar a recuperação do MODOX integralmente comprovada.

## Verificação rápida após implantação

- abrir `/app/` em janela anônima;
- entrar com uma conta controlada;
- solicitar recuperação de senha e confirmar que o link volta a `/app/`;
- testar upload de imagem e gravação de áudio em celular;
- conferir um perfil de aluno e um perfil administrativo;
- verificar erros no console e respostas recusadas pelo Supabase;
- confirmar que `/app/manifest.webmanifest` e `/app/sw.js` respondem com 200.

## Incidentes

1. Não apagar evidências nem alterar dados antes de entender o alcance.
2. Registrar horário, usuário, tela, comportamento e mudança relacionada.
3. Conter o problema com correção progressiva; evitar remoções destrutivas.
4. Validar com conta controlada antes de envolver um usuário real.
5. Documentar causa, correção, teste e pendências no histórico da versão.
