# M01 Foundation Specification

GitHub milestone [#01 - Foundation](https://github.com/djotanas/jotline/milestone/2) — issues #4–#12. Phase 1. Decisions taken in discussion: [context.md](context.md).

## Problem Statement

The app is still the `flutter create` counter template: default lints, no `lib/` organization, no test layout, no CI, no commit convention check, no license, no theme and no preferences storage. Every feature milestone after this one (data model, notebooks, pages, editor) needs these in place, and `app/CLAUDE.md` still lists lints, structure and Riverpod style as undecided. This milestone settles those decisions and builds the shared foundation so feature work starts on rails.

## Goals

- [ ] Every open "undecided" item in `app/CLAUDE.md` (lint set, `lib/` organization, Riverpod codegen) is decided, recorded in an ADR and reflected in `app/CLAUDE.md`.
- [ ] `fvm flutter analyze` reports 0 issues and `fvm flutter test` passes, both locally and in CI, on every change under `app/`.
- [ ] All design tokens and all components of the canvas "Componentes" artboard (except the two editor-coupled ones) exist in Flutter with widget tests, so feature screens never use a literal color, size or font.
- [ ] Every commit message is checked against Conventional Commits locally and in CI.

## Out of Scope

| Feature | Reason |
| --- | --- |
| Drift tables (`notebooks`, `notebook_members`, `pages`, `blocks`), UUID v7 generator, clock provider, fractional index | Milestone #02 - Local data model |
| Notebook, page, search and trash screens | Later phase 1 milestones; this milestone only builds their components |
| Editor block visuals and the block toolbar ("Blocos do editor", "Barra de blocos") | Coupled to the block editor library, still in spike (PRD §11) |
| "Padrões de estado e sync" artboard (sync status indicator) | Phase 2 (RF-09) |
| Undo toast for page deletion ("Página excluída: desfazer") | Not in the "Componentes" artboard; built with the page deletion flow (RF-12) |
| Dark theme | Canvas defines light only; issue #11 scopes "light" |
| iOS build in CI | Needs a macOS runner; Android build covers compile errors for phase 1 |
| E2E tests (`integration_test/`) and running them in CI | Issue #7 scopes unit, widget and Drift layers; e2e needs an emulator |
| Golden tests | `app/.claude/docs/testes.md`: no golden tests for now |
| `riverpod_lint` / `custom_lint` | Not requested in #4 or #6 |
| CI for `server/` | `server/` starts in phase 2 |
| English UI (`app_en.arb`) | ADR 0016: PT-BR only in phase 1 |

---

## Assumptions & Open Questions

Every ambiguity is resolved or recorded here - nothing is left silently unclear. All rows confirmed by the user on 2026-10-11.

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| `.specs/` language | English | Agent-facing like `CLAUDE.md`; EARS keywords are English | y |
| Lint set (#4) | `very_good_analysis` replaces `flutter_lints` | User decision | y |
| `lib/` organization (#5) | Feature-first: `lib/core/` + `lib/features/<feature>/{data,presentation}/` | User decision | y |
| Riverpod style (#6) | Hand-written providers, no codegen | User decision; one less generation step (same reasoning as ADR 0015 on mockito) | y |
| License (#10) | MIT | User decision | y |
| Commit check tooling (#9) | POSIX shell hook in `.githooks/` + GitHub Actions job | User decision; no Node in a Flutter/.NET repo; docs commits go straight to `main`, so a local hook is needed | y |
| Components in this milestone (#11) | Tokens + theme + every "Componentes" artboard component | User decision | y |
| Token identifiers | Flat camelCase on a `ThemeExtension` (`bgMesa`, `ink1`, `accentTraco`) | User decision | y |
| Editor block visuals and block toolbar | Out of scope (see table above) | They are the visual layer of a library not yet chosen; building them now risks rework after the spike | y |
| `public_member_api_docs` (very_good_analysis) | Disabled in `analysis_options.yaml` | Root `CLAUDE.md` allows doc comments but does not require them; an app has no public API consumers | y |
| Home screen while no feature exists | An empty `Scaffold` with background `bgMesa`, no text and no component; replaced by the notebooks screen in its milestone | User decision: no temporary screen without a canvas design; the template counter must go | y |
| Database for the Drift sample test (#7) | `AppDatabase` with no tables and `schemaVersion` 1; tables arrive in #02 | Issue #7 needs a Drift test and helper now; schema is #02's scope | y |
| Fonts | Schibsted Grotesk, Literata and IBM Plex Mono bundled as app assets (OFL); no runtime download | RNF-01: no screen reads from the network; the `google_fonts` package fetches over HTTP by default | y |
| Localization setup | `flutter_localizations` + `intl` + `gen-l10n` with `app_pt.arb` set up in this milestone | ADR 0016: set up "when the app structure is assembled", which is #5; components need l10n for fixed labels ("Cancelar") | y |
| CI build step | `flutter build apk --debug` on `ubuntu-latest` | Catches compile/platform errors without signing secrets or a macOS runner | y |
| Allowed commit types | `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert` | Conventional Commits / commitlint conventional set | y |
| Allowed commit scopes | Optional; one of `app`, `server`, `docs`, `infra` | Issue #9 list plus existing labels; matches `docs(app):` already in history | y |
| Commit header max length | 100 characters | commitlint conventional default; current history fits | y |
| Commit description language | Not checked | User decision; root `CLAUDE.md` says commits are in Portuguese, the hook checks only structure | y |
| Theme preference (#12) | Not stored in this milestone; only `lastOpenedNotebookId` is a key | Only a light theme exists; a theme key with one possible value has no behavior to test. Added with the second theme | y |
| Notebook color and cover identifiers | Mirror canvas names: colors `azulTinta`, `terracota`, `musgo`, `mostarda`, `ameixa`, `grafite`; covers `lisa`, `pautada`, `pontilhada`, `quadriculada` | `design.md`: tokens keep canvas names; #02 will persist these names in `notebooks.color` / `cover`, so they must be stable | y |
| ADRs | One ADR each for #4 (lint), #5 (structure), #6 (Riverpod), #9 (commit convention + check), #10 (license), #11 (token mapping + bundled fonts), numbered from 0017, in Portuguese | DoD of every issue: "ADR created if a decision was made" | y |
| Preferences box fails to open | App starts with no stored preferences (all reads return `null`) and does not crash; the box file is not deleted | Preferences are disposable UI state; a crash at launch would block writing (RNF-01) | y |
| Icon rendering | The 10 canvas icons are drawn from the canvas SVG geometry; technique (painter, SVG package, icon font) decided in Design | A new dependency is a design decision | y |

**Open questions:** none - all resolved and confirmed.

---

## User Stories

### P1: Lint set ⭐ MVP

**User Story**: As the developer, I want a strict, agreed lint set so that style and correctness issues are caught before review.

**Why P1**: Every line written after this is checked against it; changing it later means a mass reformat.

**Acceptance Criteria**:

1. The `app/analysis_options.yaml` SHALL include `package:very_good_analysis/analysis_options.yaml` and SHALL NOT include `package:flutter_lints`. (LINT-01)
2. The `app/pubspec.yaml` SHALL list `very_good_analysis` in `dev_dependencies` and SHALL NOT list `flutter_lints`. (LINT-02)
3. The analyzer SHALL exclude `**/*.g.dart`, `build/**`, `android/**` and `ios/**`. (LINT-03)
4. The rule `public_member_api_docs` SHALL be disabled in `analysis_options.yaml`. (LINT-04)
5. WHEN `fvm flutter analyze` runs on `app/` after `build_runner build` THEN it SHALL report 0 issues. (LINT-05)
6. The `app/CLAUDE.md` SHALL name `very_good_analysis` as the lint set and SHALL NOT list the lint set as undecided. (LINT-06)

**Independent Test**: Run `fvm flutter analyze` → "No issues found!"; introduce `print('x')` in `lib/` → analyzer reports `avoid_print`.

---

### P1: Feature-first structure and app shell ⭐ MVP

**User Story**: As the developer, I want a defined `lib/` layout and a clean app shell so that every feature lands in a predictable place.

**Why P1**: Theme, tests, preferences and every later feature depend on where files live.

**Acceptance Criteria**:

1. The `app/lib/` SHALL contain only `main.dart`, `app.dart`, `core/`, `features/` and `l10n/` at its top level. (STRUCT-01)
2. The `app/CLAUDE.md` "Structure" section SHALL describe `core/` (cross-feature code) and `features/<feature>/{data,presentation}/`, and SHALL NOT list `lib/` organization as undecided. (STRUCT-02)
3. The `app/test/` SHALL mirror `app/lib/`: every test file `test/x/y_test.dart` SHALL correspond to `lib/x/y.dart`. (STRUCT-03)
4. The template counter app (`MyApp`, `MyHomePage`) and the template `test/widget_test.dart` SHALL be removed, and `main.dart`, `pubspec.yaml` and `analysis_options.yaml` SHALL contain no `flutter create` template comments. (STRUCT-04)
5. WHEN the app starts THEN it SHALL show an empty `Scaffold` with background `bgMesa` and no text or child widget. (STRUCT-05)
6. The app SHALL use `flutter_localizations` + `gen-l10n` with a single `lib/l10n/app_pt.arb`, `pt_BR` as the only supported locale, and English keys. (STRUCT-06)
7. The widgets under `lib/` SHALL NOT contain user-facing string literals; every UI text SHALL come from the generated localizations or a constructor parameter. (STRUCT-07)
8. The `pubspec.yaml` `description` SHALL describe Jotline instead of "A new Flutter project.". (STRUCT-08)

**Independent Test**: Widget test pumps the root app widget, finds one `Scaffold` with `bgMesa` background and no `Text`; `find lib -maxdepth 1` lists only the allowed entries.

---

### P1: Riverpod without code generation ⭐ MVP

**User Story**: As the developer, I want one Riverpod style so that providers look the same everywhere and tests override them the same way.

**Why P1**: The database and preferences providers in this milestone already need a style.

**Acceptance Criteria**:

1. The `app/pubspec.yaml` SHALL NOT depend on `riverpod_annotation` or `riverpod_generator`. (RVP-01)
2. WHEN the app starts THEN the root widget SHALL be wrapped in a `ProviderScope`. (RVP-02)
3. The `app/CLAUDE.md` SHALL state that providers are declared by hand without code generation and SHALL NOT list Riverpod style as undecided. (RVP-03)

**Independent Test**: Widget test pumps the app's root and finds a `ProviderScope` ancestor; `grep riverpod_generator app/pubspec.yaml` returns nothing.

---

### P1: Test foundation ⭐ MVP

**User Story**: As the developer, I want the test layout, the in-memory database helper and a passing sample per layer so that every feature starts with its tests in place (ADR 0015).

**Why P1**: ADR 0015 makes tests mandatory for all new code; the helper is needed before #02 creates tables.

**Acceptance Criteria**:

1. The app SHALL provide an `AppDatabase` (Drift) whose constructor takes a `QueryExecutor`, with no tables and `schemaVersion` 1. (TEST-01)
2. The production executor (`drift_flutter`) SHALL be created outside `AppDatabase` and exposed through a `databaseProvider` that tests override. (TEST-02)
3. The test code SHALL provide a helper that returns a new `AppDatabase` on `NativeDatabase.memory()` for each call. (TEST-03)
4. WHEN two tests each call the helper THEN they SHALL receive distinct databases with no shared state. (TEST-04)
5. The `app/test/` SHALL contain at least one passing unit test, one passing widget test and one passing Drift test against the in-memory database. (TEST-05)
6. WHEN `fvm flutter test` runs on a machine with no emulator or device THEN every test SHALL pass. (TEST-06)
7. The `app/.claude/docs/testes.md` SHALL replace "The `lib/` organization is still undecided" with the mirroring rule for the chosen structure. (TEST-07)

**Independent Test**: `fvm flutter test` → all pass; the Drift sample opens the in-memory database and runs `SELECT 1`.

---

### P1: Continuous integration for `app/` ⭐ MVP

**User Story**: As the developer, I want CI to analyze, format-check, test and build the app on every change so that a broken `main` is caught within minutes.

**Why P1**: Every issue's DoD requires "CI green".

**Acceptance Criteria**:

1. WHEN a push to `main` or a pull request changes any file under `app/` or the app workflow file THEN the app workflow SHALL run. (CI-01)
2. IF a push or pull request changes no file under `app/` and not the app workflow file THEN the app workflow SHALL NOT run. (CI-02)
3. The app workflow SHALL install the Flutter version pinned in `app/.fvmrc`. (CI-03)
4. The app workflow SHALL run `build_runner build --delete-conflicting-outputs` before analyze, format check, test and build. (CI-04)
5. IF `flutter analyze` reports any issue THEN the app workflow SHALL fail. (CI-05)
6. IF `dart format --set-exit-if-changed` finds an unformatted Dart file outside `*.g.dart` THEN the app workflow SHALL fail. (CI-06)
7. The format check SHALL NOT fail because of generated `*.g.dart` files. (CI-07)
8. IF any test in `fvm flutter test` fails THEN the app workflow SHALL fail. (CI-08)
9. The app workflow SHALL build an Android debug APK, and IF the build fails THEN the workflow SHALL fail. (CI-09)

**Independent Test**: Push a branch with an unformatted file → workflow red at the format step; fix → green. Push a change only to `docs/` → app workflow not triggered.

---

### P2: Theme and design tokens

**User Story**: As the developer, I want every canvas token available from the theme so that screens never contain literal colors, sizes or fonts.

**Why P2**: Needed before components and screens, but nothing above depends on it.

**Acceptance Criteria**:

1. The app SHALL expose every color token in the "Color tokens" table below through a `ThemeExtension`, with the camelCase name and the exact hex value listed. (THEME-01)
2. The app SHALL expose every text style token in the "Typography tokens" table below with the family, size, weight, letter spacing and line height listed. (THEME-02)
3. The app SHALL expose the spacing, radius and shadow tokens in the "Shape tokens" table below with the values listed. (THEME-03)
4. The app SHALL define the six notebook colors and four notebook covers in the "Notebook palette" table below as closed sets, with the identifiers listed. (THEME-04)
5. The app SHALL bundle Schibsted Grotesk (400, 500, 600, 700), Literata (400, 400 italic, 500) and IBM Plex Mono (400, 500) as font assets and SHALL NOT download fonts at runtime. (THEME-05)
6. WHEN the app starts THEN the OFL license of each bundled font SHALL be registered in Flutter's `LicenseRegistry`. (THEME-06)
7. The app SHALL provide a single light `ThemeData` with Material 3, whose `scaffoldBackgroundColor` is `bgMesa` and whose `colorScheme.primary` is `accent`. (THEME-07)
8. The app SHALL NOT clamp the system text scale, so every text style grows with the device font size preference. (THEME-08)
9. The files under `lib/` outside the theme folder SHALL NOT contain `Color(` literals, `Colors.` references or `fontFamily:` literals, enforced by an automated test that scans `lib/`. (THEME-09)
10. The `app/.claude/docs/design.md` "Open" section SHALL be resolved: theme file location, dotted-name → camelCase rule and notebook palette identifiers documented. (THEME-10)

**Independent Test**: Unit tests read each token from the built `ThemeData` and compare with the tables; the scan test fails if a `Color(0xFF000000)` is added to a feature file.

#### Color tokens

| Canvas token | Dart name | Hex |
| --- | --- | --- |
| bg.mesa | bgMesa | #F3F2EE |
| bg.papel | bgPapel | #FBFAF7 |
| bg.folha | bgFolha | #FFFFFF |
| bg.trilho | bgTrilho | #E6E4DE |
| line.base | lineBase | #DAD7CF |
| line.forte | lineForte | #CFCCC4 |
| ink.deco | inkDeco | #8A877F |
| ink.feito | inkFeito | #6E6B64 |
| ink.2 | ink2 | #5E5B54 |
| ink.corpo | inkCorpo | #3A3833 |
| ink.1 | ink1 | #1B1A17 |
| bg.veu | bgVeu | #8E8C86 |
| accent | accent | #2747C9 |
| accent.press | accentPress | #1A3399 |
| accent.soft | accentSoft | #DCE2F8 |
| accent.wash | accentWash | #EEF1FC |
| accent.traco | accentTraco | #B9C3EA |
| danger | danger | #A4402A |
| danger.bg | dangerBg | #FBEDE8 |
| accent.busca | accentBusca | #F3E2A9 |

#### Typography tokens

Families: `font.ui` = Schibsted Grotesk, `font.texto` = Literata, `font.meta` = IBM Plex Mono. Letter spacing −0.02em for sizes ≥ 28, 0 otherwise. Line height "—" means the font default.

| Canvas token | Dart name | Family | Size | Weight | Letter spacing | Line height | Color |
| --- | --- | --- | --- | --- | --- | --- | --- |
| titulo.tela | tituloTela | ui | 34 | 700 | −0.02em | — | ink1 |
| titulo.pagina | tituloPagina | ui | 28 | 700 | −0.02em | — | ink1 |
| bloco.titulo | blocoTitulo | ui | 19 | 600 | 0 | — | ink1 |
| titulo.sheet | tituloSheet | ui | 17 | 600 | 0 | — | ink1 |
| bloco.texto | blocoTexto | texto | 17 | 400 | 0 | 1.55 | ink1 |
| acao | acao | ui | 16 | 600 | 0 | — | ink1 |
| item.titulo | itemTitulo | ui | 16 | 600 | 0 | — | ink1 |
| card.titulo | cardTitulo | ui | 15 | 600 | 0 | — | ink1 |
| item.trecho | itemTrecho | texto | 14 | 400 | 0 | 1.4 | ink2 |
| apoio | apoio | ui | 14 | 400 | 0 | 1.45 | ink2 |
| rotulo | rotulo | ui | 13 | 600 | 0 | — | ink2 |
| meta | meta | meta | 12 | 400 | 0 | — | ink2 |

#### Shape tokens

| Group | Canvas token | Dart name | Value |
| --- | --- | --- | --- |
| Spacing | space.1 / .2 / .3 / .4 / .5 / .6 / .8 / .11 / .14 | space1 … space14 | 4 / 8 / 12 / 16 / 20 / 24 / 32 / 44 / 56 |
| Radius | r.etiqueta | rEtiqueta | 3 |
| Radius | r.capa | rCapa | 4 spine side, 12 open side |
| Radius | r.bloco | rBloco | 10 |
| Radius | r.campo | rCampo | 12 |
| Radius | r.card | rCard | 14 |
| Radius | r.botao | rBotao | 16 |
| Radius | r.fab | rFab | 18 |
| Radius | r.pilula | rPilula | 22 (pill button) / 24 (sheet top) |
| Shadow | shadow.toque | shadowToque | 0 1 2, black 8% |
| Shadow | shadow.capa | shadowCapa | 0 1 0 black 6% + 0 6 14 #1B1A17 12% |
| Shadow | shadow.erguido | shadowErguido | 0 12 28, #1B1A17 18% |
| Shadow | shadow.fab | shadowFab | 0 8 24, #2747C9 28% |

#### Notebook palette

| Canvas name | Identifier | Value |
| --- | --- | --- |
| Azul tinta | azulTinta | #2747C9 |
| Terracota | terracota | #B5532F |
| Musgo | musgo | #3F6B4A |
| Mostarda | mostarda | #C99A2E |
| Ameixa | ameixa | #6B3E6E |
| Grafite | grafite | #3B4651 |
| Lisa | lisa | solid color |
| Pautada | pautada | horizontal white lines 16%, 1 px every 14 px |
| Pontos | pontilhada | white dots 28%, radius 1.2, 12 px grid |
| Grade | quadriculada | white grid lines 14%, 1 px every 14 px |

---

### P2: Base components

**User Story**: As the developer, I want the canvas "Componentes" artboard built as reusable widgets so that every phase 1 screen is assembled from tested pieces.

**Why P2**: Screens in later milestones consume them; they depend on the theme.

**Acceptance Criteria**:

1. The app SHALL provide button widgets for the variants primary, destructive, floating (FAB with icon and label), secondary pill, text and icon, each with a minimum touch area of 44 × 44. (COMP-01)
2. WHILE a primary, secondary pill or text button has no `onPressed` THEN it SHALL render its disabled style and SHALL NOT respond to taps. (COMP-02)
3. The FAB and icon button SHALL NOT have a disabled state: their `onPressed` SHALL be required and non-null. (COMP-03)
4. The icon button SHALL require a semantic label and expose it to accessibility services. (COMP-04)
5. The app SHALL provide a segmented control that shows each option's label and count ("Ativos · 6"), marks exactly one option as selected (semantics `selected: true`) and calls back with the tapped option. (COMP-05)
6. The app SHALL provide a labeled text field with distinct focused and unfocused styles, and a search field with the search icon and a placeholder passed by parameter. (COMP-06)
7. The app SHALL provide a notebook cover widget that paints the notebook color, the cover pattern, the spine (12 px, black 18%), the elastic (6 px, black 28%, 18 px from the edge), the label in `bgPapel` with the title, and `shadowCapa`. (COMP-07)
8. The app SHALL provide a color picker with the six notebook colors and a cover picker with the four covers, each option with a semantic label equal to the canvas name, and WHEN an option is selected THEN it SHALL show a 2 px `ink1` ring and expose `selected: true`. (COMP-08)
9. The app SHALL provide list rows for: page (title, date in `meta`, excerpt in `itemTrecho`), page while dragging (handle with semantic label, title, `shadowErguido`) and archived or trashed notebook (mini cover, title, page count, one pill action). (COMP-09)
10. The app SHALL provide a bottom sheet with a 40 × 5 handle, top radius 24, a "Cancelar" text action from l10n, a title, a content slot and a primary action at the end, shown over `bgVeu`. (COMP-10)
11. The app SHALL provide an empty state with a 40 px icon, a title in UI 16/600 and one support sentence, without a call-to-action button. (COMP-11)
12. The app SHALL provide a top navigation bar in two modes: back (back icon + previous level name in `accent`) and root (title in `tituloTela` with icon actions on the right). (COMP-12)
13. The app SHALL provide a confirmation dialog with title, description, a destructive action and a "Cancelar" text action from l10n, radius 24 and `shadowErguido`, exposed as an alert dialog to accessibility services. (COMP-13)
14. The app SHALL provide the 10 canvas icons (buscar, ordenar, lixeira, novo, voltar, opções, alça, título, checklist, desenho) on a 24 grid, rendered at 22 px, inheriting the text color. (COMP-14)
15. The components SHALL read colors, text styles, spacing, radii and shadows only from the theme tokens. (COMP-15)
16. Each component SHALL have a widget test, and the `app/.claude/docs/design.md` SHALL map each canvas component to its Dart widget. (COMP-16)

**Independent Test**: Widget tests pump each component inside the app theme and assert semantics, callbacks, disabled behavior and the token values used.

---

### P2: Commit message check

**User Story**: As the developer, I want commit messages checked against Conventional Commits locally and in CI so that history stays consistent.

**Why P2**: Helps every later commit, but nothing in the app depends on it.

**Acceptance Criteria**:

1. The repository SHALL version a POSIX shell `commit-msg` hook in `.githooks/` with no dependency beyond `sh`, `grep` and `sed`. (COMMIT-01)
2. WHEN the first non-comment line of the message matches `<type>[(<scope>)][!]: <description>` with an allowed type and, if present, an allowed scope THEN the hook SHALL exit 0. (COMMIT-02)
3. IF the type is not in `feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert` THEN the hook SHALL exit non-zero and print the expected format and allowed types. (COMMIT-03)
4. IF a scope is present and not in `app, server, docs, infra` THEN the hook SHALL exit non-zero and print the allowed scopes. (COMMIT-04)
5. IF the header is longer than 100 characters or the description is empty THEN the hook SHALL exit non-zero. (COMMIT-05)
6. WHEN the message is a git-generated merge (`Merge …`) or revert (`Revert "…"`) THEN the hook SHALL exit 0. (COMMIT-06)
7. WHEN a push or pull request reaches GitHub THEN a CI job SHALL run the same script on every new commit message and fail IF any message is rejected. (COMMIT-07)
8. The hook SHALL be covered by an automated test of accepted and rejected messages that runs in CI. (COMMIT-08)
9. The `README.md` and the root `CLAUDE.md` SHALL document the convention and the `git config core.hooksPath .githooks` setup. (COMMIT-09)

**Independent Test**: `git commit -m "feature: x"` is rejected locally with the allowed types printed; `git commit -m "feat(app): x"` passes.

---

### P3: Preferences storage

**User Story**: As a user, I want the app to remember device-only UI preferences (the last opened notebook) so that it reopens where I left off.

**Why P3**: The notebook list that consumes it arrives in a later milestone; only the store is built now.

**Acceptance Criteria**:

1. WHEN the app starts THEN `hive_ce` SHALL be initialized and the preferences box opened before the first frame. (PREF-01)
2. The app SHALL expose the preferences store through a Riverpod provider that tests override. (PREF-02)
3. WHEN `lastOpenedNotebookId` is written and the store is reopened from the same storage THEN reading it SHALL return the written value. (PREF-03)
4. WHEN `lastOpenedNotebookId` was never written or was cleared THEN reading it SHALL return `null`. (PREF-04)
5. The preferences store SHALL hold only the `lastOpenedNotebookId` key, and no table or synced data SHALL be written to Hive. (PREF-05)
6. IF the preferences box fails to open THEN the app SHALL start, every read SHALL return `null`, and the box file SHALL NOT be deleted. (PREF-06)

**Independent Test**: Unit test writes, reopens and reads the key in a temp directory; widget test starts the app with a failing store and finds the root `Scaffold`.

---

### P3: License

**User Story**: As a visitor of the repository, I want an explicit license so that I know how the code may be used.

**Why P3**: No code depends on it; it is a one-file change.

**Acceptance Criteria**:

1. The repository root SHALL contain a `LICENSE` file with the MIT license text and the line `Copyright (c) 2026 Jonatas Sennas`. (LIC-01)
2. The `README.md` "License" section SHALL state MIT and link to `LICENSE`, replacing "To be defined". (LIC-02)

**Independent Test**: `head -3 LICENSE` shows "MIT License" and the copyright line; the README link resolves.

---

### P3: Decision records

**User Story**: As a future contributor, I want each decision in this milestone recorded so that I know why it was taken.

**Why P3**: Required by each issue's DoD; written alongside the implementation.

**Acceptance Criteria**:

1. The `docs/adr/` SHALL contain one new ADR, in Portuguese and in the Contexto/Decisão/Consequências format, for each of: lint set, `lib/` structure, Riverpod without codegen, commit convention and check, license, and token mapping with bundled fonts — numbered from 0017. (ADR-01)
2. The `docs/adr/README.md` index SHALL list each new ADR. (ADR-02)

**Independent Test**: `ls docs/adr/001[7-9]* docs/adr/002[0-2]*` lists six files; each is linked from `docs/adr/README.md`.

---

## Edge Cases

- WHEN the device text scale is 2.0 THEN every component SHALL render without a `RenderFlex` overflow error.
- IF the commit message file contains only comment lines (`#`) or is empty THEN the hook SHALL exit non-zero.
- IF `build_runner` fails in CI THEN the app workflow SHALL fail before analyze.
- WHEN a pull request changes both `app/` and `docs/` THEN the app workflow SHALL run once.
- IF a component receives a title longer than its width THEN it SHALL truncate with an ellipsis instead of overflowing.

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| LINT-01 | P1: Lint set | - | Pending |
| LINT-02 | P1: Lint set | - | Pending |
| LINT-03 | P1: Lint set | - | Pending |
| LINT-04 | P1: Lint set | - | Pending |
| LINT-05 | P1: Lint set | - | Pending |
| LINT-06 | P1: Lint set | - | Pending |
| STRUCT-01 | P1: Structure and shell | - | Pending |
| STRUCT-02 | P1: Structure and shell | - | Pending |
| STRUCT-03 | P1: Structure and shell | - | Pending |
| STRUCT-04 | P1: Structure and shell | - | Pending |
| STRUCT-05 | P1: Structure and shell | - | Pending |
| STRUCT-06 | P1: Structure and shell | - | Pending |
| STRUCT-07 | P1: Structure and shell | - | Pending |
| STRUCT-08 | P1: Structure and shell | - | Pending |
| RVP-01 | P1: Riverpod | - | Pending |
| RVP-02 | P1: Riverpod | - | Pending |
| RVP-03 | P1: Riverpod | - | Pending |
| TEST-01 | P1: Test foundation | - | Pending |
| TEST-02 | P1: Test foundation | - | Pending |
| TEST-03 | P1: Test foundation | - | Pending |
| TEST-04 | P1: Test foundation | - | Pending |
| TEST-05 | P1: Test foundation | - | Pending |
| TEST-06 | P1: Test foundation | - | Pending |
| TEST-07 | P1: Test foundation | - | Pending |
| CI-01 | P1: CI | - | Pending |
| CI-02 | P1: CI | - | Pending |
| CI-03 | P1: CI | - | Pending |
| CI-04 | P1: CI | - | Pending |
| CI-05 | P1: CI | - | Pending |
| CI-06 | P1: CI | - | Pending |
| CI-07 | P1: CI | - | Pending |
| CI-08 | P1: CI | - | Pending |
| CI-09 | P1: CI | - | Pending |
| THEME-01 | P2: Theme and tokens | - | Pending |
| THEME-02 | P2: Theme and tokens | - | Pending |
| THEME-03 | P2: Theme and tokens | - | Pending |
| THEME-04 | P2: Theme and tokens | - | Pending |
| THEME-05 | P2: Theme and tokens | - | Pending |
| THEME-06 | P2: Theme and tokens | - | Pending |
| THEME-07 | P2: Theme and tokens | - | Pending |
| THEME-08 | P2: Theme and tokens | - | Pending |
| THEME-09 | P2: Theme and tokens | - | Pending |
| THEME-10 | P2: Theme and tokens | - | Pending |
| COMP-01 | P2: Base components | - | Pending |
| COMP-02 | P2: Base components | - | Pending |
| COMP-03 | P2: Base components | - | Pending |
| COMP-04 | P2: Base components | - | Pending |
| COMP-05 | P2: Base components | - | Pending |
| COMP-06 | P2: Base components | - | Pending |
| COMP-07 | P2: Base components | - | Pending |
| COMP-08 | P2: Base components | - | Pending |
| COMP-09 | P2: Base components | - | Pending |
| COMP-10 | P2: Base components | - | Pending |
| COMP-11 | P2: Base components | - | Pending |
| COMP-12 | P2: Base components | - | Pending |
| COMP-13 | P2: Base components | - | Pending |
| COMP-14 | P2: Base components | - | Pending |
| COMP-15 | P2: Base components | - | Pending |
| COMP-16 | P2: Base components | - | Pending |
| COMMIT-01 | P2: Commit check | - | Pending |
| COMMIT-02 | P2: Commit check | - | Pending |
| COMMIT-03 | P2: Commit check | - | Pending |
| COMMIT-04 | P2: Commit check | - | Pending |
| COMMIT-05 | P2: Commit check | - | Pending |
| COMMIT-06 | P2: Commit check | - | Pending |
| COMMIT-07 | P2: Commit check | - | Pending |
| COMMIT-08 | P2: Commit check | - | Pending |
| COMMIT-09 | P2: Commit check | - | Pending |
| PREF-01 | P3: Preferences | - | Pending |
| PREF-02 | P3: Preferences | - | Pending |
| PREF-03 | P3: Preferences | - | Pending |
| PREF-04 | P3: Preferences | - | Pending |
| PREF-05 | P3: Preferences | - | Pending |
| PREF-06 | P3: Preferences | - | Pending |
| LIC-01 | P3: License | - | Pending |
| LIC-02 | P3: License | - | Pending |
| ADR-01 | P3: Decision records | - | Pending |
| ADR-02 | P3: Decision records | - | Pending |

**Issue map:** #4 → LINT · #5 → STRUCT · #6 → RVP · #7 → TEST · #8 → CI · #9 → COMMIT · #10 → LIC · #11 → THEME, COMP · #12 → PREF · all decision issues → ADR.

**Coverage:** 78 total, 0 mapped to tasks, 78 unmapped ⚠️ (tasks not created yet)

---

## Success Criteria

- [ ] `app/CLAUDE.md` has no remaining "undecided" item among lint set, `lib/` organization and Riverpod style.
- [ ] The app workflow is green on `main` and red on a deliberately broken commit (analyze, format, test or build).
- [ ] A rejected commit message is blocked locally and flagged in CI.
- [ ] Every "Componentes" artboard component in scope renders from theme tokens with a widget test; 0 color literals outside the theme folder.
- [ ] Milestone issues #4–#12 can be closed with their checklists complete.
