# 0009 — CRDT adiado para a fase 4

- **Status:** Aceita
- **Data:** 2026-10-10
- **Decisores:** @jon
- **Relacionados:** PRD §2, §8, §9, §11; RF-19, RF-20; ADR 0005, ADR 0006

## Contexto

Coedição em tempo real no mesmo bloco (RF-19) exige CRDT. As bibliotecas para Dart ainda são imaturas, e no servidor o YDotNet está em fase inicial e mira `net8.0`. Não há dados mostrando que as pessoas editam o mesmo bloco ao mesmo tempo.

## Decisão

**Adiar CRDT para a fase 4**, que só existe se o gate 3 mostrar que vale o custo. Até lá, os degraus 1 (last-write-wins por bloco), 1b (cópia de conflito) e 2 (histórico de versões) cobrem o uso assíncrono.

## Alternativas descartadas

- **Yjs desde o início** — bibliotecas Dart imaturas; custo alto sem demanda comprovada.

## Consequências

- Coedição em tempo real e presença (RF-19, RF-20) ficam fora do escopo até nova decisão.
- Gate 3: métricas de conflito por bloco e pedidos explícitos de coedição precisam justificar o custo.
- Se a fase 4 acontecer: Yrs via `flutter_rust_bridge` no app, YDotNet no servidor (testar no .NET 10 antes de adotar), tabela `page_updates` só de inserções, compactada em snapshots pelo .NET.
- O modelo em blocos (ADR 0005) mantém esse caminho aberto.
