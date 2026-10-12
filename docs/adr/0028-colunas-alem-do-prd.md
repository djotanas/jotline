# 0028 — Colunas além do PRD §7: `blocks.deleted_at` e `notebook_members.id`

- **Status:** Aceita
- **Data:** 2026-10-12
- **Decisores:** @jon
- **Relacionados:** ADR 0002, ADR 0004; PRD §5 (RNF-05), §7

## Contexto

O modelo do PRD §7 não lista `blocks.deleted_at` nem uma chave primária de coluna única para `notebook_members`. Duas regras pedem essas colunas: todo registro sincronizado é apagado só logicamente (RNF-05), e o PowerSync exige uma coluna `id` de texto como chave primária em cada tabela sincronizada e não aceita chaves compostas.

## Decisão

1. `blocks` ganha `deleted_at`, para que um bloco possa ser excluído sozinho e a exclusão sincronize.
2. `notebook_members` ganha `id` (texto, UUID v7 gerado no cliente) como chave primária. `(notebook_id, user_id)` fica com restrição de unicidade.
3. O PRD §7 é atualizado para listar as duas colunas.

Não entram na fase 1: `notebooks.updated_at` e `updated_by`, `pages.created_at` e `created_by`, `blocks.created_at` e `created_by`.

## Alternativas descartadas

- **Chave composta `(notebook_id, user_id)`** — não é suportada pelo PowerSync.
- **Montar o `id` no servidor concatenando as colunas** — o app precisaria do mesmo valor para escrever e para ler, e a chave deixaria de ser um UUID v7 gerado no cliente (RNF-04).
- **Apagar blocos fisicamente** — contra o RNF-05.

## Consequências

- Trocar o nome de um valor de enum gravado com `textEnum` exige migração de schema, porque as linhas guardam o nome.
- Na fase 2 o PowerSync gerencia as tabelas como views, sem chaves estrangeiras nem `CHECK`. As garantias que a fase 1 deixa a cargo do SQLite precisarão ir para tabelas brutas ou para verificações nos repositórios (decisão da fase 2, #08).
