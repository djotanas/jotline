# 0004 — Todo caderno tem membros desde a fase 1

- **Status:** Aceita
- **Data:** 2026-10-10
- **Decisores:** @jon
- **Relacionados:** PRD §1, §5 (RNF-09), §7, §8; RF-13, RF-14

## Contexto

O app nasce individual (fase 1), mas o compartilhamento de cadernos chega na fase 3 (RF-13, RF-14). Um modelo que trate cadernos pessoais e compartilhados de forma diferente exigiria migrar dados quando alguém compartilha um caderno.

## Decisão

**Todo caderno tem linhas em `notebook_members` desde a fase 1.** Um caderno pessoal é um caderno com um único membro, o dono (`role = owner`). Os papéis são `owner`, `editor` e `viewer`.

## Alternativas descartadas

- **Modelos separados para pessoal e compartilhado** — compartilhar exigiria migração de dados.

## Consequências

- Compartilhar vira inserir uma linha em `notebook_members`, sem migração.
- A regra de sync é uma só para cadernos pessoais e compartilhados: o aparelho recebe todo caderno em que o usuário aparece como membro (RNF-09).
- Remover um membro também apaga o caderno do aparelho dessa pessoa no próximo sync.
- A fase 1 já carrega uma tabela que só terá um papel em uso até a fase 3.
