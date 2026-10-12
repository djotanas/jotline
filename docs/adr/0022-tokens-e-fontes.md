# 0022 — Tokens do tema e fontes empacotadas

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** ADR 0016, ADR 0018, RNF-01

## Contexto

O canvas "Jotline design" define os tokens do design system com nomes pontuados em português (`bg.mesa`, `ink.1`, `accent.traco`, `shadow.capa`), além de seis cores e quatro capas de caderno com nome mas sem token. O `app/.claude/docs/design.md` exigia que o tema Flutter espelhasse esses nomes num lugar só, mas deixava em aberto onde ficaria o arquivo, como um nome pontuado vira identificador Dart e como identificar a paleta de cadernos.

As três famílias do canvas (Schibsted Grotesk, Literata e IBM Plex Mono) não vêm com o Flutter. O pacote `google_fonts` baixa as fontes por HTTP em tempo de execução, o que contradiz o RNF-01: nenhuma tela depende da rede.

## Decisão

- **Local:** todo o tema mora em `lib/core/theme/`, a única pasta do `lib/` que pode ter literal de cor, de família de fonte ou de estilo. Um teste varre o `lib/` e falha se encontrar `Color(`, `Colors.` ou `fontFamily:` fora dela (THEME-09).
- **Forma:** cores, estilos de texto e sombras ficam em três `ThemeExtension` (`JotColors`, `JotTextStyles`, `JotShadows`), registradas em `buildJotTheme()` e lidas com `context.colors`, `context.textStyles` e `context.shadows`. Espaçamentos e raios são `static const` em `JotSpace` e `JotRadius`, para funcionar em widgets `const`.
- **Nomes:** o nome pontuado do canvas vira camelCase plano: `bg.mesa` → `bgMesa`, `ink.1` → `ink1`, `accent.traco` → `accentTraco`, `r.capa` → `rCapa`, `space.4` → `space4`. Nas sombras, o prefixo do grupo cai porque a classe já o diz: `shadow.capa` → `JotShadows.capa`.
- **Paleta de cadernos:** `enum NotebookColor { azulTinta, terracota, musgo, mostarda, ameixa, grafite }` com o valor de cada cor, `enum CoverPattern { lisa, pautada, pontilhada, quadriculada }` e `NotebookCoverPaint` com a geometria da lombada, do elástico e dos padrões. Os identificadores repetem os nomes do canvas e são estáveis: o milestone #02 os grava em `notebooks.color` e `notebooks.cover`. O nome exibido vem do l10n.
- **Fontes:** os arquivos vêm do repositório `google/fonts` e vão como assets em `app/assets/fonts/<família>/`. Schibsted Grotesk e Literata usam os TTF variáveis (o `FontWeight` controla o eixo `wght`); IBM Plex Mono usa os TTF estáticos 400 e 500. Os estilos em Literata aplicam `FontVariation.opticalSize` com o próprio tamanho. A licença OFL de cada família é registrada no `LicenseRegistry` ao iniciar o app. Sem `google_fonts`.

## Alternativas descartadas

- **Pacote `google_fonts`** — baixa as fontes pela rede na primeira vez; só funciona offline se as fontes forem empacotadas de qualquer jeito, e aí o pacote não acrescenta nada.
- **Só `ColorScheme` e `TextTheme` do Material** — os 20 tokens de cor e os 12 estilos não cabem nos papéis do Material sem perder os nomes do canvas, que é a fonte da verdade.
- **Tudo como constantes globais** — mais simples hoje, mas um tema escuro futuro exigiria trocar cada uso. Com `ThemeExtension`, o segundo tema é uma nova instância.
- **Mapa de tokens por nome pontuado (`tokens['bg.mesa']`)** — mantém o nome exato do canvas, mas troca erro de compilação por erro em tempo de execução.

## Consequências

- Uma tela ou componente nunca escreve uma cor ou fonte literal; o teste de varredura quebra o build se isso acontecer.
- Um tema escuro futuro cria novas instâncias das três extensões, sem mudar quem as lê. Espaçamentos e raios não mudam com o tema.
- Mudar um token exige editar a tabela da spec, a extensão e o teste que confere o valor.
- Renomear uma cor ou capa de caderno depois do #02 exige migração de dados.
- O app cresce cerca de 2,3 MB com as fontes, e as licenças OFL aparecem na tela de licenças.
