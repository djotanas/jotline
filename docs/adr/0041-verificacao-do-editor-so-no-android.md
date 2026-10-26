# 0041 — Verificação do editor só no Android físico no Gate 1

- **Status:** Aceita
- **Data:** 2026-10-23
- **Decisores:** @jon
- **Relacionados:** ADR 0035; issue #67; spec da M05 (GATE-03, GATE-06)

## Contexto

O GATE-03 pede os resultados da lista de verificação manual do editor (#67, SPIKE-06) em um iPhone e em um Android físico. O teste cobre o teclado do sistema (acentos, autocorreção, cursor flutuante, ditado) e não pode ser emulado: o ambiente de desenvolvimento é Linux/WSL, sem simulador de iOS, e o comportamento depende do teclado real. O decisor não tem um iPhone nem um Mac.

## Decisão

1. **No Gate 1, a lista do #67 é executada apenas no Android físico** (Samsung SM-A356E, Gboard pt-BR). O GATE-03 passa a exigir o resultado desse aparelho.
2. **Os itens exclusivos do iOS ficam sem verificação** no Gate 1: acento por arrastar a tecla `e` (item 2, parte iOS), cursor flutuante pela barra de espaço (item 4) e ditado (item 9). O `gate-1.md` os lista como "não verificados no iOS", sem marcá-los como aprovados.
3. **A ADR 0035 (`super_editor`) continua em vigor.** O GATE-06 vale para o Android: se algum item falhar, uma nova ADR substitui a 0035 antes de o Gate 1 passar.
4. **A verificação no iOS é obrigatória antes de qualquer build para iOS ser distribuído** (TestFlight ou loja), em um iPhone real com a mesma lista.

## Alternativas descartadas

- **Manter o critério e deixar o Gate 1 não atendido:** bloquearia a fase 2 por um aparelho que o projeto não tem, sem que a fase 2 dependa do iOS.
- **Simular o teclado iOS em testes automáticos:** não reproduz o comportamento do teclado real, que é o objeto do teste.

## Consequências

- Existe risco aceito de o `super_editor` ter falhas de entrada de texto no iOS que só aparecem no primeiro build para iPhone.
- O Gate 1 pode passar sem evidência do iOS; o `gate-1.md` registra a lacuna e aponta esta ADR.
- A lista do #67 no roteiro `docs/gates/uso-interno.md` passa a ter um aparelho, com os itens do iOS marcados como pendentes.
