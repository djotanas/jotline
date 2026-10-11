# Design do app

Onde está e como usar o layout do app. Índice em [app/CLAUDE.md](../../CLAUDE.md); invariantes no [CLAUDE.md da raiz](../../../CLAUDE.md).

## Fonte da verdade

O canvas **Jotline design** é a única fonte da verdade do layout: <https://claude.ai/artifact/4KD28z2NEsVk61M3pRY7H8>. Se o código e o canvas divergirem, vale o canvas.

| Página | Artboards |
| --- | --- |
| Marca | Logo final · Ícone em uso |
| Design system | Fundamentos e cores · Tipografia · Espaço, forma, elevação e ícones · Componentes · Padrões de estado e sync |
| Fase 1 — telas | Cadernos (RF-01) · Novo caderno: capa e cor (RF-01) · Páginas do caderno (RF-02) · Opções do caderno (RF-01) · Editor de blocos (RF-03, RF-06) · Opções da página (RF-12) · Página excluída: desfazer (RF-12) · Busca local (RF-05) · Lixeira local (RF-12) |

Cada artboard é um arquivo `project/<Nome>.dc.html` do canvas (ex.: `project/Fundamentos.dc.html`); os tokens e valores estão nele.

## Regras

- **Cores, tipografia, espaçamento, raios, sombras, ícones e telas vêm do canvas.** Não invente valores fora dele, nem provisórios.
- **Faltou algo no canvas** (um estado, uma tela, um token)? Pergunte antes de implementar.
- **O tema Flutter espelha os tokens do design system pelos mesmos nomes** — `bg.mesa`, `ink.1`, `accent`, `accent.traco` etc. — e fica num lugar só. Telas e widgets usam o tema, nunca um valor literal.

## Em aberto

- Arquivo do tema: depende da organização de `lib/`, ainda não decidida.
- Como os nomes com ponto (`bg.mesa`) viram identificadores Dart.
- As seis cores de caderno (RF-01) têm nome no canvas, mas não token.
