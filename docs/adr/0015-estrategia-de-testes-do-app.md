# 0015 — Estratégia de testes do app

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** ADR 0001, ADR 0002, ADR 0014

## Contexto

O app ainda é o esqueleto do `flutter create`, com só `flutter_test` e o teste do contador. Antes da primeira tela, falta decidir o que é obrigatório testar e com quais ferramentas.

O app é offline-first: o SQLite (Drift) é a fonte da verdade no aparelho (ADR 0001), e boa parte das regras — soft delete, UUID v7 no cliente, membros do caderno, `updated_by` — mora em consultas e escritas no banco. Um erro de SQL ou de migração perde dados do usuário sem rede para recuperar.

O repo já exige gerar código (`build_runner`, `*.g.dart` não versionados) antes de analisar e testar. Cada passo de geração a mais pesa no ciclo de teste.

## Decisão

1. **Unidade e widget, sempre:** toda regra de negócio, provider e tela com lógica vem com teste.
2. **Banco, sempre, com SQLite real em memória:** todo DAO, repositório, consulta e migração Drift é testado com `NativeDatabase.memory()`, um banco novo por teste. O banco não é mockado.
3. **Migrações** testadas pelo fluxo do `drift_dev make-migrations`: schema de cada versão versionado no repo e verificado passo a passo.
4. **mocktail** para mocks e fakes, usado só acima da camada de dados (interface de sync, relógio, gerador de id).
5. **E2E com `integration_test`** (pacote do SDK) para os fluxos principais da fase 1.

## Alternativas descartadas

- **mockito** — mocks tipados gerados e mantido pelo time do Dart, mas exige `@GenerateMocks` e `build_runner`. Seria mais um passo de geração antes de cada teste, num repo que já depende de codegen. O mocktail não gera código e usa `when(() => ...)`, que encaixa nos overrides do Riverpod.
- **Patrol desde já** — controla o lado nativo (modo avião, rede, permissões), mas traz setup e dependência externa. A fase 1 roda inteira offline e não precisa disso. **Reavaliar na fase 2**, quando o e2e precisar ligar e desligar a rede (RNF-02, RF-09).
- **Mockar o banco** — testes mais isolados, mas escondem erros de SQL, índice e migração, justamente onde o app não pode errar. O SQLite em memória custa milissegundos por teste.
- **Banco testado só em migrações e consultas críticas** — menos testes, mas deixa sem cobertura as escritas que garantem as invariantes.

## Consequências

- Teste de banco roda no host via `libsqlite3`, sem emulador; o custo é baixo e entra no `flutter test` padrão.
- Os arquivos de schema por versão (`drift_schemas/`) passam a ser versionados e mudam junto com cada migração.
- E2E precisa de emulador ou aparelho e fica fora do `flutter test` padrão até existir CI.
- `mocktail` e `integration_test` entram em `dev_dependencies`.
- Os detalhes de como testar ficam em `app/.claude/docs/testes.md` (ADR 0014).
