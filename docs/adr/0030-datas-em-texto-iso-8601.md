# 0030 — Datas como texto ISO-8601 em UTC

- **Status:** Aceita
- **Data:** 2026-10-12
- **Decisores:** @jon
- **Relacionados:** ADR 0001; PRD §7 (convenções de datas)

## Contexto

O Drift guarda `DateTime` como segundos Unix por padrão, o que descarta os milissegundos e não é legível ao inspecionar o banco. A opção `store_date_time_values_as_text` guarda texto ISO-8601 e é a recomendada para projetos novos. Porém `DateTime.toIso8601String()` escreve os microssegundos só quando são diferentes de zero, então `…:05.120Z` e `…:05.120001Z` têm comprimentos diferentes e a ordem do texto deixa de coincidir com a ordem no tempo.

## Decisão

1. `store_date_time_values_as_text: true` no `build.yaml`, com todas as datas em UTC.
2. O relógio do app trunca para milissegundos, de modo que toda data gravada tem sempre o mesmo formato.

## Alternativas descartadas

- **Segundos Unix (padrão)** — perde precisão e legibilidade.
- **Milissegundos inteiros** — ordenam bem, mas diferem do formato ISO que o servidor e o PRD usam.
- **Normalizar o formato na hora de gravar, em cada repositório** — espalha a regra; o relógio é um ponto só.

## Consequências

- `ORDER BY` sobre colunas de data funciona como ordenação por texto.
- Datas que não passam pelo relógio do app (por exemplo, recebidas do servidor na fase 2) precisam chegar já com a mesma precisão.
- Os testes usam um relógio falso que só aceita valores alinhados a milissegundos.
