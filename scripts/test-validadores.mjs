import fs from 'node:fs';
import vm from 'node:vm';

const html = fs.readFileSync('app/index.html', 'utf8');
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
