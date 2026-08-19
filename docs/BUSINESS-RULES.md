# Regras de Negócio - ContAI

## Visão Geral

ContAI é um **copiloto financeiro com controle de estoque** para pequenos comerciantes (vendedor de pipoca, dono de loja, ambulante, MEI).

O usuário fala ou digita naturalmente:
- *"vendi 5 pipocas"*
- *"comprei 10kg de milho por 80 reais"*
- *"gastei 30 de gás"*

O sistema:
1. Entende o que foi dito (IA)
2. Atualiza estoque automaticamente
3. Calcula lucro em tempo real
4. Avisa quando precisa repor mercadoria

---

## Entidades do Sistema

### 1. Produto (Product)

Representa um item que o comerciante vende ou usa como insumo.

```typescript
type Product = {
  id: string;                    // UUID
  user_id: string;               // Dono do produto
  name: string;                  // "Pipoca doce", "Milho"
  type: "SELLABLE" | "SUPPLY";   // Vendável ou Insumo

  // Preços (em centavos)
  cost_price_cents: number;      // Quanto PAGA para ter/fazer
  sell_price_cents: number;      // Quanto VENDE (só se SELLABLE)

  // Estoque
  stock_quantity: number;        // Quantidade atual
  stock_unit: string;            // "unidade", "kg", "litro"
  min_stock_alert: number;       // Alerta quando <= este valor

  // Relacionamento (para produtos compostos)
  supplies_used: SupplyUsage[];  // Insumos que usa (ex: pipoca usa milho)

  created_at: string;
  updated_at: string;
};

type SupplyUsage = {
  supply_id: string;             // ID do insumo
  quantity_per_unit: number;     // Quantidade usada por unidade produzida
};
```

**Exemplos:**

| Produto | Tipo | Custo | Venda | Estoque | Alerta |
|---------|------|-------|-------|---------|--------|
| Pipoca doce | SELLABLE | R$ 3,00 | R$ 8,00 | 50 un | 10 un |
| Pipoca salgada | SELLABLE | R$ 3,50 | R$ 8,00 | 30 un | 10 un |
| Milho | SUPPLY | R$ 8,00/kg | - | 15 kg | 5 kg |
| Óleo | SUPPLY | R$ 7,00/L | - | 3 L | 2 L |
| Gás | SUPPLY | R$ 100,00 | - | 1 un | 1 un |

---

### 2. Transação (Transaction)

Registro de movimentação financeira E de estoque.

```typescript
type Transaction = {
  id: string;
  user_id: string;

  // Tipo
  type: "SALE" | "PURCHASE" | "EXPENSE" | "INCOME";

  // Valores financeiros (centavos)
  total_amount_cents: number;    // Valor total
  cost_amount_cents: number;     // Custo (para calcular lucro)
  profit_cents: number;          // Lucro (total - custo)

  // Produto relacionado (opcional)
  product_id: string | null;
  quantity: number | null;
  unit_price_cents: number | null;

  // Metadata
  description: string;
  category: string;
  source: "TEXT" | "VOICE" | "RECEIPT" | "MANUAL";
  original_input: string;        // O que o usuário disse

  // Status
  status: "PENDING" | "CONFIRMED" | "CANCELLED";
  confidence: number;            // 0-1, da IA

  // Timestamps
  occurred_at: string;           // Quando aconteceu
  created_at: string;
  updated_at: string;
};
```

**Tipos de Transação:**

| Tipo | Descrição | Afeta Estoque | Exemplo |
|------|-----------|---------------|---------|
| SALE | Venda de produto | -quantidade | "vendi 5 pipocas" |
| PURCHASE | Compra de insumo/produto | +quantidade | "comprei 10kg de milho" |
| EXPENSE | Gasto sem estoque | não | "paguei 50 de luz" |
| INCOME | Receita sem produto | não | "recebi 100 do João" |

---

### 3. Alerta (Alert)

