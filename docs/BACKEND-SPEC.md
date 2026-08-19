# Especificação do Backend — ContAI

## 1. Objetivo

O ContAI é um aplicativo mobile para lojistas, vendedores autônomos e pequenos comerciantes controlarem vendas, lucro e estoque por texto, áudio ou lançamento manual.

O fluxo principal deve ser simples:

1. O usuário digita ou fala: “vendi 3 camisetas por 50 reais cada”.
2. O backend transcreve o áudio, quando necessário, e interpreta a movimentação.
3. O backend devolve uma prévia calculada, sem alterar banco ou estoque.
4. O app permite revisar e corrigir os dados.
5. O usuário confirma.
6. O backend registra a venda, congela o custo histórico, calcula lucro e margem e desconta o estoque em uma única transação de banco.

Esta especificação é o contrato entre o backend e o aplicativo Flutter. Alterações de nomes, tipos, enums ou formatos devem ser combinadas entre as duas equipes.

---

## 2. Escopo da primeira versão

### Incluído

- Cadastro e autenticação do lojista.
- Uma loja por usuário na primeira versão.
- Cadastro, edição, arquivamento e consulta de produtos.
- Controle de estoque por quantidade.
- Registro de vendas, compras de estoque, despesas e receitas.
- Entrada por texto, áudio e formulário manual.
- Prévia editável antes da confirmação.
- Cálculo de faturamento, custo, lucro e margem.
- Movimentação e histórico de estoque.
- Alertas de estoque baixo.
- Dashboard por período.
- Histórico e detalhe das transações.
- Cancelamento com estorno de estoque.

### Fora do escopo inicial

- Produtos compostos e receitas de insumos.
- Conversão automática entre unidades, como saco para kg.
- OCR de comprovantes.
- Metas e alertas de meta atingida.
- Várias lojas por usuário.
- Contas de funcionários e permissões.
- Contas a pagar ou receber parceladas.
- Integração fiscal, emissão de nota ou meios de pagamento.

Esses itens podem ser adicionados depois sem alterar o fluxo central.

---

## 3. Decisões de negócio

### 3.1 Dinheiro

- Todo valor monetário trafega e é armazenado como inteiro em centavos.
- `R$ 10,50` é representado por `1050`.
- A moeda da primeira versão é `BRL`.
- O backend é a fonte oficial de todos os cálculos.

### 3.2 Quantidade e unidades

- Quantidades aceitam até três casas decimais.
- Unidades permitidas inicialmente: `UNIT`, `KG`, `G`, `L`, `ML`, `M`, `BOX`, `PACKAGE` e `OTHER`.
- Cada produto possui uma única unidade de estoque.
- A entrada deve usar a mesma unidade cadastrada. Caso contrário, o preview deve pedir correção; não haverá conversão automática na primeira versão.

### 3.3 Custo do produto

- Compras de estoque atualizam o custo pelo custo médio ponderado.
- Fórmula:

```text
novo_custo = ((estoque_anterior × custo_anterior) + valor_da_compra) ÷ (estoque_anterior + quantidade_comprada)
```

- Quando o estoque anterior for menor ou igual a zero, o novo custo unitário será o custo unitário da compra.
- O resultado deve ser arredondado para o centavo mais próximo.

### 3.4 Venda, lucro e margem

Ao confirmar uma venda:

```text
faturamento = quantidade × preço_unitário_vendido
custo = quantidade × custo_unitário_atual
lucro_bruto = faturamento - custo
margem_percentual = lucro_bruto ÷ faturamento × 100
```

- O preço de venda pode ser diferente do preço cadastrado.
- O backend deve avisar sobre a diferença, mas usar o preço informado.
- O custo unitário usado deve ser salvo na venda. Alterações futuras no produto não podem mudar o lucro histórico.
- Se o faturamento for zero, a margem será `null`.
- A margem é retornada como número decimal, por exemplo `37.50`.

### 3.5 Estoque

- Venda confirmada reduz o estoque.
- Compra confirmada aumenta o estoque.
- Ajuste manual cria uma movimentação de estoque auditável.
- A primeira versão permite estoque negativo, mas retorna aviso antes da confirmação.
- Toda alteração de estoque precisa gerar um registro em `stock_movements`.
- Cadastro, edição ou exclusão de produto nunca deve reescrever o histórico.

### 3.6 Confirmação e segurança do preview

