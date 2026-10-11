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
- **The Flutter theme mirrors the design system tokens under the same names** — `bg.mesa`, `ink.1`, `accent`, `accent.traco` etc. — and lives in a single place. Screens and widgets use the theme, never a literal value.

## Open

- Theme file: depends on the `lib/` organization, still undecided.
- How dotted names (`bg.mesa`) become Dart identifiers.
- The six notebook colors (RF-01) have names in the canvas, but no token.
