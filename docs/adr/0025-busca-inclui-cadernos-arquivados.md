# 0025 — Páginas de caderno arquivado continuam na busca

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-01, RF-05); ADR 0012

## Contexto

A ADR 0012 definiu o arquivamento por membro (`notebook_members.archived_at`), mas não o efeito dele na busca local (RF-05).

## Decisão

A busca local **inclui páginas de cadernos arquivados**. Arquivar tira o caderno só da lista principal.

## Alternativas descartadas

- **Excluir arquivados da busca** — esconderia conteúdo que o usuário não apagou.

## Consequências

- Itens na lixeira (`deleted_at` preenchido) continuam fora da busca. O arquivamento não usa `deleted_at` (ADR 0012).
- Em aberto: o resultado da busca deve indicar que o caderno está arquivado?