- Interpretar texto ou áudio não grava transação e não altera estoque.
- A API gera um `preview_id` temporário com expiração de 15 minutos.
- O Flutter pode enviar correções ao preview.
- Na confirmação, o backend busca novamente produto, preço, custo e estoque e recalcula todos os valores.
- A confirmação exige `Idempotency-Key`; repetir a mesma requisição deve retornar a operação já criada.
- Confirmação, transação, itens, estoque, movimentações e alertas devem ser persistidos atomicamente.

### 3.7 Cancelamento

- Transações confirmadas não são apagadas.
- O cancelamento exige um motivo.
- Venda cancelada devolve a quantidade ao estoque.
- Compra cancelada remove do estoque a quantidade comprada.
- Despesa ou receita cancelada não altera estoque.
- O cancelamento gera movimentos inversos e mantém auditoria.
- Uma transação não pode ser cancelada duas vezes.

### 3.8 Exclusão de produto

- Produto com histórico é arquivado usando `active = false`.
- Produto arquivado não aparece nas buscas de lançamento, mas continua no histórico.
- Nomes são únicos por loja entre produtos ativos, ignorando maiúsculas, minúsculas e espaços laterais.

---

## 4. Entidades

### 4.1 Store

```typescript
type Store = {
  id: string;
  owner_user_id: string;
  name: string;
  currency: "BRL";
  timezone: "America/Sao_Paulo";
  created_at: string;
  updated_at: string;
};
```

### 4.2 Product

```typescript
type StockUnit =
  | "UNIT" | "KG" | "G" | "L" | "ML"
  | "M" | "BOX" | "PACKAGE" | "OTHER";

type Product = {
  id: string;
  store_id: string;
  name: string;
  sku: string | null;
  description: string | null;
  cost_price_cents: number;
  default_sale_price_cents: number;
  stock_quantity: string; // decimal serializado como string: "10.500"
  stock_unit: StockUnit;
  custom_stock_unit: string | null;
  min_stock_quantity: string;
  active: boolean;
  created_at: string;
  updated_at: string;
};
```

`custom_stock_unit` é obrigatório apenas quando `stock_unit = OTHER`.

### 4.3 Transaction

Uma transação pode ter vários itens. Isso permite frases como “vendi duas camisetas e um boné”.

```typescript
type TransactionType = "SALE" | "PURCHASE" | "EXPENSE" | "INCOME";
type TransactionStatus = "CONFIRMED" | "CANCELLED";
type InputSource = "TEXT" | "VOICE" | "MANUAL";

type Transaction = {
  id: string;
  store_id: string;
  type: TransactionType;
  status: TransactionStatus;
  source: InputSource;
  description: string;
  category: string | null;
  total_amount_cents: number;
  total_cost_cents: number;
  gross_profit_cents: number;
  margin_percent: number | null;
  original_input: string | null;
  occurred_at: string;
  confirmed_at: string;
  cancelled_at: string | null;
  cancellation_reason: string | null;
  created_at: string;
  updated_at: string;
  items: TransactionItem[];
};

type TransactionItem = {
  id: string;
  transaction_id: string;
  product_id: string;
  product_name_snapshot: string;
  stock_unit_snapshot: StockUnit;
  quantity: string;
  unit_price_cents: number;
  unit_cost_cents: number;
  total_amount_cents: number;
  total_cost_cents: number;
  gross_profit_cents: number;
  margin_percent: number | null;
};
```

`EXPENSE` e `INCOME` não possuem itens de produto na primeira versão.

### 4.4 StockMovement

```typescript
type StockMovementType =
  | "INITIAL" | "SALE" | "PURCHASE"
  | "ADJUSTMENT" | "REVERSAL";

type StockMovement = {
  id: string;
  store_id: string;
  product_id: string;
  transaction_id: string | null;
  type: StockMovementType;
  quantity_delta: string;
  quantity_before: string;
  quantity_after: string;
  reason: string | null;
  occurred_at: string;
  created_at: string;
};
```

### 4.5 Alert

```typescript
type Alert = {
  id: string;
  store_id: string;
  type: "LOW_STOCK" | "NEGATIVE_STOCK" | "NEGATIVE_MARGIN";
  product_id: string | null;
  title: string;
  message: string;
  read_at: string | null;
  resolved_at: string | null;
  created_at: string;
};
```

- Só pode existir um alerta ativo do mesmo tipo para o mesmo produto.
- Se o estoque voltar a ficar acima do mínimo, o alerta `LOW_STOCK` é resolvido automaticamente.
- Se cair novamente, um novo alerta pode ser criado.

---

## 5. Convenções da API

