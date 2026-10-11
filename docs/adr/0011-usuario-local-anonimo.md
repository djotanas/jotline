# 0011 — Usuário local anônimo antes do login

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-04, RF-07), §5 (RNF-04, RNF-07), §7; ADR 0004, ADR 0008

## Contexto

Na fase 1 não há conta (RF-04), mas o modelo de dados já tem colunas de autoria: `notebooks.created_by`, `notebook_members.user_id` e `added_by`, `pages.updated_by` e `blocks.updated_by` (PRD §7). Todo caderno precisa de uma linha `owner` em `notebook_members` (ADR 0004), e o histórico da fase 3 não pode nascer sem autoria. Na fase 2, os dados criados sem login passam para a conta (RF-07).

Os IDs das entidades (UUID v7) não dependem do aparelho nem da conta. O que falta antes do login é um valor para o autor.

## Decisão

1. Na primeira abertura, o app gera um **usuário local anônimo**: um UUID v7 guardado no aparelho. Esse id preenche todas as colunas de autoria enquanto não há conta.
2. No login (RF-07), uma **única transação local** troca o id anônimo pelo id da conta em todas as colunas de autoria, antes do primeiro upload.
3. Se a conta já tem dados de outro aparelho, os dados locais são **somados à conta automaticamente**, sem perguntar ao usuário. Como os IDs são UUID v7 gerados no cliente, não há colisão entre aparelhos.

O servidor nunca confia no autor enviado: autoriza e grava autoria pelo usuário do token (RNF-07).

## Alternativas descartadas

- **Colunas nulas até o login** — perde o `NOT NULL`, toda consulta trata nulo e a linha `owner` em `notebook_members` fica sem `user_id`.
- **Id local permanente, mapeado pelo servidor** — a autoria fica presa ao aparelho (uma pessoa teria vários ids) e o servidor dependeria de um valor do payload, contra o RNF-07.
- **Perguntar ao usuário se junta ou descarta os dados locais no login** — passo a mais sem ganho, já que a junção não gera conflito.

## Consequências

- As colunas de autoria são `NOT NULL` desde a fase 1.
- A troca do id anônimo é determinística e acontece uma vez, no login. Não há script de reparo depois.
- A migração para a conta tem teste dedicado (PRD §11), incluindo o caso de conta que já tem dados de outro aparelho.
- Em aberto: o que acontece com os dados locais no logout e quando outra conta entra no mesmo aparelho (RNF-09).
