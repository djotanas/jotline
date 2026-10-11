# 0006 — Cópia de conflito em vez de sobrescrita

- **Status:** Aceita
- **Data:** 2026-10-10
- **Decisores:** @jon
- **Relacionados:** PRD §2, §4 (RF-10), §8; ADR 0003, ADR 0005

## Contexto

O sucesso do produto é medido por confiança: o usuário nunca perde texto (meta de zero edições perdidas). Last-write-wins por bloco (ADR 0005) ainda descarta a edição perdedora quando duas pessoas mudam o mesmo bloco.

## Decisão

Quando duas edições colidem no mesmo bloco, o servidor **cria uma cópia do bloco** em vez de sobrescrever (RF-10).

O app envia a `version` do bloco em que a edição se baseou. Se o servidor já tem versão mais nova, a operação gera a cópia de conflito.

## Alternativas descartadas

- **Last-write-wins puro** — viola o requisito de nunca perder texto.

## Consequências

- Nenhuma sobrescrita silenciosa: o conflito fica visível para o usuário.
- `blocks.version` existe desde a fase 1, mesmo sem servidor.
- A taxa de conflitos resolvidos sem cópia é acompanhada; a meta é definida na fase 3.
- Cópias de conflito podem poluir a página se forem frequentes — esse dado alimenta o gate 3 (ADR 0009).