- Base URL: `/v1`.
- Autenticação: `Authorization: Bearer <access_token>`.
- JSON usa `snake_case`.
- Datas usam ISO 8601 UTC, por exemplo `2026-08-19T14:30:00.000Z`.
- Períodos enviados apenas como data são interpretados no timezone da loja.
- Quantidades decimais são strings para evitar perda de precisão no Dart e no JavaScript.
- Campos monetários são inteiros.
- Paginação por cursor.
- `limit` padrão 20, máximo 100.
- Resposta de sucesso contém `data`.

```json
{
  "data": {},
  "meta": {
    "request_id": "req_123"
  }
}
```

### Erros

```json
{
  "error": {
    "code": "INSUFFICIENT_OR_NEGATIVE_STOCK",
    "message": "A venda deixará o estoque negativo.",
    "fields": {
      "items.0.quantity": "Disponível: 2.000"
    },
    "details": {},
    "request_id": "req_123"
  }
}
```

Códigos HTTP principais:

- `200`: consulta ou alteração concluída.
- `201`: recurso criado.
- `400`: JSON ou parâmetros inválidos.
- `401`: token ausente ou inválido.
- `403`: recurso pertence a outra loja.
- `404`: recurso não encontrado.
- `409`: conflito, duplicidade ou estado inválido.
- `422`: regra de negócio ou campos do preview incompletos.
- `429`: limite de requisições.
- `500`: erro interno.

---

## 6. Autenticação e loja

O provedor pode ser Supabase Auth, mas a API deve validar o token e derivar o usuário no servidor. `user_id` e `store_id` nunca são aceitos livremente no corpo das requisições.

### `POST /v1/stores`

Cria a loja do usuário autenticado.

```json
{
  "name": "Loja do Eduardo",
  "timezone": "America/Sao_Paulo"
}
```

### `GET /v1/me`

Retorna usuário e loja necessários para inicializar o app.

---

## 7. Produtos e estoque

### `POST /v1/products`

```json
{
  "name": "Camiseta básica",
  "sku": "CAM-BAS",
  "description": null,
  "cost_price_cents": 3000,
  "default_sale_price_cents": 5000,
  "initial_stock_quantity": "20.000",
  "stock_unit": "UNIT",
  "custom_stock_unit": null,
  "min_stock_quantity": "5.000"
}
```

Criar estoque inicial gera movimento `INITIAL`.

### `GET /v1/products`

Filtros:

- `search`
- `active=true|false`
- `low_stock=true|false`
- `cursor`
- `limit`

### `GET /v1/products/{product_id}`

Retorna o produto.

### `PATCH /v1/products/{product_id}`

Permite atualizar metadados e preços. Não permite editar estoque diretamente.

### `DELETE /v1/products/{product_id}`

Arquiva o produto, definindo `active = false`.

### `POST /v1/products/{product_id}/stock-adjustments`

```json
{
  "operation": "SET",
  "quantity": "12.000",
  "reason": "Contagem física",
  "occurred_at": "2026-08-19T14:30:00.000Z"
}
```

`operation` pode ser `SET`, `ADD` ou `REMOVE`. Retorna produto atualizado e movimento.

### `GET /v1/products/{product_id}/stock-movements`

Filtros: `start_date`, `end_date`, `cursor`, `limit`.

---

## 8. Interpretação de texto e áudio

### `POST /v1/transaction-previews/text`

```json
{
  "text": "vendi 3 camisetas por 50 reais cada",
  "occurred_at": "2026-08-19T14:30:00.000Z"
}
```

### `POST /v1/transaction-previews/audio`

Recebe `multipart/form-data`:

- `audio`: arquivo obrigatório.
- `occurred_at`: ISO 8601 opcional.

Formatos aceitos: `m4a`, `mp3`, `wav`, `webm` e `ogg`. Limite inicial: 10 MB e 2 minutos.

### Resposta de preview

```json
{
  "data": {
    "preview_id": "prv_123",
    "expires_at": "2026-08-19T14:45:00.000Z",
    "transcription": "vendi 3 camisetas por 50 reais cada",
    "confidence": 0.96,
    "needs_review": false,
    "transaction": {
      "type": "SALE",
      "description": "Venda de camisetas",
      "category": null,
      "occurred_at": "2026-08-19T14:30:00.000Z",
      "total_amount_cents": 15000,
      "total_cost_cents": 9000,
      "gross_profit_cents": 6000,
      "margin_percent": 40.0,
      "items": [
        {
          "product_id": "prod_123",
          "product_name": "Camiseta básica",
          "quantity": "3.000",
          "stock_unit": "UNIT",
          "unit_price_cents": 5000,
          "unit_cost_cents": 3000,
          "stock_before": "20.000",
          "stock_after": "17.000"
        }
      ]
    },
    "warnings": [],
    "clarifications": [],
    "suggested_products": []
  }
}
```

