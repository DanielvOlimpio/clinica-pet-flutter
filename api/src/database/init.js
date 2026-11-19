const pool = require('./database');

// Cria a tabela da entidade principal (Pet / atendimento veterinario),
// se ainda nao existir.
//
// - id: identificador unico remoto (serial do PostgreSQL), devolvido ao
//   aplicativo na resposta do POST e guardado como id_remoto no SQLite.
// - id_local: identificador unico de origem gerado pelo Flutter (UUID).
//   Serve de estrategia simples de idempotencia: re-envios de um mesmo
//   registro pendente NAO criam duplicidades no PostgreSQL.
async function inicializarBanco() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS pets (
      id SERIAL PRIMARY KEY,
      id_local VARCHAR(64) UNIQUE,
      atendimento_id INTEGER NOT NULL,
      nome VARCHAR(120) NOT NULL,
      especie VARCHAR(60) NOT NULL,
      valor NUMERIC(10, 2) NOT NULL CHECK (valor > 0),
      criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
  console.log('Banco de dados verificado (tabela "pets" ok).');
}

module.exports = { inicializarBanco };
