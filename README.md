<div align="center">

# 🧾 Conta+

**Venda por voz, estoque e lucro para pequenos negócios.**

*“Vendi duas camisetas por cinquenta reais cada”* → venda estruturada, estoque atualizado e lucro calculado.

![Status](https://img.shields.io/badge/status-MVP%20funcional-16a34a?style=flat-square)
![Backend](https://img.shields.io/badge/backend-Fastify%20%2B%20TypeScript-000000?style=flat-square&logo=fastify)
![App](https://img.shields.io/badge/app-Flutter-02569B?style=flat-square&logo=flutter)

</div>

## O problema

Ambulantes, MEIs e pequenos lojistas frequentemente controlam vendas e estoque de cabeça, no caderno ou em ferramentas desconectadas. No fim do dia, sabem quanto entrou, mas nem sempre quanto realmente lucraram ou o que precisam repor.

## A solução

O **Conta+** permite registrar uma venda apenas falando ou digitando naturalmente:

1. Transcreve a fala no navegador em português brasileiro.
2. Interpreta produto, quantidade e preço.
3. Exibe uma prévia antes de alterar qualquer dado.
4. Calcula faturamento, custo, lucro e margem com regras determinísticas.
5. Após a confirmação, registra a venda e atualiza o estoque atomicamente.

O resumo financeiro é consequência da operação por voz — não a funcionalidade principal do produto.

## Fluxo principal

```text
Fala do vendedor
       ↓
Reconhecimento de voz do navegador
       ↓
Texto enviado para POST /v1/sales/preview
       ↓
Produto + quantidade + preço + lucro + margem
       ↓
Prévia para conferência humana
       ↓
POST /v1/sales/confirm com source = VOICE
       ↓
Venda registrada + estoque atualizado
```

O arquivo de áudio não é armazenado pelo Conta+. O navegador realiza o reconhecimento e envia somente o texto transcrito para a API.

## Decisões de engenharia

- Dinheiro armazenado em centavos inteiros.
- A prévia nunca altera o banco.
- Custo do produto congelado no momento da venda.
- Confirmação atômica e idempotente.
- Cálculos financeiros determinísticos.
- Conferência humana antes de alterar estoque ou valores.
- Origem `VOICE`, `TEXT` ou `MANUAL` registrada em cada venda.

## Stack

| Camada | Tecnologia |
|---|---|
| Aplicativo | Flutter Web |
| Voz | Web Speech API (`SpeechRecognition`) |
| API | Fastify 5 + TypeScript |
| Validação | Zod |
| Banco do MVP | SQLite via `node:sqlite` |
| Landing page | HTML, CSS e JavaScript puro |

## Estrutura

```text
contaai/
├── app/          # Aplicativo Flutter responsivo
├── backend/      # API, banco e regras financeiras
├── homepage/     # Landing page institucional
└── docs/         # Regras, modelagem e especificações
```

## Executando o projeto

Requisito do backend: Node.js 22.5 ou superior.

### Backend

```bash
cd backend
npm install
npm run dev
```

A API será iniciada em `http://localhost:3333` e criará automaticamente a loja e os produtos de demonstração.

### Aplicativo Flutter

Em outro terminal:

```bash
cd app
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:3333
```

Para usar o microfone, abra pelo Chrome em `localhost` e permita o acesso quando solicitado.

## Rotas principais

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/health` | Verifica a disponibilidade da API |
| `GET` | `/v1/products` | Lista produtos e estoque |
| `POST` | `/v1/products` | Cadastra um produto |
| `POST` | `/v1/products/:productId/stock-adjustments` | Ajusta o estoque |
| `POST` | `/v1/sales/preview` | Interpreta texto e calcula a prévia |
| `POST` | `/v1/sales/confirm` | Confirma a venda e atualiza o estoque |
| `GET` | `/v1/transactions` | Lista o histórico de vendas |
| `GET` | `/v1/dashboard/summary` | Retorna o resumo financeiro e de estoque |

## Demonstração

> “Vendi duas camisetas por cinquenta reais cada.”

Resultado esperado:

- Faturamento: R$ 100,00
- Custo: R$ 60,00
- Lucro bruto: R$ 40,00
- Margem: 40%
- Estoque reduzido em duas unidades após a confirmação

## Modelo de negócio

O Conta+ adota um modelo freemium: Gratuito (R$ 0), Solo (R$ 14,90/mês) e Pro (R$ 34,90/mês).

Mais detalhes estão em [`docs/BUSINESS-MODEL.md`](docs/BUSINESS-MODEL.md).

---

<div align="center">
<sub>Menos tempo fazendo conta. Mais tempo vendendo.</sub>
</div>
