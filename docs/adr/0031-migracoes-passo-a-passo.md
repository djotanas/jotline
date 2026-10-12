# 0031 — Versionamento do schema com migrações passo a passo

- **Status:** Aceita
- **Data:** 2026-10-12
- **Decisores:** @jon
- **Relacionados:** ADR 0001, ADR 0015

## Contexto

O banco local é a fonte da verdade no aparelho (ADR 0001), então uma migração errada perde dados do usuário. O ADR 0015 exige que mudanças de schema venham com migração testada. Faltava definir como o schema é versionado e verificado.

## Decisão

1. Cada mudança de tabela incrementa `schemaVersion` e roda `drift_dev make-migrations`, que exporta o schema da versão para `drift_schemas/`, gera `app_database.steps.dart` e cria o teste em `test/drift/`.
2. Os schemas exportados e o `.steps.dart` são versionados no git e nunca editados à mão.
3. A migração `vN → vN+1` usa os helpers gerados, e o teste gerado (`SchemaVerifier`) é completado com dados: linhas criadas na versão antiga precisam sobreviver à nova.
4. `test/drift/` fica isento da regra de espelhamento de `lib/`, porque esses testes não têm arquivo de origem próprio.
5. As chaves estrangeiras são ligadas em `beforeOpen` (`PRAGMA foreign_keys = ON`).

## Alternativas descartadas

- **`onUpgrade` escrito à mão com `if (from < N)`** — sem verificação automática do schema final de cada versão.
- **Recriar o banco a cada versão** — perde dados do usuário.

## Consequências

- Todo schema publicado fica congelado em `drift_schemas/`, e o teste compara o resultado de cada migração com ele.
- O `.steps.dart` gerado pode acusar lint do `very_good_analysis` e ser excluído da análise.
- Na fase 2, o PowerSync passa a gerenciar o SQLite; o versionamento das tabelas locais não sincronizadas segue este fluxo.
