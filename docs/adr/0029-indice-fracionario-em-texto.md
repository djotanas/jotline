# 0029 — Índice fracionário em chaves de texto base-62

- **Status:** Aceita
- **Data:** 2026-10-12
- **Decisores:** @jon
- **Relacionados:** ADR 0005; PRD §7 (`position`), RF-02

## Contexto

Páginas e blocos têm ordem definida pelo usuário, e mover um item deve alterar uma única linha, para sincronizar pouco e conflitar pouco. O PRD §7 pede `position` em índice fracionário, sem definir o formato da chave.

## Decisão

1. `position` é uma chave de texto de tamanho variável, com dígitos base-62 (`0-9A-Za-z`). Os dígitos são ASCII, então a ordem byte a byte, o `compareTo` do Dart e a collation `BINARY` do SQLite concordam.
2. Empates (chaves iguais entre irmãos, possíveis com escritas de aparelhos diferentes) se desfazem por `id`.
3. O algoritmo é uma porta própria do rocicorp/fractional-indexing, licenciada CC0, sem novo pacote.
4. A chave nova é calculada considerando também os irmãos excluídos, para que restaurar uma linha não colida com a posição de outra.
5. Não há rebalanceamento na fase 1.

## Alternativas descartadas

- **Pacote pronto de índice fracionário** — mais uma dependência para um algoritmo curto e já testável por nós.
- **Posição inteira e renumeração** — mover um item reescreve os vizinhos.
- **Posição `REAL`** — perde precisão após inserções repetidas no mesmo ponto.

## Consequências

- Inserir no fim ou no início mantém a chave curta; inserir repetidamente entre os mesmos dois itens a alonga.
- Sem rebalanceamento, o crescimento das chaves é aceito na fase 1; reavaliar se uma lista real mostrar chaves longas.
- A escrita recebe um `Placement`, nunca uma chave crua, e um `PositionAllocator` converte o `Placement` em chave dentro da transação.