### Situações que exigem revisão

`needs_review = true` quando:

- Confiança geral menor que `0.80`.
- Produto não foi encontrado.
- Há mais de um produto possível.
- Quantidade ou valor está ausente.
- Unidade é incompatível.
- Estoque ficará negativo.
- Preço informado diverge do cadastro.
- Margem será negativa.

Uma ambiguidade retorna opções estruturadas:

```json
{
  "field": "items.0.product_id",
  "code": "AMBIGUOUS_PRODUCT",
  "question": "Qual camiseta foi vendida?",
  "options": [
    { "value": "prod_1", "label": "Camiseta básica" },
    { "value": "prod_2", "label": "Camiseta premium" }
  ]
}
```

Produto inexistente retorna uma sugestão de cadastro, mas nunca cria o produto automaticamente.

### `PATCH /v1/transaction-previews/{preview_id}`

O Flutter envia os campos corrigidos. O backend valida e recalcula toda a prévia.

```json
{
  "type": "SALE",
  "description": "Venda de camisetas",
  "occurred_at": "2026-08-19T14:30:00.000Z",
  "items": [
    {
      "product_id": "prod_123",
      "quantity": "3.000",
      "unit_price_cents": 5000
    }
  ]
}
```

Para `EXPENSE` ou `INCOME`:

```json
{
  "type": "EXPENSE",
  "description": "Conta de luz",
  "category": "UTILITIES",
  "total_amount_cents": 15000,
  "occurred_at": "2026-08-19T14:30:00.000Z"
}
```

---

## 9. Confirmação e histórico

### `POST /v1/transactions`

Header obrigatório:

```text
Idempotency-Key: UUID gerado pelo Flutter
```

Body:

```json
{
  "preview_id": "prv_123"
}
```

Se o preço, custo ou estoque mudou depois da prévia, retornar `409 PREVIEW_STALE` com uma prévia recalculada. O app deve mostrá-la novamente antes de confirmar.

Resposta `201`: transação confirmada, estoque atualizado, movimentos e alertas gerados.

### `POST /v1/transactions/manual-preview`

Cria uma prévia a partir de formulário manual usando o mesmo formato do `PATCH` de preview. Mesmo lançamentos manuais passam por preview e confirmação.

### `GET /v1/transactions`

Filtros:

- `type`
- `status`
- `product_id`
- `start_date`
- `end_date`
- `search`
- `cursor`
- `limit`

Ordenação padrão: `occurred_at DESC, id DESC`.

### `GET /v1/transactions/{transaction_id}`

Retorna transação, itens e impactos no estoque.

### `POST /v1/transactions/{transaction_id}/cancel`

```json
{
  "reason": "Venda lançada em duplicidade"
}
```

---

## 10. Dashboard

### `GET /v1/dashboard/summary`

Query obrigatória: `start_date` e `end_date` no formato `YYYY-MM-DD`. O padrão no app será o dia atual, mas a API também aceita períodos maiores.

```json
{
  "data": {
    "period": {
      "start_date": "2026-08-01",
      "end_date": "2026-08-31",
      "timezone": "America/Sao_Paulo"
    },
    "sales_revenue_cents": 100000,
    "sales_cost_cents": 60000,
    "sales_gross_profit_cents": 40000,
    "sales_margin_percent": 40.0,
    "expenses_cents": 10000,
    "other_income_cents": 5000,
    "net_result_cents": 35000,
    "sales_count": 25,
    "items_sold_quantity": "42.000",
    "low_stock_count": 3,
    "stock_value_cents": 120000,
    "top_products": [
      {
        "product_id": "prod_123",
        "name": "Camiseta básica",
        "quantity_sold": "15.000",
        "revenue_cents": 75000,
        "gross_profit_cents": 30000
      }
    ]
  }
}
```

```text
resultado_líquido = lucro_bruto_das_vendas + outras_receitas - despesas
valor_do_estoque = soma(estoque_atual × custo_médio_atual)
```

Transações canceladas não entram nos indicadores.

### `GET /v1/dashboard/stock`

Retorna produtos ativos ordenados por criticidade:

1. Estoque negativo.
2. Estoque igual ou abaixo do mínimo.
3. Menor proporção `estoque / mínimo`.
4. Nome.

---

