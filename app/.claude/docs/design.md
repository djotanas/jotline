# App design

Where the app layout lives and how to use it. Index in [app/CLAUDE.md](../../CLAUDE.md); invariants in the [root CLAUDE.md](../../../CLAUDE.md).

## Source of truth

The **Jotline design** canvas is the single source of truth for the layout: <https://claude.ai/artifact/4KD28z2NEsVk61M3pRY7H8>. If the code and the canvas diverge, the canvas wins.

Page and artboard names are kept as they appear in the canvas (in Portuguese).

| Page | Artboards |
| --- | --- |
| Marca | Logo final · Ícone em uso |
| Design system | Fundamentos e cores · Tipografia · Espaço, forma, elevação e ícones · Componentes · Padrões de estado e sync |
| Fase 1 — telas | Cadernos (RF-01) · Novo caderno: capa e cor (RF-01) · Páginas do caderno (RF-02) · Opções do caderno (RF-01) · Editor de blocos (RF-03, RF-06) · Opções da página (RF-12) · Página excluída: desfazer (RF-12) · Busca local (RF-05) · Lixeira local (RF-12) |

Each artboard is a canvas file `project/<Name>.dc.html` (e.g. `project/Fundamentos.dc.html`); the tokens and values are in it.

## Rules

- **Colors, typography, spacing, radii, shadows, icons and screens come from the canvas.** Do not invent values outside it, not even temporary ones.
- **Something missing from the canvas** (a state, a screen, a token)? Ask before implementing.
- **The Flutter theme mirrors the design system tokens under the same names** — `bg.mesa`, `ink.1`, `accent`, `accent.traco` etc., in camelCase (below) — and lives in a single place. Screens and widgets use the theme, never a literal value.

## Theme in code (ADR 0022)

- **Location:** `lib/core/theme/`, the only folder allowed to hold `Color(`, `Colors.` or `fontFamily:`. A test in `test/core/theme/jot_theme_test.dart` scans `lib/` and fails on any of them elsewhere.
- **Where each token lives:** colors in `JotColors`, text styles in `JotTextStyles`, shadows in `JotShadows` (all `ThemeExtension`s, registered by `buildJotTheme()`); spacing in `JotSpace` and radii in `JotRadius` (`static const`).
- **Reading tokens:** `context.colors.bgMesa`, `context.textStyles.tituloTela`, `context.shadows.capa` (`theme_context.dart`); `JotSpace.space4`, `JotRadius.rCard`.
- **Dotted name → Dart identifier:** flat camelCase of the canvas name: `bg.mesa` → `bgMesa`, `ink.1` → `ink1`, `accent.traco` → `accentTraco`, `r.capa` → `rCapa`, `space.4` → `space4`. Shadows drop the group prefix inside `JotShadows`: `shadow.capa` → `capa`.
- **Notebook palette:** `NotebookColor` (`azulTinta`, `terracota`, `musgo`, `mostarda`, `ameixa`, `grafite`) and `CoverPattern` (`lisa`, `pautada`, `pontilhada`, `quadriculada`) in `notebook_palette.dart`, with the spine, elastic and pattern values in `NotebookCoverPaint`. These identifiers are persisted from milestone #02: never rename them without a migration. Display names come from l10n (`notebookColorAzulTinta`, `coverPatternPontilhada` → "Pontos", ...).
- **Fonts:** bundled from `google/fonts` in `assets/fonts/<family>/` with their `OFL.txt`, registered by `registerFontLicenses()`. No `google_fonts` package (it downloads over the network). Families: `JotTextStyles.fontUi` (Schibsted Grotesk), `fontTexto` (Literata, with `FontVariation.opticalSize`), `fontMeta` (IBM Plex Mono).

## Components in code

Every in-scope component of the canvas "Componentes" artboard lives in `lib/core/design_system/`, one widget per file, with its widget test mirrored under `test/core/design_system/`. Screens build from these widgets instead of recreating them. Generic widgets use the `Jot` prefix; notebook and page widgets use domain names.

| Canvas component | Dart widget | File |
| --- | --- | --- |
| Botões — primário, destrutivo, pílula secundária, texto | `JotButton.primary` / `.destructive` / `.pill` / `.text` | `jot_button.dart` |
| Botões — flutuante (FAB) | `JotFab` | `jot_fab.dart` |
| Botões — ícone | `JotIconButton` | `jot_icon_button.dart` |
| Segmentado | `JotSegmentedControl<T>` + `JotSegment<T>` | `jot_segmented_control.dart` |
| Campo (com limite, contador "N/50", dica e ajuda) | `JotTextField` | `jot_text_field.dart` |
| Campo de busca | `JotSearchField` | `jot_search_field.dart` |
| Capa de caderno | `NotebookCover` (`.mini` for swatches), painted by `NotebookCoverPainter` | `notebook_cover.dart` |
| Capa + título + meta (grade) | `NotebookCoverTile` | `notebook_cover_tile.dart` |
| Cor e capa — cor | `NotebookColorPicker` | `notebook_color_picker.dart` |
| Cor e capa — capa | `NotebookCoverPicker` | `notebook_cover_picker.dart` |
| Linhas de lista — página | `PageRow` | `page_row.dart` |
| Linhas de lista — página arrastando | `DraggingPageRow` | `dragging_page_row.dart` |
| Linhas de lista — caderno arquivado ou na lixeira | `ArchivedNotebookRow` | `archived_notebook_row.dart` |
| Bottom sheet | `showJotBottomSheet<T>()` → `JotBottomSheet` | `jot_bottom_sheet.dart` |
| Aviso de desfazer (3 s, pausa ao segurar) | `JotUndoToast` | `jot_undo_toast.dart` |
| Diálogo de texto (renomear, limite 50) | `showTextInputDialog()` → `JotTextInputDialog` | `jot_text_input_dialog.dart` |
| Selo "Arquivado" (tokens `rSelo` 6 e `selo`) | `JotBadge` | `jot_badge.dart` |
| Estado vazio | `EmptyState` | `empty_state.dart` |
| Navegação de topo | `JotTopBar.back` / `JotTopBar.root` | `jot_top_bar.dart` |
| Bottom sheet de opções (grupos em cards, linha destrutiva ou marcada) | `showJotOptionsSheet<T>()` → `JotOptionsSheet<T>` + `JotOptionRow<T>` | `jot_options_sheet.dart` |
| Diálogo de confirmação | `showConfirmDialog()` → `ConfirmDialog` | `confirm_dialog.dart` |
| Ícones ("Espaço, forma, elevação e ícones") | `JotIcon` + `JotIconGlyph` (with `edit`, `cover`, `archive`, `unarchive`, `check`, `page`, `notebook`) | `icons/jot_icon.dart` |

**Out of scope until the block editor ADR:** "Blocos do editor" and "Barra de blocos". They are the visual layer of the editor library still in spike (PRD §11) and are built after that decision.