Notificações automáticas do sistema.

```typescript
type Alert = {
  id: string;
  user_id: string;
  type: "LOW_STOCK" | "NEGATIVE_MARGIN" | "GOAL_REACHED";

  // Referência
  product_id: string | null;

  // Conteúdo
  title: string;
  message: string;

  // Status
  read: boolean;
  created_at: string;
};
```

---

## Regras de Negócio

### RN01: Venda Desconta Estoque

Quando uma SALE é confirmada:
1. Desconta `quantity` do `stock_quantity` do produto
2. Se produto usa insumos, desconta proporcionalmente
3. Calcula `profit_cents = total_amount_cents - (cost_price_cents * quantity)`

```
Exemplo: "vendi 5 pipocas a 8 reais"
- Produto: Pipoca doce (custo R$ 3,00, venda R$ 8,00)
- total_amount_cents = 5 * 800 = 4000 (R$ 40,00)
- cost_amount_cents = 5 * 300 = 1500 (R$ 15,00)
- profit_cents = 4000 - 1500 = 2500 (R$ 25,00)
- stock_quantity: 50 → 45
```

### RN02: Compra Aumenta Estoque

Quando uma PURCHASE é confirmada:
1. Aumenta `stock_quantity` do produto/insumo
2. Atualiza `cost_price_cents` se preço mudou (média ponderada ou último)

```
Exemplo: "comprei 10kg de milho por 80 reais"
- Produto: Milho (insumo)
- stock_quantity: 15 → 25 kg
- cost_price_cents: atualiza para 800 (R$ 8,00/kg)
```

### RN03: Alerta de Estoque Baixo

Após qualquer transação que afete estoque:
1. Verifica se `stock_quantity <= min_stock_alert`
2. Se sim, cria Alert tipo LOW_STOCK
3. Não duplica alerta se já existe um não lido

```
Exemplo: Estoque de pipoca foi para 8, alerta é 10
- Cria alerta: "Estoque baixo: Pipoca doce (8 unidades)"
```

### RN04: Cálculo de Margem

Para produtos SELLABLE:
```
margem_percentual = ((sell_price - cost_price) / sell_price) * 100
```

Se margem <= 0, cria Alert tipo NEGATIVE_MARGIN.

### RN05: Produto Não Cadastrado

Se IA detecta venda de produto não cadastrado:
1. Retorna transação com `product_id: null`
2. Inclui sugestão: "Produto 'X' não cadastrado. Deseja criar?"
3. App oferece opção de criar produto inline

### RN06: Preço Diferente do Cadastrado

Se usuário diz preço diferente do cadastrado:
```
"vendi pipoca por 10 reais" (cadastrado é 8)
```
1. Usa o preço informado pelo usuário
2. Inclui aviso: "Preço diferente do cadastrado (R$ 8,00)"
3. Não atualiza cadastro automaticamente

### RN07: Quantidade Maior que Estoque

Se quantidade vendida > estoque disponível:
1. Permite a venda (usuário pode ter estoque não registrado)
2. Estoque pode ficar negativo
3. Inclui aviso: "Atenção: estoque ficará negativo (-5 unidades)"

### RN08: Inferência de Produto

IA deve tentar casar o que foi dito com produtos cadastrados:
```
Cadastrado: "Pipoca doce"
Usuário diz: "vendi 3 pipoca", "3 doce", "três do doce"
→ IA deve inferir: Pipoca doce
```

Se ambíguo (ex: tem "Pipoca doce" e "Pipoca salgada"):
```
Usuário: "vendi 3 pipocas"
→ IA pergunta: "Qual tipo? Doce ou salgada?"
```

---

## Fluxos Principais

### Fluxo 1: Primeira Venda (Sem Cadastro)

