# 0035 — Editor de blocos: super_editor

- **Status:** Aceita
- **Data:** 2026-10-12
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-03, RF-04), §11; ADR 0005, ADR 0013, ADR 0029; issue #22 (spike), #23, #24

## Contexto

O RF-03 pede um editor com texto rico, título, lista e checklist, e a ADR 0005 exige que cada bloco seja uma linha própria de `blocks`, porque a unidade de conflito na fase 2 é o bloco. O PRD §11 deixou o editor em aberto entre `flutter_quill`, `appflowy_editor` e `super_editor`, a decidir por um spike de uma semana (#22), com os critérios SPIKE-01 a SPIKE-07 da spec da M04.

O spike fez um protótipo de cada candidato no Flutter 3.47.5 fixado no `app/.fvmrc` (branch `spike/22-block-editor`, que não vai para a `main`). Cada protótipo lê e grava linhas no formato de `blocks` com um `content_json` próprio (`text`, `marks`, `checked`). O spike rodou testes automatizados e também digitação real com o Gboard pt-BR num emulador Android 15. Não houve iPhone nem simulador iOS disponível.

| Critério | super_editor 0.3.0-dev.52 | flutter_quill 11.6.0 | appflowy_editor (git `main` @ 01eccc6) |
| --- | --- | --- | --- |
| SPIKE-01 roda no Flutter fixado | sim (precisa de `compileSdk 36` no Android) | sim | não na 6.2.0 publicada; só no `main` não publicado |
| SPIKE-02 uma linha por bloco, id estável, divisão e junção | sim, ids próprios dos nós | parcial: sem id de linha; na junção sobrevive o objeto de baixo; precisa de heurística | parcial: troca de tipo recria o nó com outro id; precisa de heurística |
| SPIKE-03 detectar a mudança de um bloco sem serializar a página | sim, log de mudanças por transação com o id do nó | parcial: delta por offset; o IME recebe o texto da página inteira | parcial: operações por caminho, sem id |
| SPIKE-04 ida e volta do `content_json` sem perda | sim | sim | sim |
| SPIKE-05 quatro tipos, negrito, itálico, checklist, bloco próprio | sim | sim | sim |
| SPIKE-06 pt-BR com acento, autocorreção e composição | Android (emulador): sim; iOS: não verificado | Android (emulador): parcial, o Enter do teclado na tela não dividiu; iOS: não verificado | Android (emulador): não, Enter não dividiu; iOS: não verificado |
| SPIKE-07 licença | MIT | MIT | AGPL-3.0 ou MPL-2.0 |
| SPIKE-07 última versão | 0.3.0-dev.52 (2026-06-11, pré-lançamento); estável 0.2.7 de 2024 | 11.6.0 (2026-09-16) | 6.2.0 (2025-12-08), incompatível |
| SPIKE-07 estilo do canvas (fundo em edição, alça, item marcado) | sim, por builders de componente | não sem fork (fundo e alça por linha) | não verificado |
| Regras de Enter e Backspace da spec | todas nativas | faltam duas (CHECK-04, CHECK-07) | falta uma (EDIT-08) |

## Decisão

1. **O editor de blocos do app é o `super_editor`**, na versão exata `0.3.0-dev.52` (pré-lançamento), sem faixa de versão. Atualizar é uma tarefa própria, com os testes do mapeamento.
2. **O documento do editor nunca é persistido.** Uma camada própria converte cada nó em uma linha de `blocks` no formato de `content_json` da ADR do modelo de blocos. Os nós carregados usam o id do bloco como id do nó; nós criados pelo editor recebem o id gerado pelo repositório na primeira gravação.
3. **A mudança de cada bloco vem do log de mudanças do editor** (`EditListener` com `DocumentEdit`), conferido contra o documento final: nó presente é gravado, nó ausente vai para a lixeira (`deleted_at`). Uma movimentação grava só a linha movida.
4. **A ADR é aceita sem verificação em iOS e com o Android testado só no emulador**, por falta de aparelho. O roteiro manual (`spikes/m04-editor/REPORT.md` na branch `spike/22-block-editor`, "Manual checklist") roda num iPhone e num Android físico na issue #67, antes do Gate 1. Se algum item de SPIKE-06 falhar, uma nova ADR substitui esta.

## Alternativas descartadas

- **flutter_quill** — o pacote mais maduro e ativo, mas o modelo é um Delta plano sem identidade de bloco. Na junção sobrevive o objeto da linha de baixo, e desfazer ou trocar o documento perde a identidade. Fundo e alça do bloco em edição exigiriam fork da renderização das linhas.
- **appflowy_editor** — a versão publicada não compila no Flutter fixado, e a correção existe só no `main`, sem release. A licença AGPL-3.0/MPL-2.0 pede uma decisão à parte frente à MIT (ADR 0021). Toda troca de tipo recria o nó com outro id, e o Enter não dividiu o bloco no emulador.
- **Editor próprio** — controle total do modelo por bloco, mas sem o trabalho de IME, seleção e gestos que o `super_editor` já resolve. Fica como saída se o roteiro iOS falhar.

## Consequências

- O `app/CLAUDE.md` cita o `super_editor` e esta ADR na linha "Block editor" (SPIKE-09).
- O risco de IME no iOS (acentos, autocorreção, ditado, cursor flutuante; issue #2269 do `super_editor`) segue aberto até a #67.
- O app depende de um pacote em pré-lançamento mantido quase só por uma pessoa. O risco é aceito na fase 1, e a camada de mapeamento isola o resto do app da biblioteca.
- O build Android precisa de `compileSdk 36` para o `super_keyboard 0.4.1`, que ainda aplica o Kotlin Gradle Plugin; o Flutter avisa que versões futuras deixarão de compilar com ele. Reavaliar a cada atualização do Flutter.
- O #23 precisa de um componente próprio de item de checklist (caixa 22×22, linha de 44 px) e de um wrapper para o bloco em edição. Decorações dentro dos componentes não podem capturar toques, senão o cursor deixa de ser posicionado.
- O `BlockRepository` precisa gravar `type` junto com `content_json` para a troca de tipo (BAR-05).
- A SAVE-08 da spec segue o comportamento do editor: numa seleção que cruza blocos, o primeiro bloco recebe o texto juntado e os demais ganham `deleted_at`.
- A alça de mover segue o desenho do canvas, dentro dos 12 px de sangria, mesmo com área de toque menor que 44 × 44.
