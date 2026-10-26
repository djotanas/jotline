# 0038 — Skills acionadas pelo índice de Referências

- **Status:** Aceita
- **Data:** 2026-10-26
- **Decisores:** @jon
- **Relacionados:** ADR 0014, ADR 0015

## Contexto

A ADR 0014 descartou skills porque "dependem do gatilho da descrição acertar". O índice explícito de Referências é previsível, e o agente lê o doc indicado.

Escrever um teste e2e, porém, é um procedimento: tem passos, um esqueleto de arquivo, regras de determinismo e um roteiro de verificação. Um doc com regras não garante que o procedimento seja seguido, e a comparação com uma skill de e2e de outro projeto mostrou lacunas que o doc de testes não cobria (esqueleto, relógio e ids fixos, caminho de erro).

## Decisão

1. **Um procedimento de trabalho repetível vira uma skill** em `<camada>/.claude/skills/<nome>/SKILL.md`, com o conteúdo em inglês.
2. **A skill é acionada pelo índice, não só pelo gatilho:** a linha da tabela "Quando | Arquivo" da seção "Referências" do `CLAUDE.md` da camada manda invocar a skill (ferramenta Skill) antes da tarefa. O `CLAUDE.md` é sempre carregado, então a execução não depende da descrição acertar. A descrição da skill continua existindo como segunda via.
3. **Regras e material de consulta continuam em docs** (`.claude/docs/<tema>.md`), conforme a ADR 0014. A skill é dona do procedimento e aponta para o doc em vez de repeti-lo.
4. A primeira skill é `create-e2e-test` (`app/.claude/skills/create-e2e-test/`), dona de tudo sobre testes e2e. O doc `testes.md` mantém unit, widget, banco e migração.

## Alternativas descartadas

- **Manter só o doc e ampliá-lo** — não garante que o procedimento seja executado; é o problema que motivou esta ADR.
- **Skill sem linha no índice** — volta a depender só do gatilho da descrição.

## Consequências

- A ADR 0014 continua valendo para todos os temas que são regra ou consulta; esta ADR a complementa apenas para procedimentos, sem substituí-la.
- Toda skill nova ou removida muda a tabela de Referências da camada no mesmo commit.
- Skill e doc podem divergir: ao mudar uma regra de e2e, o lugar é a skill; ao mudar uma regra de unit, widget ou banco, é o `testes.md`.
- Decisão sobre mocks e servidor falso de sync em e2e (fase 2) segue em aberto e exige ADR própria.
