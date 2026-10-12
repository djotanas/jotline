# 0034 — Ordenação dos cadernos

- **Status:** Aceita
- **Data:** 2026-10-12
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-01); ADR 0018; M01 PREF-05

## Contexto

A lista de cadernos tinha o botão "Ordenar" só como ícone (M01) e uma ordem fixa (M02). O design passou a definir três opções de ordenação, valendo para as abas Ativos e Arquivados.

## Decisão

1. Há três opções: **Editados recentemente**, **Nome (A–Z)** e **Data de criação**. A escolha vale para as duas abas.
2. O padrão é **Editados recentemente**: data da última edição decrescente, sendo essa o maior `updated_at` entre as páginas do caderno, ou o `created_at` do caderno quando não há páginas. O desempate é por `id` decrescente.
3. **Nome (A–Z)** ignora maiúsculas e acentos (pt-BR), de modo que "árvore" fica junto de "arvore", antes de "Bloco". O desempate é por `id` crescente.
4. **Data de criação** ordena por `created_at` decrescente, com desempate por `id` decrescente.
5. A escolha fica no `hive_ce`, numa segunda chave ao lado de `lastOpenedNotebookId`. Valor ausente ou desconhecido, ou caixa indisponível, usa o padrão.

Isso estende o PREF-05 do M01 ("só `lastOpenedNotebookId`") e substitui a ordem fixa do M02, sem editá-los.

## Alternativas descartadas

- **Guardar a ordenação no Drift** — é preferência de interface do aparelho, que não deve sincronizar (`app/CLAUDE.md`).
- **Uma ordenação por aba** — mais controles para pouco ganho; o design usa uma só.

## Consequências

- A lista de cadernos agrega a data da última página editada, então reordenar ou editar uma página muda a posição do caderno.
- Sem a caixa de preferências, a escolha vale só durante a sessão.
