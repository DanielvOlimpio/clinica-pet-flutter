# API Clínica Pet

API REST em **Node.js + Express + PostgreSQL** para a aplicação **Clínica Pet**
(registro de atendimentos veterinários). É o backend do aplicativo Flutter
localizado na raiz deste repositório.

## Rotas

| Método | Rota       | Descrição |
| --- | --- | --- |
| `POST` | `/pets`    | Cadastra um novo atendimento. Retorna `201` com o registro criado (incluindo o `id` remoto) ou `200` se o `idLocal` já existir (idempotência, evita duplicidade). |
| `GET`  | `/pets`    | Lista todos os atendimentos armazenados no PostgreSQL. |
| `GET`  | `/health`  | Verificação de funcionamento (deploy). |

Exemplo de corpo do `POST /pets`:

```json
{
  "idLocal": "4b1f2c66-8a5a-4b8e-9d3f-1a2b3c4d5e6f",
  "atendimentoId": 3,
  "nome": "Thor",
  "especie": "Cão",
  "valor": 180.5
}
```

## Estrutura

```
api/
├── src/
│   ├── controllers/pets.controller.js  # validação + respostas HTTP
│   ├── routes/pets.routes.js           # rotas POST /pets e GET /pets
│   ├── services/pets.service.js        # consultas parametrizadas ao PostgreSQL
│   ├── database/database.js            # conexão (pg Pool) via variáveis de ambiente
│   ├── database/init.js                # criação da tabela "pets"
│   ├── app.js                          # Express + middlewares + tratamento de erros
│   └── server.js                       # inicialização (porta via process.env.PORT)
├── package.json
├── .env.example                        # nomes das variáveis necessárias
└── README.md
```

## Variáveis de ambiente

Configure no painel do Render (Environment) ou copie `.env.example` para `.env`
em desenvolvimento local:

- `DATABASE_URL` — string de conexão do PostgreSQL (Render fornece automaticamente ao criar o banco).
- `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE` — alternativa para desenvolvimento local.
- `PORT` — porta de escuta (o Render injeta automaticamente).

## Executando localmente

1. Tenha um PostgreSQL em execução e crie o banco `clinica_pet`.
2. `cd api && npm install`
3. Copie `.env.example` para `.env` e preencha com suas credenciais locais.
4. `npm start` (ou `npm run dev` com reinício automático).

## Publicação no Render

1. New → **Web Service**, apontando para este repositório.
2. **Root Directory:** `api`
3. **Build Command:** `npm install` · **Start Command:** `npm start`
4. New → **PostgreSQL** (banco gerenciado) e copie a *Internal Database URL*.
5. Em *Environment*, adicione `DATABASE_URL` com essa string.
6. Faça deploy e teste `https://<servico>.onrender.com/health`.
