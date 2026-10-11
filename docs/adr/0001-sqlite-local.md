# 0001 — SQLite com Drift como banco local

- **Status:** Aceita
- **Data:** 2026-10-10
- **Decisores:** @jon
- **Relacionados:** PRD §5 (RNF-01), §6; ADR 0002

## Contexto

O app é offline-first: toda leitura e escrita vai ao banco local, e a rede nunca bloqueia a UI (RNF-01). O banco local é a fonte da verdade no aparelho e precisa continuar servindo quando o sync entrar na fase 2.

O PowerSync, escolhido para o sync (ADR 0002), traz o próprio SQLite no cliente. Hive ou Isar como banco principal obrigariam a manter dois bancos e copiar dados entre eles. Além disso, o Isar original está sem manutenção e o Hive sobrevive num fork comunitário (`hive_ce`).

## Decisão

Usar **SQLite com Drift** como banco local desde a fase 1. Na fase 2, o mesmo SQLite passa a ser gerenciado pelo PowerSync, com o Drift por cima.

`hive_ce` fica restrito a preferências locais que não sincronizam (tema, último caderno aberto).

## Alternativas descartadas

- **Hive** — exigiria um segundo banco ao lado do SQLite do PowerSync; mantido só por fork comunitário.
- **Isar** — mesmo problema de dois bancos; versão original sem manutenção.

## Consequências

- Consultas tipadas e reativas: a UI consome streams do Drift.
- O formato é padrão e sobrevive à troca da lib de sync: num sync próprio, volta a ser SQLite puro.
- Mudanças de schema passam por migrações Drift.
