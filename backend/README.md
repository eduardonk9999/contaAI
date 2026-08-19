# Backend ContAI

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
- `POST /v1/sales/preview`
- `POST /v1/sales/confirm`
- `GET /v1/transactions`
- `GET /v1/dashboard/summary`

