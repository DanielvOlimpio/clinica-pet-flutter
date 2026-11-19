const pool = require('../database/database');

// Regras de acesso ao PostgreSQL da entidade Pet (atendimento veterinario).
// Todas as consultas sao parametrizadas ($1, $2...) para evitar SQL injection.

async function inserir({ idLocal, atendimentoId, nome, especie, valor }) {
  const resultado = await pool.query(
    `INSERT INTO pets (id_local, atendimento_id, nome, especie, valor)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, id_local, atendimento_id, nome, especie, valor, criado_em;`,
    [idLocal, atendimentoId, nome, especie, valor],
  );
  return resultado.rows[0];
}

// Busca um registro ja existente pelo id_local (idempotencia).
async function buscarPorIdLocal(idLocal) {
  const resultado = await pool.query(
    'SELECT id, id_local, atendimento_id, nome, especie, valor, criado_em FROM pets WHERE id_local = $1;',
    [idLocal],
  );
  return resultado.rows[0] || null;
}

async function listarTodos() {
  const resultado = await pool.query(
    'SELECT id, id_local, atendimento_id, nome, especie, valor, criado_em FROM pets ORDER BY id ASC;',
  );
  return resultado.rows;
}

module.exports = { inserir, buscarPorIdLocal, listarTodos };
