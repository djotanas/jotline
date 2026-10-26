# 0038 — Busca local

- **Status:** Aceita
- **Data:** 2026-10-17
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-05), RNF-06; ADR 0002, ADR 0036, ADR 0037; issue #26; spec da M05 (SRCH-04, SRCH-08, SRCH-18, SRCH-19, LOAD-06, LOAD-07)

## Contexto

O RF-05 pede busca local por título e conteúdo. Nada do que foi escrito pode ser reencontrado sem abrir os cadernos um a um. A busca precisa funcionar offline, ignorar caixa e acentos, casar o início das palavras ("bele" acha "Belém") e responder em menos de 100 ms com 10 mil páginas (RNF-06). O conteúdo está em `blocks.content_json` (ADR 0036), um bloco por linha, e a página é a unidade que o usuário procura.

## Decisão

1. **Uma tabela virtual FTS5, `page_search`, com uma linha por página** e as colunas `title` e `body`. O `body` junta o texto dos blocos não apagados dos tipos `text`, `heading`, `bulleted_list_item` e `checklist_item`, em ordem de `position, id`, separados por U+2029. Desenhos ficam fora (SRCH-09). Uma linha por página faz o "Tudo" casar título e conteúdo juntos com `AND`, sem agregar resultados (SRCH-08).
2. **Tokenizador `unicode61 remove_diacritics 2`**, que ignora caixa e acentos (SRCH-04). O tokenizador do SQLite decide o que casou; o Dart não reimplementa a normalização.
3. **Casamento por prefixo de palavra com `AND`:** cada palavra da consulta vira um termo entre aspas com `*` no fim (`"bele"* AND "belém"*`). Aspas, `*`, `-`, `OR` e `NEAR` digitados pelo usuário são texto, nunca operadores.
4. **O índice é mantido por gatilhos SQL** em `pages` (inserção e mudança de `title`) e em `blocks` (inserção, atualização e remoção). Qualquer escritor, inclusive o backfill da migração, deixa o índice consistente, e nenhum caminho de código Dart pode esquecer de atualizá-lo (SRCH-18).
5. **O `rowid` do índice é o `rowid` de `pages`.** Nenhum `VACUUM` pode rodar sem reindexar, porque ele pode renumerar os `rowid`.
6. **Páginas e cadernos apagados continuam no índice;** a consulta os filtra (SRCH-09). Restaurar da lixeira (RF-12) não exige reindexar.
7. **A migração v2 → v3 cria a tabela e os gatilhos e indexa todas as páginas existentes em um único `INSERT … SELECT`** (SRCH-19).
8. **Os trechos destacados são carregados por linha visível,** com `highlight()` sobre a página daquela linha. Rodar `highlight()` sobre milhares de corpos estouraria a meta de LOAD-06. A lista de resultados vem sem destaque.
9. **A busca roda só no SQLite local,** atrás do repositório, sem tela dependente de rede (RNF-01). Plano de consulta sem varredura completa de `pages` ou `blocks` é verificado por teste (LOAD-07).

## Alternativas descartadas

- **Uma linha de FTS5 por bloco** — "Tudo" exigiria juntar título e blocos de uma página na consulta, e uma palavra no título com outra no corpo não casaria com `AND`; também multiplicaria as linhas do índice.
- **`LIKE '%termo%'`** — não ignora acentos sem normalização própria, não usa índice e varre `blocks` inteiro, o que não cabe em 100 ms com 10 mil páginas.
- **Indexar pelo Dart, no repositório** — qualquer escrita por outro caminho deixaria o índice defasado; os gatilhos cobrem todos.
- **Apagar do índice a página apagada** — restaurar da lixeira exigiria reindexar a página.

## Consequências

- Escrever uma página custa uma reescrita da linha do índice por alteração de bloco ou título.
- O `body` guarda uma cópia do texto da página; o banco cresce na proporção do conteúdo.
- Fase 2: o PowerSync mantém o SQLite por views e gatilhos próprios. Antes de adotá-lo é preciso confirmar que `page_search` e seus gatilhos convivem com isso; a ADR 0002 mantém o PowerSync atrás de interface nossa, então o risco fica contido na camada de dados.
- Trocar de tokenizador ou de regra de normalização exige recriar o índice em uma migração.
- Se a meta de 100 ms não for atingida, o trabalho para e o usuário decide (spec da M05, LOAD-09).
