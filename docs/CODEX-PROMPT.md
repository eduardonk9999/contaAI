# Prompt para Codex - Conta+ Backend

Copie este prompt para o Codex ou outro agente de código.

---

## PROMPT

```
Você vai implementar o backend do Conta+, um copiloto financeiro com controle de estoque para pequenos comerciantes brasileiros.

## Contexto do Projeto

- Monorepo com `apps/api/` (Fastify + TypeScript) e `apps/mobile/` (Flutter)
- Banco de dados: Supabase (PostgreSQL)
- IA: OpenAI (Whisper para áudio, GPT-4o-mini para extração)
- Infraestrutura já existe: logging, error handling, env config

## O que o usuário faz

Vendedor de pipoca/loja fala ou digita:
- "vendi 5 pipocas" → sistema desconta estoque, calcula lucro
- "comprei 10kg de milho por 80 reais" → sistema aumenta estoque
- "gastei 50 de luz" → registra despesa

## Sua tarefa

Implementar na ordem:

### 1. Migrações Supabase (`supabase/migrations/`)

Criar 3 tabelas com RLS:

**products:**
- id (UUID PK)
- user_id (FK auth.users)
- name (VARCHAR 200, unique por user)
- type (ENUM: 'SELLABLE', 'SUPPLY')
- cost_price_cents (INTEGER)
- sell_price_cents (INTEGER, nullable)
- stock_quantity (DECIMAL 10,3)
- stock_unit (VARCHAR 50, default 'unidade')
- min_stock_alert (DECIMAL 10,3)
- created_at, updated_at (TIMESTAMPTZ)

**transactions:**
- id (UUID PK)
- user_id (FK auth.users)
- type (ENUM: 'SALE', 'PURCHASE', 'EXPENSE', 'INCOME')
- total_amount_cents (INTEGER)
- cost_amount_cents (INTEGER)
- profit_cents (INTEGER)
- product_id (FK products, nullable)
- quantity (DECIMAL, nullable)
- unit_price_cents (INTEGER, nullable)
- description (VARCHAR 500)
- category (VARCHAR 100)
- source (ENUM: 'TEXT', 'VOICE', 'RECEIPT', 'MANUAL')
- original_input (TEXT)
- status (ENUM: 'PENDING', 'CONFIRMED', 'CANCELLED')
- confidence (DECIMAL 3,2)
- occurred_at, created_at, updated_at (TIMESTAMPTZ)

**alerts:**
- id (UUID PK)
- user_id (FK auth.users)
- type (ENUM: 'LOW_STOCK', 'NEGATIVE_MARGIN', 'GOAL_REACHED')
- product_id (FK products, nullable)
- title (VARCHAR 200)
- message (TEXT)
- read (BOOLEAN default false)
- created_at (TIMESTAMPTZ)

### 2. OpenAI Provider (`src/providers/openai.provider.ts`)

Implementar a interface AIProvider existente em `src/providers/ai.types.ts`:

```typescript
class OpenAIProvider implements AIProvider {
  // Transcreve áudio com Whisper
  async transcribeAudio(buffer: Buffer, mimeType: string): Promise<TranscriptionResult>