## 11. Alertas

### `GET /v1/alerts`

Filtros: `status=unread|read|all`, `type`, `cursor`, `limit`.

### `PATCH /v1/alerts/{alert_id}/read`

Marca como lido.

### `PATCH /v1/alerts/{alert_id}/unread`

Marca como não lido.

### `DELETE /v1/alerts/{alert_id}`

Resolve o alerta sem apagar o registro.

---

## 12. Banco de dados sugerido

PostgreSQL/Supabase com as tabelas:

- `stores`
- `store_members`
- `products`
- `transactions`
- `transaction_items`
- `stock_movements`
- `alerts`
- `transaction_previews`
- `idempotency_keys`

Requisitos:

- UUID como chave primária.
- Foreign keys e checks para valores não negativos onde aplicável.
- `stock_quantity` pode ser negativo; quantidades de itens devem ser maiores que zero.
- RLS por associação em `store_members`.
- Índices por `store_id`, datas, status, produto e alertas ativos.
- Unique parcial para nomes de produtos ativos por loja.
- Unique parcial para um alerta ativo por tipo e produto.
- Trigger padronizado de `updated_at` ou atualização explícita pela aplicação.
- Operações de confirmação e cancelamento dentro de transação SQL.
- Lock da linha do produto durante movimentação (`SELECT ... FOR UPDATE`) para evitar estoque incorreto em vendas simultâneas.

O backend usa credencial de servidor para operações internas, mas ainda precisa validar acesso à loja em toda requisição. Nunca expor service role key ao Flutter.

---

## 13. Requisitos da interpretação por IA

- Entender português brasileiro informal e números por extenso.
- Receber como contexto somente produtos ativos da loja.
- Extrair tipo, produto, quantidade, preço, total, descrição, categoria e data quando mencionada.
- Aceitar mais de um item na mesma venda ou compra.
- Nunca inventar produto, quantidade ou valor ausente.
- Devolver JSON estruturado validado por schema.
- O modelo sugere; as regras determinísticas do backend calculam dinheiro, custo, lucro, margem e estoque.
- Matching final de produto e autorização permanecem no backend.
- Áudio deve ser armazenado apenas temporariamente e apagado após transcrição, salvo consentimento futuro explícito.

---

## 14. Requisitos não funcionais

- OpenAPI 3.1 versionado e entregue ao front.
- Ambiente de homologação com dados de teste.
- Rate limit específico para texto e áudio.
- Logs estruturados com `request_id`, sem conteúdo sensível do áudio ou token.
- Auditoria de confirmações, cancelamentos e ajustes.
- Testes unitários dos cálculos.
- Testes de integração dos endpoints.
- Testes de concorrência na baixa de estoque.
- Testes de RLS entre duas lojas.
- Healthcheck e monitoramento de falhas da IA.
- O lançamento manual deve continuar funcionando se a IA estiver indisponível.

Meta inicial de desempenho, sem contar transcrição/IA:

- Consultas comuns: p95 abaixo de 500 ms.
- Confirmação de transação: p95 abaixo de 1 s.

---

## 15. Critérios de aceite

O backend da primeira versão estará pronto quando:

- Um usuário só acessar dados da própria loja.
- Produto puder ser criado com estoque inicial auditável.
- Texto e áudio gerarem previews no mesmo formato.
- Preview não modificar banco nem estoque.
- Correções no preview forem recalculadas pelo backend.
- Venda confirmada criar transação, itens e movimentos e reduzir estoque atomicamente.
- Compra confirmada aumentar estoque e atualizar custo médio.
- Lucro histórico permanecer inalterado após mudança de custo do produto.
- Repetição da confirmação com a mesma chave não duplicar a venda.
- Venda simultânea não causar perda de atualização de estoque.
- Cancelamento gerar estorno auditável.
- Estoque baixo gerar apenas um alerta ativo por produto.
- Dashboard excluir cancelamentos e respeitar timezone e período.
- Contrato OpenAPI corresponder aos exemplos desta especificação.

---

## 16. Ordem recomendada de implementação

1. Autenticação, lojas, RLS e estrutura do banco.
2. Produtos, ajustes e histórico de estoque.
3. Preview e confirmação manual.
4. Cálculos, idempotência, concorrência e cancelamento.
5. Interpretação por texto.
6. Upload e transcrição de áudio.
7. Dashboard e alertas.
8. OpenAPI, testes completos e ambiente de homologação.

O front Flutter pode começar após as etapas 1 a 3, usando o OpenAPI e respostas mockadas com os mesmos contratos.
