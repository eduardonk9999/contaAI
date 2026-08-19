<div align="center">

# 🧾 ContAI

**Copiloto financeiro com controle de estoque para quem vende de verdade.**

*"vendi 3 camisetas por 50 reais cada"* → venda registrada, estoque baixado, lucro calculado.

<br>

![Status](https://img.shields.io/badge/status-MVP%20em%20desenvolvimento-yellow?style=flat-square)
![Backend](https://img.shields.io/badge/backend-Fastify%20%2B%20TypeScript-000000?style=flat-square&logo=fastify)
![App](https://img.shields.io/badge/app-Flutter-02569B?style=flat-square&logo=flutter)
![Node](https://img.shields.io/badge/node-%E2%89%A522.5-339933?style=flat-square&logo=node.js&logoColor=white)
![Licença](https://img.shields.io/badge/licen%C3%A7a-n%C3%A3o%20definida-lightgrey?style=flat-square)

</div>

---

## O problema

O pequeno comerciante — vendedor de pipoca, ambulante, lojista, MEI — controla o negócio de cabeça, no caderno ou no WhatsApp. Sistemas de gestão existem, mas exigem cadastro, navegação e disciplina que não cabem na correria da banca.

Aí ele não sabe responder o básico: **quanto vendi hoje? quanto realmente lucrei? o que precisa repor?**

## A solução

O ContAI troca o formulário por uma frase. O comerciante fala ou digita naturalmente, e o sistema faz o resto:

```
  "vendi 3 camisetas por 50 reais cada"
                  │
                  ▼
        ┌─────────────────────┐
        │  IA interpreta      │   extrai produto, quantidade e preço
        └─────────────────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │  Backend calcula    │   custo, lucro, margem e impacto no estoque
        │  (determinístico)   │   ⚠️  nada é gravado ainda
        └─────────────────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │  Prévia editável    │   o usuário revisa, corrige e confirma
        └─────────────────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │  Confirmação        │   venda + itens + baixa de estoque
        │  atômica            │   em uma única transação de banco
        └─────────────────────┘
```

O resultado é lucro em tempo real e alerta de reposição, sem o comerciante abrir uma planilha.

---

## Princípios de projeto

Cinco decisões que atravessam todo o código. Elas não são detalhe de implementação — são o que mantém o dinheiro correto:

| Princípio | Por quê |
|---|---|
| 💰 **Dinheiro em centavos, sempre inteiro** | `R$ 10,50` é `1050`. Zero erro de ponto flutuante em cálculo financeiro. |
| 🧠 **A IA sugere, o backend decide** | O modelo extrai intenção. Dinheiro, custo, lucro, margem e estoque são calculados por regra determinística — nunca pelo LLM. |
| 👁️ **Prévia não grava nada** | O preview é puro. Banco e estoque só mudam depois da confirmação explícita. |
| 🧊 **Custo congelado na venda** | O item guarda o custo do momento. Mudar o preço do produto hoje não reescreve o lucro de ontem. |
| ⚛️ **Confirmação atômica e idempotente** | Transação, itens e movimento de estoque numa transação só. Reenviar a mesma chave não duplica a venda. |

---

## Stack

| Camada | Tecnologia |
|---|---|
| **API** | Fastify 5 + TypeScript (ESM) |
| **Validação** | Zod |
| **Banco (MVP local)** | SQLite via `node:sqlite` — destino: PostgreSQL/Supabase |
| **IA** | OpenAI — interpretação de texto e transcrição de áudio |
| **App** | Flutter |

---

## Estrutura do repositório

```text
contaai/
├── app/                 # Aplicativo Flutter (não iniciado)
├── backend/
│   ├── src/
│   │   ├── server.ts    # Rotas Fastify, validação e tratamento de erro
│   │   ├── sales.ts     # Preview, interpretação de texto e confirmação de venda
│   │   ├── database.ts  # Schema, migração e seed da loja de demonstração
│   │   └── domain.ts    # Tipos do domínio
│   └── postman/         # Coleção com os fluxos da API
└── docs/                # Produto, regras de negócio, contrato e monetização
```

---

## Rodando o backend

**Requisito:** Node 22.5 ou superior (o projeto usa o módulo nativo `node:sqlite`).

```bash
cd backend && npm install && npm run dev
```

A API sobe em `http://localhost:3333`, cria o banco em `backend/data/contaai.db` e semeia uma loja de demonstração com três produtos: *Camiseta básica*, *Boné* e *Garrafa térmica*.

Um teste rápido de ponta a ponta:

```bash
curl -s -X POST http://localhost:3333/v1/sales/preview -H 'Content-Type: application/json' -d '{"text":"vendi 3 camisetas por 50 reais cada"}'
```

A coleção do Postman em `backend/postman/` cobre o fluxo completo, do cadastro de produto ao dashboard.

### Scripts

| Comando | O que faz |
|---|---|
| `npm run dev` | Sobe a API com recarga automática |
| `npm start` | Sobe a API |
| `npm run typecheck` | Verifica os tipos sem gerar build |
| `npm test` | Roda os testes (nenhum escrito ainda) |

---

## Endpoints

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/health` | Verificação de saúde |
| `GET` | `/v1/products` | Lista os produtos ativos da loja |
| `POST` | `/v1/products` | Cadastra produto com estoque inicial auditável |
| `POST` | `/v1/sales/preview` | Gera prévia a partir de `text` ou de `items` — **não grava nada** |
| `POST` | `/v1/sales/confirm` | Confirma a venda e baixa o estoque atomicamente |
| `GET` | `/v1/transactions` | Histórico de transações |
| `GET` | `/v1/dashboard/summary` | Faturamento, custo, lucro, margem e valor em estoque |

Todas as respostas seguem o envelope `{ "data": ... }`; erros usam `{ "error": { "code", "message" } }`.

---

## Estado atual

**Funcionando no backend**

- ✅ Cadastro e listagem de produtos, com movimento de estoque inicial
- ✅ Prévia de venda por texto em português informal, incluindo números por extenso
- ✅ Prévia de venda manual, por item
- ✅ Avisos automáticos: estoque negativo, estoque baixo, preço fora do cadastro, margem negativa
- ✅ Confirmação idempotente, com baixa de estoque e histórico de movimentação
- ✅ Dashboard com faturamento, custo, lucro, margem e valor em estoque

**Ainda não**

- ⬜ Autenticação e múltiplas lojas — hoje há uma loja de demonstração fixa
- ⬜ Entrada por áudio e transcrição
- ⬜ Compras, despesas, receitas e cancelamento com estorno
- ⬜ Alertas persistidos
- ⬜ Migração para PostgreSQL/Supabase com RLS
- ⬜ Aplicativo Flutter

---

## Documentação

| Documento | Conteúdo |
|---|---|
| [`docs/BUSINESS-RULES.md`](docs/BUSINESS-RULES.md) | Visão do produto, entidades e regras de negócio numeradas |
| [`docs/BACKEND-SPEC.md`](docs/BACKEND-SPEC.md) | Contrato completo entre API e app Flutter |
| [`docs/DATA-MODEL.md`](docs/DATA-MODEL.md) | Entidades, relacionamentos e corte do banco para o MVP |
| [`docs/BUSINESS-MODEL.md`](docs/BUSINESS-MODEL.md) | Modelo de receita, planos e argumentação comercial |
| [`docs/CODEX-PROMPT.md`](docs/CODEX-PROMPT.md) | Prompt inicial do projeto, preservado como referência histórica |

---

## Modelo de negócio

SaaS freemium. O plano gratuito reduz a barreira de entrada com cadastro de produtos, lançamentos manuais e um limite mensal de interpretações por IA. Os planos pagos liberam lançamento por voz, produtos ilimitados, dashboard completo e alertas — mantendo o custo de IA proporcional ao plano contratado.

Detalhes, hipóteses de preço e estratégia de aquisição em [`docs/BUSINESS-MODEL.md`](docs/BUSINESS-MODEL.md).

---

<div align="center">
<sub>Feito para quem controla o negócio de cabeça, no caderno ou pelo WhatsApp.</sub>
</div>
