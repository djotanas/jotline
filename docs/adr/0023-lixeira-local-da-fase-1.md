# 0023 — Lixeira local da fase 1: caderno leva as páginas, sem esvaziar

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** PRD §4 (RF-12), §5 (RNF-05), §11

## Contexto

Na fase 1 a lixeira (RF-12) existe só no aparelho: lista o que tem `deleted_at` preenchido e restaura limpando a coluna. O PRD deixou em aberto (§11) o que acontece com as páginas quando um caderno é excluído e se existe "esvaziar lixeira" na fase 1, sabendo que o app nunca apaga fisicamente (RNF-05).

## Decisão

1. Excluir um caderno **leva as páginas dele para a lixeira**, e restaurar o caderno traz as páginas junto.
2. Na fase 1 **não existe "esvaziar lixeira"**.

## Alternativas descartadas

- **Páginas ficarem órfãs fora da lixeira** — continuariam visíveis sem o caderno a que pertencem.
- **Um "esvaziar" que só esconde os itens** — prometeria uma exclusão que não acontece, já que pelo RNF-05 o app nunca apaga.

## Consequências

- A limpeza definitiva continua só com o servidor, a partir da fase 2.
- Em aberto: uma página excluída sozinha antes do caderno volta junto quando o caderno é restaurado?
- Em aberto: as páginas de um caderno excluído aparecem também na seção "Páginas" da lixeira?
