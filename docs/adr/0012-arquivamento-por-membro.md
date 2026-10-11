# 0012 — Arquivamento de caderno por membro

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-01, RF-13), §7; ADR 0004

## Contexto

O RF-01 pede arquivar cadernos, mas o modelo de dados (PRD §7) não tinha onde guardar isso. Na fase 1 o único membro é o dono; na fase 3 um caderno pode ter vários membros (RF-13), e arquivar passa a ter dois sentidos possíveis: tirar o caderno da lista de todos ou só da lista de quem arquivou.

## Decisão

Arquivar é **por membro**: a coluna `archived_at` (UTC, nula quando ativo) fica em `notebook_members`. Arquivar preenche a coluna na linha do usuário; desarquivar a limpa. O caderno arquivado sai só da lista principal de quem arquivou.

## Alternativas descartadas

- **`notebooks.archived_at`, global** — um membro arquivando tiraria o caderno da lista de todos; mudar isso na fase 3 exigiria migração.

## Consequências

- Na fase 1 o comportamento é o mesmo de um arquivamento global, porque só existe o dono.
- O compartilhamento da fase 3 não exige migração: cada membro já tem a própria coluna (ADR 0004).
- Arquivar é diferente de excluir: não usa `deleted_at` e não passa pela lixeira (RF-12).
