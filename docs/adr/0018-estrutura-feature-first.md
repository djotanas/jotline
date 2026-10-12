# 0018 — Estrutura do `lib/`: feature-first

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** ADR 0016

## Contexto

O app ainda era o esqueleto do `flutter create`, sem nenhuma organização de pastas definida para `lib/`. O milestone #01 monta o shell do app e os primeiros arquivos de tema e preferências, então a estrutura precisa existir antes deles para não exigir mover arquivos depois. Toda feature posterior (modelo de dados, cadernos, páginas, editor) também depende de onde os arquivos vão morar.

## Decisão

`lib/` segue uma organização feature-first: `lib/main.dart` e `lib/app.dart` no topo, `lib/core/` para código sem feature própria (tema, banco, preferências, design system) e `lib/features/<feature>/{data,presentation}/` para cada feature, criada quando a primeira feature chegar (milestone #03). `lib/l10n/` guarda o ARB e os arquivos gerados pelo `gen-l10n`. `test/` espelha `lib/` arquivo por arquivo: `lib/x/y.dart` → `test/x/y_test.dart`.

## Alternativas descartadas

- **Layer-first** (`lib/screens/`, `lib/widgets/`, `lib/models/`, `lib/services/` cruzando todas as features) — cresce mal: uma mudança numa feature espalha edições em quatro pastas diferentes.
- **Tudo em `lib/` sem subpastas** — funciona com poucos arquivos, mas o milestone já traz tema, preferências, banco e um design system inteiro; ficaria ilegível rapidamente.

## Consequências

- Todo código deste milestone (tema, banco, preferências, design system) entra em `lib/core/`, já que nenhum é específico de uma feature ainda.
- `lib/features/` só aparece no milestone #03, com a primeira feature.
- `test/` precisa manter o espelhamento file-by-file; um teste sem par em `lib/` quebra a verificação automática (STRUCT-03).
- O `app/CLAUDE.md` deixa de listar a organização do `lib/` como indecidida.
