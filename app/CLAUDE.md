# CLAUDE.md — app (Flutter)

App mobile do Jotline. Regras gerais e invariantes no [CLAUDE.md da raiz](../CLAUDE.md); requisitos em [docs/prd/PRD.md](../docs/prd/PRD.md).

> Esqueleto criado com `flutter create` (`com.jon.jotline`, Android e iOS) e as dependências da stack. Ainda **não decididos** — pergunte antes de assumir: organização de `lib/`, Riverpod com ou sem geração de código, conjunto de lints (hoje o padrão `flutter_lints`).

## Stack

- **Flutter via FVM** (versão fixada em `.fvmrc`); Android e iOS.
- **Estado:** Riverpod. A UI consome streams reativos do banco local.
- **Banco local:** SQLite com **Drift** — fonte da verdade no aparelho (ADR 0001). Na fase 2 o SQLite passa a ser gerenciado pelo PowerSync, com Drift por cima.
- **Preferências:** `hive_ce` — só tema, último caderno aberto e afins; nada que sincronize.
- **Editor de blocos:** _em aberto_ — `flutter_quill`, `appflowy_editor` ou `super_editor`, decidido por spike de 1 semana. Não adote um sem a decisão registrada em ADR.
- **Desenho (RF-06, Could):** `perfect_freehand`, traços salvos como JSON.
- **Ordem:** índice fracionário em `position` — reordenar altera uma linha só.
- **Testes:** `flutter_test` + `mocktail`; banco testado com Drift real em memória; e2e com `integration_test` (ADR 0015).

## Comandos

Sempre via `fvm`, para usar a versão fixada.

```bash
fvm flutter pub get
fvm flutter run
fvm flutter analyze
fvm dart format lib test integration_test
fvm flutter test
fvm flutter test path/to/file_test.dart
fvm flutter test integration_test                              # e2e; exige emulador ou aparelho
fvm dart run build_runner build --delete-conflicting-outputs   # após clonar e após mudar tabelas Drift
fvm dart run drift_dev make-migrations                         # após subir schemaVersion
```

Código gerado (`*.g.dart`) não é versionado: gere localmente antes de analyze, test e build. CI a definir.

## Estrutura

_A definir no scaffold._

## Referências

Leia o doc antes de mexer no tema (ADR 0014).

| Quando | Arquivo |
| --- | --- |
| Escrever ou mudar qualquer teste, mexer em tabela Drift ou criar um fluxo de tela | [`app/.claude/docs/testes.md`](.claude/docs/testes.md) |
| Mexer em tela, tema, cor, fonte ou ícone | [`app/.claude/docs/design.md`](.claude/docs/design.md) |

## Regras

- **Invariantes da raiz, do lado do app:** IDs gerados no momento da criação, offline; consultas filtram registros com `deleted_at`; telas e regras de negócio nunca importam o SDK do PowerSync.
- **Modelo de dados da fase 1 já inclui** `notebook_members` (só o dono), `blocks.version` e `updated_by`, mesmo sem servidor (PRD §7).
- **Autoria antes do login:** um usuário local anônimo (UUID v7 gerado na primeira abertura) preenche `created_by`, `user_id`, `added_by` e `updated_by`; no login, uma transação o troca pelo id da conta antes do primeiro upload (ADR 0011).
- **Arquivar é por membro:** `notebook_members.archived_at` da linha do usuário, não `deleted_at` (ADR 0012).
- **O app nunca incrementa `blocks.version`:** guarda a versão recebida do servidor e a envia como base no upload (ADR 0013).
- **Fase 2:** a fila de upload sobrevive a fechar o app, reiniciar e trocar de rede (RNF-02); o indicador de estado é discreto — sincronizado, pendente, erro (RF-09).
- **Desempenho:** lista e abertura de página sem carregamento perceptível com 10 mil páginas locais (RNF-06).
- **Testes (ADR 0015):** todo código novo vem com teste de unidade ou widget; o que toca o Drift, com teste de banco em memória; mudança de schema, com migração testada; fluxo principal, com e2e.
