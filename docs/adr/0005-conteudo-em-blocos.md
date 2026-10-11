# 0005 — Conteúdo em blocos, conflito por bloco

- **Status:** Aceita
- **Data:** 2026-10-10
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-03), §7, §8, §11; ADR 0006, ADR 0009

## Contexto

Usuários editam a mesma página em mais de um aparelho, às vezes ao mesmo tempo e offline (persona Bruno). Se a página inteira for a unidade de conflito, qualquer edição simultânea colide, mesmo em parágrafos diferentes.

## Decisão

O conteúdo de uma página é uma lista de **blocos** (tabela `blocks`: `type`, `content_json`, `position`, `version`, `updated_at`, `updated_by`). **A unidade de conflito é o bloco.**

## Alternativas descartadas

- **Página inteira como um texto** — mais colisões; sem caminho incremental para coedição.

## Consequências

- Edições em blocos diferentes nunca colidem (last-write-wins por bloco, fase 2).
- Caminho aberto para CRDT por bloco na fase 4 (ADR 0009).
- O editor de blocos precisa se adaptar a esse modelo. Risco médio, mitigado por um spike de 1 semana na fase 1 antes de fixar o editor (PRD §11).