  // Extrai dados estruturados com GPT-4o-mini
  async extractStructuredData<T>(text: string, context: ExtractionContext): Promise<ExtractionResult<T>>
}
```

O contexto de extração deve incluir lista de produtos do usuário para matching.

System prompt deve:
- Entender português brasileiro informal
- Identificar tipo (SALE/PURCHASE/EXPENSE/INCOME)
- Extrair produto, quantidade, valor
- Calcular totais se quantidade * preço
- Retornar confidence score

### 3. Schemas Zod (`src/modules/*/schemas.ts`)

Criar schemas para:
- ProductSchema (create, update)
- TransactionSchema (extracted, confirmed)
- AlertSchema
- DashboardSchema

### 4. Módulo Products (`src/modules/products/`)

Endpoints:
- POST /products - criar produto
- GET /products - listar do usuário
- GET /products/:id - detalhe
- PUT /products/:id - atualizar
- DELETE /products/:id - remover

### 5. Módulo Transactions (`src/modules/transactions/`)

**POST /transactions/extract**
- Recebe { type: "text" | "voice", content: string | Buffer }
- Se voice: transcreve com Whisper primeiro
- Busca produtos do usuário para contexto
- Extrai com GPT-4o-mini
- Se produto não existe: retorna suggestion para criar
- Se produto ambíguo: retorna needs_clarification
- Calcula profit se for SALE
- Retorna preview (não salva ainda)

**POST /transactions/confirm**
- Recebe transação do preview
- Valida com Zod
- Se SALE: desconta estoque, verifica alerta
- Se PURCHASE: aumenta estoque, atualiza custo
- Salva no banco
- Retorna transação + alertas gerados

**GET /transactions**
- Lista transações do usuário
- Filtros: type, status, startDate, endDate, product_id
- Paginação: limit, offset

### 6. Módulo Dashboard (`src/modules/dashboard/`)

**GET /dashboard**
- Query: startDate, endDate (default: mês atual)
- Retorna:
  - total_sales_cents
  - total_costs_cents
  - total_expenses_cents
  - gross_profit_cents (vendas - custos)
  - net_profit_cents (bruto - despesas)
  - total_transactions
  - top_products (5 mais vendidos com lucro)

**GET /dashboard/stock**
- Lista produtos com estoque atual
- Destaca os que estão abaixo do mínimo
- Ordena por criticidade

### 7. Módulo Alerts (`src/modules/alerts/`)

- GET /alerts - lista não lidos
- PUT /alerts/:id/read - marca como lido
- Alerta criado automaticamente quando stock <= min_stock_alert

## Regras de Negócio Importantes

1. Valores SEMPRE em centavos (R$ 10,50 = 1050)
2. IDs gerados no backend (UUID)
3. Transação só persiste após confirm (status PENDING → CONFIRMED)
4. SALE desconta estoque e calcula profit
5. PURCHASE aumenta estoque
6. Alerta LOW_STOCK criado se stock <= min_stock_alert
7. Não duplicar alerta se já existe um não lido para o produto
8. Se produto não cadastrado na extração, retornar sugestão de criação
9. RLS ativo: usuário só vê seus próprios dados

## Dependências para instalar

npm install openai @supabase/supabase-js @fastify/multipart

## Estrutura de arquivos esperada

```
apps/api/src/
├── config/env.ts (já existe)
├── lib/
│   ├── errors.ts (já existe)
│   ├── logger.ts (já existe)
│   └── supabase.ts (criar - client do supabase)
├── providers/
│   ├── ai.types.ts (já existe)
│   ├── openai.provider.ts (criar)
│   └── index.ts (atualizar)
├── modules/
│   ├── health/ (já existe)
│   ├── products/
│   │   ├── products.schema.ts
│   │   ├── products.service.ts
│   │   └── products.routes.ts
│   ├── transactions/
│   │   ├── transactions.schema.ts
│   │   ├── transactions.service.ts
│   │   └── transactions.routes.ts
│   ├── dashboard/
│   │   ├── dashboard.schema.ts
│   │   ├── dashboard.service.ts
│   │   └── dashboard.routes.ts
│   └── alerts/
│       ├── alerts.schema.ts
│       ├── alerts.service.ts
│       └── alerts.routes.ts
└── app.ts (atualizar - registrar rotas)

supabase/migrations/
├── 20240101000001_create_products.sql
├── 20240101000002_create_transactions.sql
└── 20240101000003_create_alerts.sql
```

## Testes

Criar testes básicos para:
- Schemas (validação Zod)
- Services (lógica de negócio)
- Integração dos endpoints

Use vitest (já configurado).

## Começe pela migração do banco, depois provider OpenAI, depois módulos na ordem: products → transactions → dashboard → alerts.
```

---

## CHECKLIST DE VALIDAÇÃO

Depois que o Codex implementar, verifique:

- [ ] Migrações rodam sem erro (`npx supabase db reset`)
- [ ] `npm run typecheck` passa
- [ ] `npm run lint` passa
- [ ] `npm run test` passa
- [ ] POST /products cria produto
- [ ] GET /products lista produtos do usuário
- [ ] POST /transactions/extract retorna preview correto
- [ ] POST /transactions/confirm salva e atualiza estoque
- [ ] Alerta criado quando estoque baixo
- [ ] GET /dashboard retorna métricas corretas
- [ ] RLS impede acesso a dados de outros usuários
