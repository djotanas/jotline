# 0026 — Usuário local anônimo numa tabela do Drift

- **Status:** Aceita
- **Data:** 2026-10-12
- **Decisores:** @jon
- **Relacionados:** ADR 0001, ADR 0011; PRD §7

## Contexto

O ADR 0011 define o usuário local anônimo (UUID v7 gerado na primeira abertura), mas não diz onde ele fica guardado. O app já usa `hive_ce` para preferências (tema, último caderno aberto) e Drift para os dados. O id do usuário local entra em colunas de autoria (`created_by`, `user_id`, `added_by`, `updated_by`) e, no login, é trocado pelo id da conta numa única transação local.

## Decisão

1. O usuário local anônimo fica na tabela `local_user` do Drift, com uma única linha.
2. A tabela é só local: nunca é sincronizada e permanece fora do que o PowerSync gerencia na fase 2.
3. A linha é criada na primeira abertura, dentro de uma transação, e as aberturas seguintes leem a mesma linha.

## Alternativas descartadas

- **Guardar o id no `hive_ce`** — o id e as linhas que o referenciam ficariam em dois bancos, sem transação comum. Um encerramento no meio da troca do id no login deixaria autoria inconsistente.
- **Guardar o id nas colunas de autoria apenas** — não há onde ler o id antes da primeira escrita, e cada repositório precisaria inventar o seu.

## Consequências

- A troca do id no login (ADR 0011) pode rodar na mesma transação que atualiza as colunas de autoria.
- O Hive continua só com preferências, sem nenhum dado do usuário.
- Na fase 2, `local_user` não entra no esquema do PowerSync.
- Em aberto: o que acontece com `local_user` no logout e na troca de conta (PRD §11).