```
1. Usuário: "vendi 5 pipocas a 8 reais"
2. IA extrai: { product: "pipoca", qty: 5, price: 800 }
3. API: produto não existe
4. Retorna:
   {
     transaction: { ... },
     warnings: ["Produto 'pipoca' não cadastrado"],
     suggestions: {
       create_product: {
         name: "Pipoca",
         type: "SELLABLE",
         sell_price_cents: 800,
         cost_price_cents: null  // Perguntar
       }
     }
   }
5. App mostra: "Criar produto 'Pipoca'? Qual o custo?"
6. Usuário informa custo
7. Produto criado + transação confirmada
```

### Fluxo 2: Venda Normal

```
1. Usuário: "vendi 3 pipocas"
2. IA extrai: { product: "pipoca", qty: 3 }
3. API: encontra produto, usa preço cadastrado
4. Retorna:
   {
     transaction: {
       type: "SALE",
       product_id: "xxx",
       quantity: 3,
       unit_price_cents: 800,
       total_amount_cents: 2400,
       cost_amount_cents: 900,
       profit_cents: 1500
     },
     stock_after: 47,
     confidence: 0.95
   }
5. App mostra preview com lucro calculado
6. Usuário confirma
7. Estoque atualizado, transação salva
```

### Fluxo 3: Compra de Insumo

```
1. Usuário: "comprei 10kg de milho por 80 reais"
2. IA extrai: { product: "milho", qty: 10, unit: "kg", total: 8000 }
3. API: encontra insumo
4. Retorna:
   {
     transaction: {
       type: "PURCHASE",
       product_id: "yyy",
       quantity: 10,
       unit_price_cents: 800,  // 8000/10
       total_amount_cents: 8000
     },
     stock_after: 25,
     confidence: 0.92
   }
5. Usuário confirma
6. Estoque aumenta, custo atualizado
```

### Fluxo 4: Alerta de Reposição

```
1. Após venda, estoque de pipoca = 8
2. min_stock_alert = 10
3. Sistema cria alerta:
   {
     type: "LOW_STOCK",
     product_id: "xxx",
     title: "Estoque baixo",
     message: "Pipoca doce: apenas 8 unidades. Reponha!"
   }
4. App mostra notificação/badge
5. Usuário pode:
   - Marcar como lido
   - Ir para tela de compras
   - Ignorar
```

---

## Dashboard

### Métricas Principais

```typescript
type DashboardData = {
  period: { start: string; end: string };

  // Financeiro
  total_sales_cents: number;      // Total vendido
  total_costs_cents: number;      // Total de custos
  total_expenses_cents: number;   // Despesas gerais
  gross_profit_cents: number;     // Lucro bruto (vendas - custos)
  net_profit_cents: number;       // Lucro líquido (bruto - despesas)

  // Operacional
  total_transactions: number;
  products_sold: number;          // Quantidade de itens vendidos

  // Estoque
  low_stock_products: Product[];  // Produtos abaixo do mínimo
  stock_value_cents: number;      // Valor total em estoque

  // Top produtos
  top_products: {
    product_id: string;
    name: string;
    quantity_sold: number;
    revenue_cents: number;
    profit_cents: number;
  }[];
};
```

### Cálculos

```
Lucro Bruto = Σ(vendas) - Σ(custo das vendas)
Lucro Líquido = Lucro Bruto - Σ(despesas gerais)
Margem Bruta = (Lucro Bruto / Vendas) * 100
Valor em Estoque = Σ(quantidade * custo_unitário) para cada produto
```

---

## Migrações de Banco

### Tabela: products

```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),

  name VARCHAR(200) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('SELLABLE', 'SUPPLY')),

  cost_price_cents INTEGER NOT NULL DEFAULT 0,
  sell_price_cents INTEGER DEFAULT NULL,

  stock_quantity DECIMAL(10,3) NOT NULL DEFAULT 0,
  stock_unit VARCHAR(50) NOT NULL DEFAULT 'unidade',
  min_stock_alert DECIMAL(10,3) NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user_id, name)
);

-- RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own products" ON products
  FOR ALL USING (auth.uid() = user_id);
```

