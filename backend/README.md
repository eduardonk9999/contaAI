# Backend Conta+

API do MVP em Fastify, TypeScript e SQLite.

## Executar

```bash
npm install
npm run dev
```

A API inicia em `http://localhost:3333`. Na primeira execução, o banco e os produtos de demonstração são criados automaticamente.

## Rotas do MVP

- `GET /health`
- `GET /v1/products`
- `POST /v1/products`
- `GET /v1/products/:productId`
- `PATCH /v1/products/:productId`
- `POST /v1/products/:productId/stock-adjustments`
- `GET /v1/products/:productId/stock-movements`
- `POST /v1/sales/preview`
- O reconhecimento de voz acontece no navegador; o texto reconhecido usa `POST /v1/sales/preview`.
- `POST /v1/sales/confirm`
- `GET /v1/transactions`
- `GET /v1/dashboard/summary`

## Restaurar a demonstração

Pare a API e execute `npm run demo:reset`. Ao executar `npm start` novamente, o banco será recriado com os três produtos e o estoque inicial.
