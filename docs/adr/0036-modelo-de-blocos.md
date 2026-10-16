# 0036 — Modelo de blocos

- **Status:** Aceita
- **Data:** 2026-10-15
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-03), §7; ADR 0005, ADR 0013, ADR 0035; issue #23; spec da M04 (SAVE-01, SAVE-10, ADR-01)

## Contexto

A ADR 0005 fez do bloco a unidade de conflito e criou a tabela `blocks` com `type` e `content_json`, mas não disse o que é um bloco, quais são os tipos nem o formato do conteúdo. A ADR 0035 escolheu o `super_editor`, cujo documento tem nós e atribuições próprias. Se o `content_json` guardasse esse modelo interno, trocar ou atualizar a biblioteca exigiria migrar dados, e a busca e o trecho da página (M05, #26) dependeriam do editor para ler texto.

## Decisão

1. **Uma linha de `blocks` por item:** cada parágrafo, título, item de lista e item de checklist é um bloco. Dois aparelhos que marcam itens diferentes da mesma checklist não entram em conflito (ADR 0005).
2. **Quatro tipos**, com estes identificadores em `blocks.type`:
   - `text` — parágrafo;
   - `heading` — título de um nível só;
   - `bulleted_list_item` — item de lista com marcador;
   - `checklist_item` — item de checklist.
3. **Tipo desconhecido é lido como `text`.** Um tipo novo (como o desenho, #25) não quebra uma versão antiga do app.
4. **`content_json` é um formato nosso**, sem campo da biblioteca do editor:

   ```json
   {"text":"Belém cedo","marks":[{"start":0,"end":5,"type":"bold"}],"checked":false}
   ```

   - `text`: o texto como digitado, espaços nas pontas incluídos.
   - `marks`: faixas de `bold` e `italic`, ordenadas, sem sobreposição nem adjacência do mesmo tipo e sem faixa vazia. Tipo de marca desconhecido é ignorado na leitura.
   - `checked`: só em `checklist_item`; nos outros tipos o campo não existe.
5. **Offsets em unidades UTF-16, com `end` exclusivo.** É a unidade das `String` do Dart; o mapeamento converte o fim inclusivo das atribuições do `super_editor` (ADR 0035).
6. Só a pasta `lib/features/blocks/presentation/editor/` importa o `super_editor`; o resto do app lê `blocks` e `content_json`.

## Alternativas descartadas

- **Guardar o documento do editor (JSON do `super_editor` ou Markdown)** — prende os dados à biblioteca e a uma versão pré-lançamento; a busca precisaria do editor.
- **Uma linha por lista ou checklist inteira** — marcar dois itens em aparelhos diferentes viraria conflito, contra a ADR 0005.
- **Offsets em grafemas ou code points** — exigiria conversão em toda leitura e escrita; as posições do editor já respeitam grafemas, então UTF-16 não corta emoji.

## Consequências

- Busca, trecho da página e a fase 2 leem o conteúdo sem depender do editor.
- Trocar de editor só exige refazer o mapeamento nó ⇄ bloco, não migrar dados.
- O mapeamento é código nosso, onde os erros sutis vão morar; ele fica com testes próprios.
- Um tipo novo (desenho, nível de título, lista numerada) é um identificador novo e um componente novo no editor, sem migração; versões antigas o mostram como texto.
- Listas aninhadas e mais níveis de título ficam de fora até uma nova decisão.
