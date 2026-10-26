# Medição de desempenho com 10 mil páginas (LOAD-08)

A medição abaixo foi feita pelo agente no aparelho do usuário, não pelo usuário.

## Ambiente

- Aparelho: Samsung SM-A356E, Android 16, adb sem fio.
- Build: `flutter drive --profile`, `integration_test/perf/large_library_test.dart`.
- Dados: seed de LOAD-01 em arquivo SQLite (21 cadernos, 12.000 páginas, 240.000 blocos); seed leva cerca de 39 s no aparelho.

## SPEC_DEVIATION (LOAD-04)

A rolagem é medida com `SchedulerBinding.addTimingsCallback` e `FrameTimingSummarizer`, e não com `traceAction` e o resumo da timeline. Motivo: o adb sem fio não alcança o VM service. A chave `average_frame_build_time_millis` e a meta de 16 ms são as mesmas; a contagem de quadros das duas fontes pode diferir (lacuna de precisão da spec).

## Valores contra as metas

| Alvo | Meta | Sem índice novo (1 execução) | Com índice `blocks_page_edits` (3 execuções) |
| --- | --- | --- | --- |
| LOAD-02 lista de cadernos | < 100 ms | 296 ms (não atinge) | 2192, 2188, 2182 ms (não atinge) |
| LOAD-03 abrir caderno de 10.000 páginas | < 100 ms | 2186 ms (não atinge) | 683, 696, 702 ms (não atinge) |
| LOAD-04 média de build por quadro na rolagem | < 16 ms | 6,36 ms (atinge) | 6,73, 7,03, 6,87 ms (atinge) |
| LOAD-05 abrir página | < 100 ms | 44 ms (atinge) | 47, 50, 48 ms (atinge) |
| LOAD-06 busca "belém" após debounce de 150 ms | < 100 ms | 88 ms (atinge) | 103, 100, 89 ms (oscila na meta) |

Pior quadro de build na rolagem: 48 ms sem índice, 38 a 44 ms com índice. PERF-01 (`launch_to_new_page`) segue gerando o arquivo: toList 102 ms, toEditor 234 ms.

## Tentativa de índice (única, LOAD-09)

Índice `blocks_page_edits` em `blocks(page_id, updated_at, deleted_at)`, schema v4, migração v3 para v4 com teste. Planos antes e depois (consulta de resumo de cadernos e de páginas):

- Antes: `SEARCH blocks USING INDEX blocks_page_position (page_id=?)`, com leitura da linha para `updated_at` e `deleted_at`.
- Depois: `SEARCH blocks USING COVERING INDEX blocks_page_edits (page_id=?)` nas agregações de resumo, na ordenação da busca e nos dois `max` da página; o trecho (`excerpt`) segue em `blocks_page_position`.

## Atrito

- O índice moveu o custo: LOAD-03 caiu de 2186 para cerca de 690 ms, mas LOAD-02 subiu de 296 para cerca de 2190 ms de forma estável. Hipótese não testada: a verificação de integridade (INTEG-01) roda no isolate principal logo depois do primeiro quadro e disputa com a primeira consulta da lista. A causa não foi investigada.
- Há uma só execução sem o índice; a variação entre execuções sem índice é desconhecida.
- O resumo de páginas recalcula três subconsultas por página e reemite as 10.000 linhas a cada escrita de bloco (risco já listado no design).
- Parar aqui, conforme LOAD-09: nenhuma outra otimização foi tentada.

## Decisão do usuário

2026-10-19: manter o índice `blocks_page_edits` (schema v4, commit 9cab0a7) e aceitar os valores medidos com lacuna. LOAD-02 (cerca de 2190 ms) e LOAD-03 (cerca de 690 ms) ficam acima da meta de 100 ms e LOAD-06 oscila na meta; a investigação vira issue de acompanhamento. A M05 segue para a fase 6.
