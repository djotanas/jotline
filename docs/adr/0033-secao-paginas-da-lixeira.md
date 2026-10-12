# 0033 — Seção "Páginas" da lixeira

- **Status:** Aceita
- **Data:** 2026-10-12
- **Decisores:** @jon
- **Relacionados:** ADR 0023, ADR 0027; PRD §4 (RF-12)

## Contexto

Os ADRs 0023 e 0027 deixaram em aberto se as páginas de um caderno excluído aparecem na seção "Páginas" da lixeira. Como excluir um caderno grava só `notebooks.deleted_at` (ADR 0027), essas páginas não têm `deleted_at` próprio.

## Decisão

1. A seção "Páginas" lista só as páginas **excluídas por conta própria** cujo caderno **não** está na lixeira.
2. As páginas de um caderno excluído não aparecem na seção: voltam junto com o caderno, quando ele é restaurado.
3. Restaurar uma página **nunca** altera o caderno dela.

## Alternativas descartadas

- **Listar também as páginas de cadernos excluídos** — a lixeira ficaria com milhares de linhas após excluir um caderno grande, e restaurar uma página dentro de um caderno excluído a deixaria invisível.
- **Restaurar o caderno junto com a página** — uma ação sobre uma página alteraria um item que o usuário não escolheu.

## Consequências

- A consulta da seção junta o caderno para filtrar `notebooks.deleted_at`.
- A página excluída sozinha antes do caderno continua listada na seção se o caderno for restaurado (ADR 0027).
- Responde à questão em aberto dos ADRs 0023 e 0027, sem editá-los.
