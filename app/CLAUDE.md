# CLAUDE.md — app (Flutter)

App mobile do Jotline. Regras gerais e invariantes no [CLAUDE.md da raiz](../CLAUDE.md); requisitos em [docs/prd/PRD.md](../docs/prd/PRD.md).

> Esqueleto criado com `flutter create` (`com.jon.jotline`, Android e iOS) e as dependências da stack. Ainda **não decididos** — pergunte antes de assumir: organização de `lib/`, Riverpod com ou sem geração de código, conjunto de lints (hoje o padrão `flutter_lints`).

## Stack

- **Flutter 3.47.5 via FVM** (`.fvmrc`); Android e iOS.
- **Estado:** Riverpod. A UI consome streams reativos do banco local.
- **Banco local:** SQLite com **Drift** — fonte da verdade no aparelho (ADR 0001). Na fase 2 o SQLite passa a ser gerenciado pelo PowerSync, com Drift por cima.
- **Preferências:** `hive_ce` — só tema, último caderno aberto e afins; nada que sincronize.
- **Editor de blocos:** _em aberto_ — `flutter_quill`, `appflowy_editor` ou `super_editor`, decidido por spike de 1 semana. Não adote um sem a decisão registrada em ADR.
- **Desenho (RF-06, Could):** `perfect_freehand`, traços salvos como JSON.
- **Ordem:** índice fracionário em `position` — reordenar altera uma linha só.

## Comandos

Sempre via `fvm`, para usar a versão fixada.

```bash
fvm flutter pub get
fvm flutter run
fvm flutter analyze
fvm dart format lib test
fvm flutter test
fvm flutter test path/to/file_test.dart
fvm dart run build_runner build --delete-conflicting-outputs   # após clonar e após mudar tabelas Drift
```

Código gerado (`*.g.dart`) não é versionado: gere localmente e o CI gera antes de analyze, test e build.

## Estrutura

_A definir no scaffold._

## Regras

- **Toda leitura e escrita vai ao Drift.** Nenhum widget, provider ou caso de uso chama HTTP para mostrar ou gravar uma nota (RNF-01).
- **IDs UUID v7 gerados no app**, no momento da criação, offline.
- **Nunca `DELETE` físico**: marque `deleted_at`. Consultas filtram registros excluídos.
- **Sync atrás de uma interface própria** (ADR 0002). Telas e regras de negócio dependem da interface, nunca do SDK do PowerSync.
- **Modelo de dados da fase 1 já inclui** `notebook_members` (só o dono), `blocks.version` e `updated_by`, mesmo sem servidor (PRD §7).
- **Autoria antes do login:** um usuário local anônimo (UUID v7 gerado na primeira abertura) preenche `created_by`, `user_id`, `added_by` e `updated_by`; no login, uma transação o troca pelo id da conta antes do primeiro upload (ADR 0011).
- **Arquivar é por membro:** `notebook_members.archived_at` da linha do usuário, não `deleted_at` (ADR 0012).
- **O app nunca incrementa `blocks.version`:** guarda a versão recebida do servidor e a envia como base no upload (ADR 0013).
- **Fase 2:** a fila de upload sobrevive a fechar o app, reiniciar e trocar de rede (RNF-02); o indicador de estado é discreto — sincronizado, pendente, erro (RF-09).
- **Desempenho:** lista e abertura de página sem carregamento perceptível com 10 mil páginas locais (RNF-06).
- Mudanças de schema exigem migração Drift com teste.
