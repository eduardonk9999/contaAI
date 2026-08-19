# Homepage — Conta+

Landing page institucional do Conta+.

## Como abrir

Não há build, bundler nem dependência. Abra o arquivo direto no navegador:

```bash
open homepage/index.html
```

Se preferir servir por HTTP:

```bash
python3 -m http.server 8080 --directory homepage
```

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `index.html` | Marcação semântica de todas as seções |
| `styles.css` | Estilos, variáveis de tema em `:root` e breakpoints |
| `script.js` | Menu mobile, rolagem suave, animações e ano do rodapé |

## Stack

HTML5, CSS3 e JavaScript puro. Sem React, Vue, Tailwind, Bootstrap, jQuery, npm ou etapa de build.

## Destino dos botões

O `script.js` começa com a constante `APP_URL`:

```js
const APP_URL = "";
```

Vazia, os botões apenas rolam até a seção de demonstração. Preenchida com o endereço do aplicativo, todos os CTAs passam a navegar para lá.

## Decisões

- **Mobile-first.** O CSS base atende telas pequenas; os breakpoints em 768 px e 1024 px ampliam o layout.
- **Funciona sem JavaScript.** As animações de entrada só são aplicadas quando o JS carrega, então nada fica invisível se ele falhar.
- **Acessibilidade.** Link de pular para o conteúdo, foco visível, menu com `aria-expanded`, ícones SVG marcados como decorativos e `prefers-reduced-motion` respeitado.
- **Sem conteúdo inventado.** Não há depoimentos, logotipos de clientes, métricas de uso nem afirmação de disponibilidade comercial. Preços aparecem como hipótese sujeita a validação no piloto.

## Conteúdo

Preços e limites seguem [`../docs/BUSINESS-MODEL.md`](../docs/BUSINESS-MODEL.md): Gratuito R$ 0, Solo R$ 14,90/mês e Pro R$ 34,90/mês. O plano futuro de R$ 69,90 não é exibido. Ao alterar os planos naquele documento, atualize a seção `#planos` do `index.html`.
