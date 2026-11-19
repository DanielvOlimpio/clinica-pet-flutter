const express = require('express');
const cors = require('cors');

const petsRoutes = require('./routes/pets.routes');

const app = express();

// Middlewares globais.
app.use(cors());
app.use(express.json());

// Rota de saude (util para verificar o deploy no Render).
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', app: 'clinica-pet-api' });
});

// Rotas do recurso principal: /pets (atendimentos da clinica).
app.use('/pets', petsRoutes);

// Rota nao encontrada.
app.use((_req, res) => {
  res.status(404).json({ erro: 'Rota nao encontrada' });
});

// Tratamento centralizado de erros: responde com JSON adequado
// sem encerrar o servidor.
app.use((erro, _req, res, _next) => {
  console.error('Erro na API:', erro.message);
  res.status(500).json({ erro: 'Erro interno no servidor' });
});

module.exports = app;
