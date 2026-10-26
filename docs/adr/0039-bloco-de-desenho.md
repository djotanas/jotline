# 0039 — Bloco de desenho

- **Status:** Aceita
- **Data:** 2026-10-18
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-06); ADR 0005, ADR 0013, ADR 0035, ADR 0036; issue #25; spec da M05 (DRAW-03, DRAW-05…DRAW-07, DRAW-19, DRAW-20)

## Contexto

A ADR 0036 definiu quatro tipos de bloco, todos de texto, e deixou o desenho (RF-06) para um tipo novo. O desenho é um traço livre feito com o dedo ou a caneta, e precisa ser guardado sem depender da biblioteca que o desenha (`perfect_freehand`) nem do editor (`super_editor`). O mesmo desenho aparece como cartão na página e em tela cheia no modo desenho, em tamanhos diferentes, e deve ficar igual em qualquer aparelho.

## Decisão

1. **Novo tipo `drawing` em `blocks.type`.** Um desenho é um bloco como os outros: uma linha, com `version` só incrementado pelo servidor (ADR 0013). Esta ADR estende a ADR 0036; versões antigas do app leem o tipo desconhecido como `text`.
2. **`content_json` guarda só a lista de traços**, com os dados de entrada e nenhum campo da biblioteca de desenho:

   ```json
   {"strokes":[{"tool":"highlighter","color":"accent","width":6,"points":[[60.0,470.0,0.5],[100.4,440.0,0.62]]}]}
   ```

   - `tool`: `pen` ou `highlighter`. Id desconhecido é lido como `pen`.
   - `color`: `ink` (tinta preta, `ink.1`), `accent` (azul) ou `danger` (terracota). Id desconhecido é lido como `ink`.
   - `width`: `3` (fino), `6` (médio) ou `12` (grosso). O marca-texto guarda a largura escolhida; a pintura aplica 3 vezes a largura e 35 % de opacidade.
   - `points`: lista de `[x, y, pressure]`. Um traço de um ponto é desenhado como um ponto.
3. **Área lógica de 390 × 560.** Os pontos são guardados nessa escala, não em pixels da tela. O cartão e o modo desenho escalam a mesma área, sem corte, e o desenho fica igual em qualquer tamanho de tela.
4. **Arredondamento:** `x` e `y` a 0,1 unidade lógica e `pressure` a 0,01, para o JSON ficar pequeno.
5. **Borracha de traço inteiro:** ao tocar um traço, ele inteiro é removido. A borracha remove todo traço que tenha um ponto ou segmento a `width / 2 + 10` unidades lógicas do toque.
6. **O JSON que não lê vira um desenho vazio.** O cartão mostra a área em branco e a página não quebra.
7. **O desenho fica fora do trecho da página e da busca** (DRAW-20): o trecho já só aceita os tipos de texto, e o índice só lê o texto dos blocos de texto.
8. Só a pasta `lib/features/blocks/presentation/drawing/` importa o `perfect_freehand`, e só `lib/features/blocks/presentation/editor/` importa o `super_editor`.

## Alternativas descartadas

- **Guardar a saída do `perfect_freehand` (o contorno já calculado)** — prende os dados à versão da biblioteca, é muito maior (um polígono por traço) e não permite apagar ou refazer o traço com os pontos originais.
- **Imagem em pixels (PNG)** — não escala entre telas, não permite apagar um traço e pesa mais no banco e, na fase 2, no envio.
- **Coordenadas em pixels da tela** — o mesmo desenho ficaria diferente em cada aparelho.

## Consequências

- O desenho entra na sincronização como um bloco comum: o conflito é por bloco (ADR 0005) e nenhuma migração é necessária.
- Trocar a biblioteca de desenho só exige refazer a pintura; os dados continuam válidos.
- Um tool, cor ou largura novo é um identificador novo no JSON, lido com o padrão nas versões antigas.
- O JSON de um desenho cheio tem milhares de pontos; o tamanho continua pequeno por causa do arredondamento.
- A pintura (suavização, pressão simulada) pode mudar sem alterar nenhum dado guardado.
