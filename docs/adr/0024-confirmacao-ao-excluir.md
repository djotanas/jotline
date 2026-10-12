# 0024 — Confirmação ao excluir: página com desfazer, caderno com diálogo

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-01, RF-12); ADR 0023

## Contexto

O PRD não define se excluir uma página ou um caderno pede confirmação. As duas exclusões são reversíveis pela lixeira (RF-12), mas têm alcances diferentes: excluir um caderno leva todas as páginas dele junto (ADR 0023).

## Decisão

1. Excluir **página** não pede confirmação. A página vai para a lixeira e aparece um aviso com "Desfazer".
2. Excluir **caderno** abre um diálogo de confirmação antes.

## Alternativas descartadas

- **Confirmar sempre** — atrito numa ação reversível.
- **Nunca confirmar** — excluir um caderno inteiro por engano assusta, mesmo sendo reversível.

## Consequências

- Toda exclusão tem caminho de volta, pelo desfazer ou pela lixeira.
- Em aberto: por quanto tempo o aviso de desfazer fica na tela.
