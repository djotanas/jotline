# 0013 — Só o servidor incrementa `blocks.version`

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-10), §8; ADR 0003, ADR 0005, ADR 0006

## Contexto

A cópia de conflito (ADR 0006) compara a `version` em que a edição do app se baseou com a versão que o servidor tem. A ADR 0006 não definia quem incrementa `version`, e `blocks.version` existe desde a fase 1, quando ainda não há servidor.

## Decisão

**Só o servidor incrementa `blocks.version`**, a partir da fase 2, ao aceitar uma escrita no bloco. O servidor é o responsável pelo conflito.

O app nunca incrementa `version`: guarda a última versão recebida do servidor e a envia como base em cada operação de `POST /sync/upload`. Na fase 1, todo bloco mantém a versão inicial.

## Alternativas descartadas

- **App incrementa a cada edição** — dois aparelhos chegariam à mesma versão por caminhos diferentes, e a comparação no servidor deixaria de detectar o conflito.

## Consequências

- A detecção de conflito tem uma única fonte de verdade, coerente com as escritas via API .NET (ADR 0003).
- Na fase 1 a coluna não muda; ela só passa a ter valores relevantes com o sync.
- Uma mudança nesta regra altera o contrato de sync dos dois lados (`server/` primeiro, depois `app/`).
