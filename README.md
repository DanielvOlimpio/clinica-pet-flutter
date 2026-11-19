# Clínica Pet — Programação para Dispositivos Móveis II (2º Bimestre)

**Nome da temática do aplicativo:** Clínica Pet (registro de atendimentos veterinários)

**Nome completo do estudante:** Daniel Victor Olimpio Souza Morais

**Link da API publicada:** *Pendente de publicação* — a API está pronta para o
Render (ver seção [Publicação da API no Render](#publicação-da-api-no-render));
assim que o serviço for criado na conta do Render, a URL do tipo
`https://clinica-pet-api.onrender.com` deverá ser informada aqui.

## Descrição resumida da aplicação

Evolução do aplicativo **Clínica Pet** (primeiro bimestre, adaptado do Projeto
Bank): registro de atendimentos veterinários com **identificador do
atendimento, nome do pet, espécie e valor da consulta**. Nesta etapa o
aplicativo ganhou **persistência local (SQLite)**, **API própria
(Node.js + Express) com banco **PostgreSQL**** e o comportamento
**Offline-first**: com a API indisponível o cadastro continua funcionando e o
registro fica salvo no dispositivo como *pendente*, para ser sincronizado
manualmente depois.

---

## 1. Tecnologias utilizadas

| Camada | Tecnologia |
| --- | --- |
| Aplicativo | Dart + Flutter |
| Banco local | SQLite (`sqflite`) |
| Comunicação HTTP | `http` |
| Backend | Node.js + Express |
| Banco remoto | PostgreSQL (`pg`) |
| Hospedagem prevista | Render |

## 2. Estrutura dos diretórios

```
clinica-pet-flutter/
├── lib/
│   ├── main.dart                    # MaterialApp / ThemeData (tema verde 0xFF00897B)
│   ├── models/
│   │   └── pet.dart                 # Entidade Pet + idLocal (UUID) + idRemoto + sincronizado
│   ├── database/
│   │   └── app_database.dart        # Criação/abertura do SQLite e tabela "pets"
│   ├── services/
│   │   ├── api_config.dart          # URL da API centralizada (dev e produção)
│   │   └── pet_api_service.dart     # Comunicação HTTP (POST/GET /pets) e exceções tipadas
│   ├── repository/
│   │   └── pet_repository.dart      # Regras de acesso a dados + Offline-first + sincronização
│   ├── components/
│   │   ├── editor.dart              # Componente de formulário (padrão do 1º bimestre)
│   │   └── tile_pet.dart            # Card/ListTile + indicador sincronizado/pendente
│   └── telas/
│       ├── lista_pets.dart          # Listagem, banner de pendências e botão "Sincronizar"
│       └── formulario_pet.dart      # Formulário de cadastro (preservado do 1º bimestre)
├── api/
│   ├── src/
│   │   ├── controllers/pets.controller.js  # Validações e respostas HTTP
│   │   ├── routes/pets.routes.js           # POST /pets e GET /pets
│   │   ├── services/pets.service.js        # Consultas parametrizadas ao PostgreSQL
│   │   ├── database/database.js            # Conexão (pg Pool) via variáveis de ambiente
│   │   ├── database/init.js                # Criação da tabela "pets"
│   │   ├── app.js                          # Express + middlewares + tratamento de erros
│   │   └── server.js                       # Porta via process.env.PORT
│   ├── package.json
│   ├── .env.example
│   └── README.md
├── test/
│   ├── widget_test.dart             # Testes da interface com repositório fake
│   └── integracao_api_test.dart     # Teste real Flutter ↔ API ↔ PostgreSQL
└── README.md
```

## 3. Como executar o Flutter

```bash
flutter pub get
flutter run
```

- Emulador Android: a URL padrão da API é `http://10.0.2.2:3000`
  (`10.0.2.2` é o `localhost` do computador visto pelo emulador).
- Dispositivo físico: use o IP local do computador na mesma rede Wi-Fi.
- API publicada: execute com a URL do Render:

```bash
flutter run --dart-define=API_URL=https://SEU-SERVICO.onrender.com
```

## 4. Como configurar o PostgreSQL

**Local:** instale o PostgreSQL e crie o banco (a tabela é criada
automaticamente pela API ao iniciar):

```sql
CREATE DATABASE clinica_pet;
```

**Render:** crie um serviço **PostgreSQL** e copie a *Internal Database URL*
para a variável `DATABASE_URL` do serviço da API. A tabela `pets` é criada
automaticamente no primeiro start.

## 5. Como executar a API

```bash
cd api
npm install
cp .env.example .env      # preencha com suas credenciais locais
npm start                 # ou: npm run dev
```

A API sobe em `http://localhost:3000` (porta configurável em `PORT`).

## 6. Variáveis de ambiente

| Variável | Onde | Descrição |
| --- | --- | --- |
| `DATABASE_URL` | API | String de conexão do PostgreSQL (Render fornece automaticamente). |
| `PGHOST` `PGPORT` `PGUSER` `PGPASSWORD` `PGDATABASE` | API | Alternativa para desenvolvimento local (sem SSL). |
| `PORT` | API | Porta de escuta (o Render injeta automaticamente). |
| `API_URL` | Flutter | URL da API via `--dart-define` (padrão: `http://10.0.2.2:3000`). |

Nunca envie `.env` ao Git (já está no `.gitignore`; use `.env.example` como
modelo).

## 7. Principais rotas da API

| Método | Rota | Descrição |
| --- | --- | --- |
| `POST` | `/pets` | Cadastra um atendimento. `201` com o registro criado (inclui `id` remoto). Se o `idLocal` já existir (re-envio), responde `200` com o registro existente — idempotência, sem duplicidade. |
| `GET` | `/pets` | Lista os atendimentos do PostgreSQL. |
| `GET` | `/health` | Verificação de funcionamento do deploy. |

Corpo do `POST /pets`:

```json
{
  "idLocal": "uuid-v4-gerado-no-flutter",
  "atendimentoId": 3,
  "nome": "Thor",
  "especie": "Cão",
  "valor": 180.50
}
```

## 8. Como funciona o Offline-first

O comportamento é implementado na camada **Repository** (`lib/repository/pet_repository.dart`),
que centraliza a decisão entre SQLite e API — as telas não fazem SQL nem HTTP.

**Cenário 1 — API disponível:**
1. Usuário preenche o formulário e salva.
2. Repository envia `POST /pets` para a API.
3. API grava no PostgreSQL e devolve confirmação + `id` remoto.
4. Registro é gravado no SQLite com `sincronizado = 1` e `id_remoto`.
5. Mensagem: *"Registro cadastrado e sincronizado com sucesso."*

**Cenário 2 — API indisponível:**
1. Repository tenta o `POST /pets` e a comunicação falha (`ApiIndisponivel`).
2. Registro é gravado no SQLite com `sincronizado = 0` (pendente).
3. Listagem continua sendo atualizada com os dados locais.
4. Mensagem: *"Sem conexão com o servidor. Registro salvo no dispositivo."*
5. O registro sobrevive ao fechamento e reabertura do aplicativo.

**Cenário 3 — Sincronização manual:**
1. Banner laranja informa: *"Existem registros aguardando sincronização (n)."*
2. Usuário aciona o botão "Sincronizar pendentes" (ícone `sync` no AppBar).
3. Repository busca no SQLite todos os registros com `sincronizado = 0`.
4. Cada pendente é enviado à API; com confirmação (HTTP 2xx) o SQLite grava
   `sincronizado = 1` + `id_remoto`.
5. Um erro NÃO interrompe o lote — o registro falho continua pendente.
6. Resumo: *"Sincronização concluída. X registro(s) enviado(s)."* ou
   *"Não foi possível sincronizar alguns registros. Eles continuam salvos localmente."*

**Proteção contra duplicidade:** todo registro carrega um `id_local` (UUID v4,
gerado no momento do cadastro). A API possui `UNIQUE(id_local)` e, ao receber
um re-envio, devolve o registro já existente em vez de criar outro.

## 9. Como realizar a sincronização manual

1. Abra o aplicativo (com a API em execução/publicada).
2. Se existirem pendências, o banner laranja e os ícones
   `cloud_upload` (laranja) na lista indicam os registros.
3. Toque no ícone `sync` do AppBar ("Sincronizar pendentes").
4. O resumo é exibido em um SnackBar e os ícones mudam para
   `cloud_done` (verde) nos registros confirmados.

## Publicação da API no Render

1. Render → **New → Web Service**, conecte este repositório do GitHub.
2. **Root Directory:** `api`
3. **Build Command:** `npm install` · **Start Command:** `npm start`
4. Render → **New → PostgreSQL** e copie a *Internal Database URL*.
5. No Web Service, em **Environment**, adicione `DATABASE_URL` com essa string.
6. Deploy e teste `https://SEU-SERVICO.onrender.com/health`.

## Testes

```bash
# Testes da interface (não dependem de rede):
flutter test test/widget_test.dart

# Teste real Flutter ↔ API ↔ PostgreSQL (requer a API em execução):
flutter test test/integracao_api_test.dart --dart-define=API_URL=http://localhost:3000
```
