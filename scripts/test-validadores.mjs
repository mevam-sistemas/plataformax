import fs from 'node:fs';
import vm from 'node:vm';

const html = fs.readFileSync('app/index.html', 'utf8');
const convite = fs.readFileSync('supabase/functions/convidar-equipe-modox/index.ts', 'utf8');
const headers = fs.readFileSync('_headers', 'utf8');
const sw = fs.readFileSync('app/sw.js', 'utf8');
const bloco = html.match(/function cpfValido\(c\)[\s\S]*?\nasync function abrirPerfil/);
if (!bloco) throw new Error('Validadores de CPF/CNPJ não encontrados');

const contexto = {};
vm.createContext(contexto);
vm.runInContext(bloco[0].replace(/\nasync function abrirPerfil[\s\S]*/, ''), contexto);

const casos = [
  ['CPF válido', contexto.cpfValido('529.982.247-25'), true],
  ['CPF inválido', contexto.cpfValido('529.982.247-24'), false],
  ['CNPJ válido', contexto.cnpjValido('47.897.085/0001-16'), true],
  ['CNPJ inválido', contexto.cnpjValido('47.897.085/0001-17'), false]
];

for (const [nome, atual, esperado] of casos) {
  if (atual !== esperado) throw new Error(`${nome}: esperado ${esperado}, recebido ${atual}`);
  console.log(`✓ ${nome}`);
}

for (const obsoleto of ['Ninguém precisa de senha', 'Não existe senha para vazar', 'sem senha, sem convite']) {
  if (html.includes(obsoleto)) throw new Error(`Texto de acesso obsoleto encontrado: ${obsoleto}`);
}
for (const contrato of ['listUsers({page:1,perPage:1000})', 'auth_user_id:novoUid', "deleteUser(novoUid)"]) {
  if (!convite.includes(contrato)) throw new Error(`Contrato de vínculo do convite ausente: ${contrato}`);
}
console.log('✓ convite vincula o usuário autenticado ao cadastro da equipe');

for (const contrato of [
  "Content-Security-Policy: default-src 'self'",
  "object-src 'none'",
  "frame-ancestors 'none'",
  'Strict-Transport-Security:',
  'X-Frame-Options: DENY'
]) {
  if (!headers.includes(contrato)) throw new Error(`Cabeçalho de segurança ausente: ${contrato}`);
}
console.log('✓ cabeçalhos de segurança obrigatórios presentes');

for (const local of ['/app/supabase.min.js', '/app/qrcode.min.js']) {
  if (!html.includes(`src="${local}"`)) throw new Error(`Biblioteca local ausente da aplicação: ${local}`);
  if (!sw.includes(`'${local}'`)) throw new Error(`Biblioteca local ausente do shell PWA: ${local}`);
}
if (headers.includes('cdn.jsdelivr.net')) throw new Error('CSP ainda permite CDN executável desnecessária');
console.log('✓ dependências executáveis críticas são locais e entram no shell versionado');

for (const caminho of ['/app/sw.js', '/app/version.js']) {
  const bloco = headers.match(new RegExp(`${caminho.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\n([\\s\\S]*?)(?=\\n\\S|$)`))?.[1] || '';
  if (!bloco.includes('Cache-Control: no-cache, no-store, must-revalidate')) {
    throw new Error(`Cache de atualização não desativado em ${caminho}`);
  }
}
console.log('✓ service worker e versão não ficam presos no cache da CDN');

for (const association of [
  '<label for="email">Seu e-mail</label>',
  '<label for="senha">Senha</label>',
  '<label for="cc-email">Seu e-mail</label>',
  '<label for="rs-senha">Nova senha</label>'
]) {
  if (!html.includes(association)) throw new Error(`Rótulo sem associação semântica: ${association}`);
}
for (const recuperacao of ['id="s-recuperar"', 'for="rc-email"', "go('recuperar')", "resetPasswordForEmail(email", 'Se este e-mail estiver cadastrado']) {
  if (!html.includes(recuperacao)) throw new Error(`Fluxo dedicado de recuperação incompleto: ${recuperacao}`);
}
if (!html.includes('.btn.xs{padding:8px 11px;font-size:12.5px;border-radius:9px;min-height:44px}')) {
  throw new Error('Botões compactos não respeitam alvo de toque de 44 px');
}
console.log('✓ login, recuperação e botões compactos atendem os contratos de acessibilidade');

for (const contrato of [
  '<main class="wrap" id="conteudo-principal">',
  '.pe-pagina-arbor{display:inline-flex',
  'min-height:44px;padding:8px 0',
  'button:focus-visible,a:focus-visible,input:focus-visible',
  'placeholder="Mínimo 10 caracteres"',
  'function associarRotulos(root=document)'
]) {
  if (!html.includes(contrato)) throw new Error(`Contrato global de acessibilidade ausente: ${contrato}`);
}
console.log('✓ região principal, foco visível, textos de senha e links de rodapé são acessíveis');

if ((html.match(/senha\.length < 10/g) || []).length < 3 || html.includes('senha.length < 6')) {
  throw new Error('A política de senha do cliente diverge dos 10 caracteres exigidos no servidor');
}
if (/Mínimo 6 caracteres/i.test(html)) throw new Error('A interface ainda comunica política antiga de senha');
console.log('✓ criação, matrícula e recuperação exigem senha com 10 caracteres');

for (const contrato of ['PushManager', "sb.rpc('registrar_push'", "sb.functions.invoke('notificar-conversa'", "event.data?.tipo === 'ATUALIZAR_AGORA'"]) {
  if (!html.includes(contrato) && !sw.includes(contrato)) {
    throw new Error(`Contrato do PWA ausente: ${contrato}`);
  }
}
console.log('✓ PWA possui atualização controlada e notificações vinculadas ao usuário');

for (const [arquivo, limite] of [['app/index.html', 380_000], ['app/supabase.min.js', 250_000], ['app/qrcode.min.js', 80_000]]) {
  const tamanho = fs.statSync(arquivo).size;
  if (tamanho > limite) throw new Error(`${arquivo} excedeu o orçamento de desempenho: ${tamanho} > ${limite}`);
}
if (/<script[^>]+src=["']https?:\/\//i.test(html)) throw new Error('Aplicação principal voltou a executar script de terceiros');
console.log('✓ arquivos críticos respeitam o orçamento e não executam scripts remotos');
