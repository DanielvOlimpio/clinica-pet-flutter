// Teste local da API com um PostgreSQL REAL (binarios embutidos, porta 5433).
// Artefato descartavel: nao faz parte da entrega.
const EmbeddedPostgres = require('embedded-postgres').default;

async function main() {
  const pg = new EmbeddedPostgres({
    databaseDir: process.cwd() + "/.pgdata-" + Date.now(),
    user: 'postgres',
    password: 'senha_local',
    port: 5433,
    persistent: false,
  });
  await pg.initialise();
  await pg.start();
  await pg.createDatabase('clinica_pet');

  process.env.PGHOST = 'localhost';
  process.env.PGPORT = '5433';
  process.env.PGUSER = 'postgres';
  process.env.PGPASSWORD = 'senha_local';
  process.env.PGDATABASE = 'clinica_pet';
  process.env.PORT = '3000';

  const { inicializarBanco } = require('../src/database/init');
  await inicializarBanco();

  const app = require('../src/app');
  const server = app.listen(3000, async () => {
    const http = require('http');
    const req = (method, path, body) => new Promise((res) => {
      const r = http.request({ host: 'localhost', port: 3000, path, method, headers: body ? {'content-type':'application/json'} : {} }, (x) => {
        let d = ''; x.on('data', c => d += c); x.on('end', () => res(x.statusCode + ' ' + d));
      });
      if (body) r.write(JSON.stringify(body));
      r.end();
    });

    console.log('TESTE A - POST valido:', await req('POST', '/pets', { idLocal: 'uuid-teste-1', atendimentoId: 3, nome: 'Thor', especie: 'Cão', valor: '180,50' }));
    console.log('TESTE B - GET:', await req('GET', '/pets'));
    console.log('TESTE C - reenvio mesmo idLocal (idempotencia):', await req('POST', '/pets', { idLocal: 'uuid-teste-1', atendimentoId: 3, nome: 'Thor', especie: 'Cão', valor: '180,50' }));
    console.log('TESTE D - segundo registro:', await req('POST', '/pets', { idLocal: 'uuid-teste-2', atendimentoId: 4, nome: 'Mia', especie: 'Gato', valor: 120.5 }));
    console.log('TESTE E - GET final:', await req('GET', '/pets'));

    server.close(async () => {
      await pg.stop();
      process.exit(0);
    });
  });
}

main().catch((e) => { console.error('FALHA:', e); process.exit(1); });
