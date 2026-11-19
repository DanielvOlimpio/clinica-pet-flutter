const { Pool } = require('pg');

// Conexao com o PostgreSQL configurada por variaveis de ambiente
// (DATABASE_URL no Render; variaveis separadas em desenvolvimento).
const pool = new Pool(
  process.env.DATABASE_URL
    ? {
        connectionString: process.env.DATABASE_URL,
        // Hospedeiros gerenciados (Render, Neon...) exigem SSL.
        ssl: { rejectUnauthorized: false },
      }
    : {
        host: process.env.PGHOST || 'localhost',
        port: Number(process.env.PGPORT || 5432),
        user: process.env.PGUSER || 'postgres',
        password: process.env.PGPASSWORD,
        database: process.env.PGDATABASE || 'clinica_pet',
      },
);

module.exports = pool;
