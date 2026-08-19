# Prompt para Claude — Landing Page ContAI

Copie o conteúdo abaixo e envie ao Claude.

---

Crie a landing page institucional do ContAI dentro de um novo diretório `landing/`.

## Restrições obrigatórias

- Use somente HTML5, CSS3 e JavaScript puro.
- Não use React, Vue, Angular, Svelte, Tailwind, Bootstrap, jQuery ou qualquer framework/biblioteca.
- Não use npm, bundler ou etapa de build.
- A página deve funcionar abrindo `landing/index.html` diretamente.
- Não altere `backend/`, `app/` ou `docs/`.
- Não faça commit nem push.
- Não implemente checkout, login ou integração real com o backend.
- Não invente depoimentos, clientes, métricas, CNPJ, endereço ou recursos disponíveis.

## Produto

O ContAI é um copiloto financeiro com estoque para ambulantes, feirantes, pipoqueiros, MEIs e pequenos lojistas. O comerciante fala ou digita frases como “Vendi duas camisetas por cinquenta reais cada”. O sistema apresenta uma prévia e, após confirmação, registra a venda, atualiza estoque e calcula faturamento, custo, lucro e margem.

## Arquivos

```text
landing/
├── index.html
├── styles.css
├── script.js
└── README.md
```

## Visual

- Azul principal `#2563EB`.
- Azul secundário `#60A5FA`.
- Azul claro `#EFF6FF`.
- Fundo `#F8FAFC`.
- Cards brancos.
- Texto principal `#0F172A` e secundário `#64748B`.
- Lucro `#16A34A`, alerta `#F59E0B` e prejuízo `#DC2626`.
- Visual clean, espaço em branco, bordas discretas, sombras leves e cantos arredondados.
- Mobile-first e responsivo.
- Mockups feitos com HTML/CSS, sem imagens aleatórias.
- Ícones apenas como SVG inline acessível.
- Animações discretas, respeitando `prefers-reduced-motion`.

## Seções

### Header

Marca `ContAI`, destacando `AI`; links Como funciona, Benefícios e Planos; botão “Conhecer o ContAI”; header fixo e menu mobile acessível.

### Hero

Título: **Fale o que vendeu. O ContAI cuida das contas.**

Texto: **Registre vendas por texto ou voz, acompanhe seu estoque e descubra quanto realmente sobrou no fim do dia.**

Botões “Ver como funciona” e “Conhecer os recursos”.

Mockup mobile exibindo faturamento R$ 1.250, lucro R$ 480, margem 38,4%, dois produtos com estoque baixo e a frase “Vendi duas camisetas por cinquenta reais cada”.

### Problema

Título: **Seu negócio não pode depender da memória.**

Mostrar vendas no caderno, estoque descoberto quando acaba e faturamento confundido com lucro.

### Como funciona

1. Fale ou digite.
2. Confira produto, quantidade, valor, custo e lucro.
3. Confirme para registrar e atualizar o estoque.

### Demonstração financeira

Card com Camiseta básica, quantidade 2, preço R$ 50, faturamento R$ 100, custo R$ 60, lucro R$ 40, margem 40% e estoque 10 → 8. Deixe claro que faturamento não é lucro.

### Benefícios

- Registro por voz e texto.
- Estoque atualizado automaticamente.
- Lucro e margem em tempo real.
- Alertas para reposição.

### Público

Título: **Feito para quem faz o negócio acontecer.**

Apresente ambulantes, feirantes, pipoqueiros, MEIs e pequenos lojistas sem fotografias estereotipadas.

### Planos

Apresente exatamente:

**Gratuito — R$ 0**
- Até 20 produtos.
- Lançamentos manuais ilimitados.
- 30 interpretações de texto/mês.
- 10 minutos de áudio/mês.
- Dashboard de sete dias.

**Solo — R$ 14,90/mês**
- Até 100 produtos.
- 300 lançamentos por IA/mês.
- 60 minutos de áudio/mês.
- Estoque e alertas.
- Histórico de 90 dias.
- Lucro e margem em tempo real.
- Selo “Ideal para quem vende por conta própria”.
- Texto “aproximadamente R$ 0,50 por dia”.

**Pro — R$ 34,90/mês**
- Produtos ilimitados.
- 2.000 lançamentos por IA/mês.
- 300 minutos de áudio/mês.
- Histórico e relatórios completos.
- Alertas, categorias, filtros e exportação.

Destaque visualmente o Solo. Exiba: “Valores e limites sujeitos à validação durante o período piloto.” Não mostre o plano futuro de R$ 69,90 e não implemente checkout.

### Retorno

Mostrar como exemplo, não promessa: **Para um vendedor com lucro de R$ 3 por unidade, o Solo equivale ao lucro de aproximadamente cinco vendas no mês.**

Mensagem: **Se o ContAI evitar uma perda de estoque ou ajudar a corrigir o preço de um produto, a mensalidade pode se pagar no próprio dia.**

### CTA

Título: **Menos tempo fazendo conta. Mais tempo vendendo.**

Texto: **Use grátis. Assine somente quando o ContAI já estiver ajudando seu negócio.**

Botão “Começar agora”. Defina uma constante `APP_URL` no início de `script.js`; se preenchida, navegue para ela, senão role até a demonstração.

### Footer

ContAI; “Copiloto financeiro para pequenos negócios”; links internos Produto, Privacidade e Contato; ano atual via JavaScript.

## JavaScript

Use somente para menu mobile, rolagem suave, animações com `IntersectionObserver`, ano atual e `APP_URL`. A página deve continuar legível sem JavaScript.

## Qualidade e validação

- HTML semântico, CSS com variáveis em `:root`, acessibilidade, contraste e foco visível.
- Layout correto em 360, 768 e 1440 px, sem overflow horizontal.
- Metatags de viewport, descrição e compartilhamento.
- Título: `ContAI — Fale o que vendeu. A gente cuida das contas.`
- Sem Lorem Ipsum e sem afirmar disponibilidade comercial.
- Teste links, botões, menu mobile e console.
- Confirme que nenhum framework ou dependência foi usado.
- Informe arquivos criados e como abrir a página.
- Se possível, entregue capturas desktop e mobile.