### Tabela: transactions

```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),

  type VARCHAR(20) NOT NULL CHECK (type IN ('SALE', 'PURCHASE', 'EXPENSE', 'INCOME')),

  total_amount_cents INTEGER NOT NULL,
  cost_amount_cents INTEGER NOT NULL DEFAULT 0,
  profit_cents INTEGER NOT NULL DEFAULT 0,

  product_id UUID REFERENCES products(id),
  quantity DECIMAL(10,3),
  unit_price_cents INTEGER,

  description VARCHAR(500) NOT NULL,
  category VARCHAR(100),
  source VARCHAR(20) NOT NULL CHECK (source IN ('TEXT', 'VOICE', 'RECEIPT', 'MANUAL')),
  original_input TEXT,

  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED')),
  confidence DECIMAL(3,2),

  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own transactions" ON transactions
  FOR ALL USING (auth.uid() = user_id);

-- Índices
CREATE INDEX idx_transactions_user_date ON transactions(user_id, occurred_at DESC);
CREATE INDEX idx_transactions_product ON transactions(product_id);
```

### Tabela: alerts

```sql
CREATE TABLE alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),

  type VARCHAR(30) NOT NULL CHECK (type IN ('LOW_STOCK', 'NEGATIVE_MARGIN', 'GOAL_REACHED')),
  product_id UUID REFERENCES products(id),

  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,

  read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own alerts" ON alerts
  FOR ALL USING (auth.uid() = user_id);
```

---

## API Endpoints Atualizados

### Produtos

```
POST   /products              # Criar produto
GET    /products              # Listar produtos
GET    /products/:id          # Detalhe do produto
PUT    /products/:id          # Atualizar produto
DELETE /products/:id          # Remover produto
```

### Transações

```
POST   /transactions/extract  # Extrair de texto/áudio
POST   /transactions/confirm  # Confirmar e salvar
GET    /transactions          # Listar transações
GET    /transactions/:id      # Detalhe
```

### Dashboard

```
GET    /dashboard             # Métricas do período
GET    /dashboard/stock       # Status do estoque
```

### Alertas

```
GET    /alerts                # Listar alertas
PUT    /alerts/:id/read       # Marcar como lido
DELETE /alerts/:id            # Descartar alerta
```

---

## Exemplos de Input → Output

### Exemplo 1: Venda simples
```
Input: "vendi 5 pipocas"
Output: {
  type: "SALE",
  product: { id: "xxx", name: "Pipoca doce" },
  quantity: 5,
  unit_price_cents: 800,
  total_amount_cents: 4000,
  profit_cents: 2500,
  stock_after: 45
}
```

### Exemplo 2: Compra de insumo
```
Input: "comprei 2 sacos de milho por 160 reais"
Output: {
  type: "PURCHASE",
  product: { id: "yyy", name: "Milho" },
  quantity: 2,
  unit: "saco",
  unit_price_cents: 8000,
  total_amount_cents: 16000,
  stock_after: 17
}
```

### Exemplo 3: Despesa geral
```
Input: "paguei 150 de luz"
Output: {
  type: "EXPENSE",
  product: null,
  total_amount_cents: 15000,
  category: "utilidades",
  description: "Conta de luz"
}
```

### Exemplo 4: Produto ambíguo
```
Input: "vendi 3 pipocas"
Produtos: ["Pipoca doce", "Pipoca salgada"]
Output: {
  needs_clarification: true,
  question: "Qual tipo de pipoca?",
  options: ["Pipoca doce", "Pipoca salgada", "Ambas"]
}
```

### Exemplo 5: Estoque baixo após venda
```
Input: "vendi 40 pipocas" (estoque: 45, alerta: 10)
Output: {
  type: "SALE",
  ...
  stock_after: 5,
  alerts: [{
    type: "LOW_STOCK",
    message: "Estoque baixo: Pipoca doce (5 unidades)"
  }]
}
```
