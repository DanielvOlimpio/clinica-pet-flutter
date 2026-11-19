// Teste manual da API contra um PostgreSQL em execução.
//
// Como usar (API e PostgreSQL no ar, variáveis PG* ou DATABASE_URL definidas):
//
//   cd api
//   node test/teste_manual.js
//
// O script: inicializa a tabela, sobe o Express em memória e exercita as
// rotas POST /pets e GET /pets, incluindo a verificação de idempotência.
// NÃO faz parte dos testes automatizados (flutter test); é apoio à execução
// dos Testes 1, 3 e 4 do roteiro da atividade.

const http = require('http');
const { inicializarBanco } = require('../src/database/init');
const app = require('../src/app');

const PORTA_TESTE = 3100;

function requisitar(metodo, caminho, corpo) {
  return new Promise((resolve) => {
    const r = http.request(
      {
        host: 'localhost',
        port: PORTA_TESTE,
        path: caminho,
        method: metodo,
        headers: corpo ? { 'content-type': 'application/json' } : {},
      },
      (res) => {
        let dados = '';
        res.on('data', (c) => (dados += c));
        res.on('end', () => resolve(`${res.statusCode} ${dados}`));
      },
    );
    if (corpo) r.write(JSON.stringify(corpo));
    r.end();
  });
}

async function main() {
  await inicializarBanco();

  const servidor = app.listen(PORTA_TESTE, async () => {
    console.log('TESTE 1 — POST válido (esperado 201):');
    console.log(
      '  ',
      await requisitar('POST', '/pets', {
        idLocal: 'teste-manual-1',
        atendimentoId: 3,
        nome: 'Thor',
        especie: 'Cão',
        valor: '180,50',
      }),
    );

    console.log('TESTE 2 — POST válido (esperado 201):');
    console.log(
      '  ',
      await requisitar('POST', '/pets', {
        idLocal: 'teste-manual-2',
        atendimentoId: 4,
        nome: 'Mia',
        especie: 'Gato',
        valor: 120.5,
      }),
    );

    console.log('TESTE 3 — re-envio do mesmo idLocal (esperado 200 e MESMO id):');
    console.log(
      '  ',
      await requisitar('POST', '/pets', {
        idLocal: 'teste-manual-1',
        atendimentoId: 3,
        nome: 'Thor',
        especie: 'Cão',
        valor: '180,50',
      }),
    );

    console.log('TESTE 4 — GET /pets (esperado 200 e 2 registros):');
    console.log('  ', await requisitar('GET', '/pets'));

    console.log('TESTE 5 — campos ausentes (esperado 400):');
    console.log('  ', await requisitar('POST', '/pets', {}));

    servidor.close();
  });
}

main().catch((erro) => {
  console.error('Falha no teste manual:', erro.message);
  process.exit(1);
});
