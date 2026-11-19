# Imagem da API Clinica Pet (Node.js + Express)
# O Render injeta a variavel PORT; o Express escuta nela via process.env.PORT.

FROM node:22-alpine

WORKDIR /app

# Dependencias primeiro (aproveita o cache de camadas).
COPY package*.json ./
RUN npm ci --omit=dev

# Codigo da aplicacao.
COPY src ./src
COPY test ./test

EXPOSE 3000

CMD ["npm", "start"]
