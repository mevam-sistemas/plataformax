import fs from 'node:fs';
import vm from 'node:vm';

const html = fs.readFileSync('app/index.html', 'utf8');
const convite = fs.readFileSync('supabase/functions/convidar-equipe-modox/index.ts', 'utf8');
const headers = fs.readFileSync('_headers', 'utf8');
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
if (!html.includes('.btn.xs{padding:8px 11px;font-size:12.5px;border-radius:9px;min-height:44px}')) {
  throw new Error('Botões compactos não respeitam alvo de toque de 44 px');
}
console.log('✓ login, recuperação e botões compactos atendem os contratos de acessibilidade');
