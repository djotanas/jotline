# 0014 — Progressive disclosure nas instruções do agente

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** ADR 0010

## Contexto

A ADR 0010 dividiu as instruções do agente em `CLAUDE.md` por camada: a raiz em toda sessão, `app/` e `server/` quando o agente trabalha na pasta. Cada camada, porém, é carregada inteira, mesmo quando a tarefa não toca a maior parte do que ela diz.

Exemplos de código, regras de implementação de um tema (um endpoint, uma tabela, um fluxo) e explicações extras só servem à tarefa daquele tema. Mantidos no `CLAUDE.md`, ocupam contexto em toda tarefa da pasta e tendem a crescer conforme o código aparece.

## Decisão

1. **O `CLAUDE.md` de cada camada fica com o que vale para qualquer tarefa nela:** stack, comandos, invariantes em uma linha, avisos de fase e o que não foi decidido.
2. **Detalhe de um tema vai para `<camada>/.claude/docs/<tema>.md`** — exemplos de código, regras de implementação, justificativas e casos de borda. A camada é a pasta da instrução: `.claude/docs/` na raiz para temas dos dois lados, `app/.claude/docs/` e `server/.claude/docs/` para cada lado.
3. **Todo doc é listado numa seção "Referências" do `CLAUDE.md` da mesma camada**, numa tabela "Quando | Arquivo" que diz em que situação lê-lo. O agente lê o doc antes de mexer no tema. Doc sem entrada no índice não existe para o agente.
4. **Um tema por arquivo.** O doc não repete as invariantes do `CLAUDE.md`; aponta para elas se precisar.
5. Os docs são lidos sob demanda, sem importação com `@`, como o PRD.

## Alternativas descartadas

- **Skills (`.claude/skills/<tema>/SKILL.md`)** — carregam sozinhas pelo assunto, mas dependem do gatilho da descrição acertar, e cada tema exige frontmatter e pasta própria. O índice explícito é previsível e verificável.
- **Tudo no `CLAUDE.md`** — o contexto de toda tarefa paga pelo detalhe de todos os temas.

## Consequências

- O `CLAUDE.md` de cada camada fica curto e funciona como índice; o detalhe só entra no contexto quando a tarefa é do tema.
- O agente depende de ler o doc indicado: a linha "Quando" precisa descrever a situação de forma reconhecível.
- Ao adicionar, renomear ou remover um doc, o índice da camada muda no mesmo commit.
- As regras de `POST /sync/upload` saem de `server/CLAUDE.md` para `server/.claude/docs/sync-upload.md`.
