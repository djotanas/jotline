# 0007 — Monólito modular em ASP.NET Core 10

- **Status:** Aceita
- **Data:** 2026-10-10
- **Decisores:** @jon
- **Relacionados:** PRD §6

## Contexto

O backend cobre upload do sync, autorização, convites e anexos. O time é pequeno e a escala inicial é a de um app em beta.

## Decisão

Um **monólito modular em ASP.NET Core 10 com Minimal APIs**, persistência com EF Core 10 + Npgsql e ambiente local com .NET Aspire (API, Postgres e PowerSync com um comando).

## Alternativas descartadas

- **Microsserviços** — a escala atual não justifica a complexidade.

## Consequências

- Um deploy, uma base de código, transações locais no Postgres.
- Módulos com fronteiras claras permitem extrair um serviço depois, se a escala justificar.
- Observabilidade com OpenTelemetry desde a fase 2.
