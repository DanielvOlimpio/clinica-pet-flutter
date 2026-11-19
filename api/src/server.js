// Carrega as variaveis do arquivo .env (apenas em desenvolvimento local;
// no Render as variaveis de ambiente sao configuradas no painel).
require('dotenv').config();

const app = require('./app');
const { inicializarBanco } = require('./database/init');

const PORT = process.env.PORT || 3000;

// Cria a tabela (se necessario) antes de aceitar requisicoes.
inicializarBanco()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`API Clinica Pet em execucao na porta ${PORT}`);
    });
  })
  .catch((erro) => {
    console.error('Falha ao inicializar o banco de dados:', erro.message);
    process.exit(1);
  });

// Tratamento de erros nao capturados: registra e mantem o processo vivo,
// evitando encerrar inesperadamente o servidor em producao.
process.on('uncaughtException', (erro) => {
  console.error('Erro nao capturado:', erro);
});

process.on('unhandledRejection', (motivo) => {
  console.error('Promise rejeitada nao tratada:', motivo);
});
