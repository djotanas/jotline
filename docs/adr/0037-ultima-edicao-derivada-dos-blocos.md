# 0037 — Última edição da página derivada dos blocos

- **Status:** Aceita
- **Data:** 2026-10-15
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-02, RF-03); ADR 0005, ADR 0030, ADR 0034, ADR 0036; issue #24; spec da M04 (EDITED-01…EDITED-05, EXCERPT-01, ADR-01); M02 REPO-17; M03 SORT-03

## Contexto

Até a M03, a "última edição" de uma página era o `pages.updated_at`, e a de um caderno era o maior `updated_at` das suas páginas (ADR 0034, item 2; M03 SORT-03). Com o editor de blocos, escrever numa página grava só linhas de `blocks`: a regra REPO-17 da M02 proíbe que uma escrita de bloco altere a linha da página. Sem mudança, a linha "Editada", a data na lista de páginas e a ordenação "Editados recentemente" ficariam paradas enquanto o usuário escreve.

## Decisão

1. **A última edição de uma página é derivada na consulta**: o maior entre `pages.updated_at` e o `updated_at` e o `deleted_at` de todos os seus blocos, apagados incluídos. Em SQL, cada agregado de bloco vem em `COALESCE(…, p.updated_at)`, porque o `max()` escalar do SQLite devolve `NULL` se algum argumento for `NULL`. Comparar texto é válido porque toda data tem o mesmo formato ISO-8601 em UTC (ADR 0030).
2. **Escrever um bloco não grava na página.** A REPO-17 continua valendo: uma edição muda uma única linha de `blocks`, o que mantém o conflito por bloco da ADR 0005.
3. **A última edição do caderno** é o maior entre `pages.updated_at`, `blocks.updated_at` e `blocks.deleted_at` das páginas fora da lixeira, ou o `created_at` do caderno quando não há nenhum. Os blocos de uma página na lixeira ficam de fora com ela; a contagem de páginas usa `COUNT(DISTINCT pages.id)`, porque a junção com `blocks` repete as páginas.
4. **Isso substitui a data do item 2 da ADR 0034** (e da M03 SORT-03) para a ordenação "Editados recentemente". O resto da ADR 0034 continua valendo.
5. A linha "Editada", a data da linha de página, a data da folha "Opções da página" e a meta do caderno usam essa data. As consultas observadas declaram `pages`, `blocks` e `notebooks` como fontes, então reemitem a cada escrita de bloco.

## Alternativas descartadas

- **Gravar `pages.updated_at` a cada escrita de bloco** — quebra a REPO-17 e, na fase 2, faria toda edição de bloco colidir na linha da página.
- **Uma coluna `last_edited_at` mantida por trigger** — exige migração e é uma escrita a mais na página, com o mesmo problema de conflito.

## Consequências

- Sem mudança de schema e sem escrita extra na página.
- A lista de páginas e a de cadernos fazem subconsultas e agregados sobre `blocks`; o índice `blocks_page_position` cobre a busca por página, e o custo com 10.000 páginas (RNF-06) é medido na M05 (#27).
- Apagar um bloco também conta como edição, mesmo sem outra mudança na página.
- Na fase 2, um bloco recebido de outro aparelho muda a última edição da página sem que ninguém grave nela.
