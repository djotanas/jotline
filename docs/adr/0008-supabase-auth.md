# 0008 — Supabase Auth no início

- **Status:** Aceita
- **Data:** 2026-10-10
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-07), §6; ADR 0002, ADR 0003

## Contexto

A fase 2 traz conta e login (RF-07). O token precisa ser aceito tanto pela API .NET quanto pelo PowerSync. O Postgres do servidor já fica no Supabase.

## Decisão

Usar **Supabase Auth (JWT)** a partir da fase 2. O mesmo token vale para a API .NET e para o PowerSync.

## Alternativas descartadas

- **Identity próprio desde o começo** — mais código na fase 2, sem ganho imediato.

## Consequências

- Menos código na fase 2.
- Como o token é JWT padrão, trocar de provedor depois é viável. Plano de saída: Keycloak ou ASP.NET Identity emitindo JWT.
- Dados criados antes do login precisam passar para a conta ao entrar (RF-07); a migração tem teste dedicado (PRD §11).
