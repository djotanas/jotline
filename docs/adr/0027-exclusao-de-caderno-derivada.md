# 0027 — Exclusão de caderno derivada para páginas e blocos

- **Status:** Aceita
- **Data:** 2026-10-12
- **Decisores:** @jon
- **Relacionados:** ADR 0023; PRD §4 (RF-12), §5 (RNF-05)

## Contexto

O ADR 0023 decidiu que excluir um caderno leva as páginas dele para a lixeira e que restaurar o caderno traz as páginas junto. Faltava definir como isso é gravado e deixou em aberto: uma página excluída sozinha antes do caderno volta junto quando o caderno é restaurado?

## Decisão

1. Excluir um caderno grava só `notebooks.deleted_at`. Nenhuma linha de `pages` ou `blocks` é alterada.
2. As consultas de páginas e blocos escondem as linhas cujo caderno ou página está excluído.
3. Restaurar o caderno limpa só `notebooks.deleted_at`. Voltam as páginas que não foram excluídas por conta própria; a página excluída sozinha antes do caderno continua na lixeira.

Isso responde à primeira questão em aberto do ADR 0023, sem editá-lo.

## Alternativas descartadas

- **Gravar `deleted_at` em todas as páginas e blocos do caderno** — uma exclusão vira milhares de escritas e sincroniza todas elas. Na restauração, não dá para distinguir a página excluída junto com o caderno da excluída antes dele.
- **Restaurar também as páginas excluídas sozinhas** — o usuário recuperaria o que já tinha descartado.

## Consequências

- Excluir e restaurar um caderno é uma escrita só, qualquer que seja o tamanho dele.
- Toda consulta de páginas e blocos precisa juntar o caderno (e a página, no caso dos blocos) para filtrar `deleted_at`.
- Em aberto: as páginas de um caderno excluído aparecem na seção "Páginas" da lixeira? (segunda questão do ADR 0023, tratada com a tela da lixeira, #61).
