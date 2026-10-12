# 0020 — Convenção e verificação de mensagens de commit

- **Status:** Aceita
- **Data:** 2026-10-11
- **Decisores:** @jon
- **Relacionados:** ADR 0010

## Contexto

O histórico do repo já tinha commits em formatos diferentes (`docs(prd): lixeira local…`, `build(app): …`), sem nenhuma checagem automática. O repo é um monorepo Flutter/.NET sem Node instalado por padrão, e commits de documentação (ADRs, specs) vão direto para `main` (ver memória do usuário), então a checagem não pode depender só de CI: precisa rodar localmente antes do commit existir.

## Decisão

Mensagens seguem Conventional Commits: `tipo(escopo)!: descrição`, tipos `feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert`, escopo opcional entre `app, server, docs, infra`, cabeçalho até 100 caracteres, descrição não vazia. A checagem roda em dois lugares com o mesmo script: um hook `commit-msg` em `.githooks/` (POSIX `sh`, só `sh`/`grep`/`sed`, sem Node) que cada clone ativa com `git config core.hooksPath .githooks`, e um job de CI que repete a checagem em cada commit novo de um push ou PR. Mensagens de merge e revert geradas pelo git passam direto.

## Alternativas descartadas

- **lefthook** — gerenciador de hooks multi-linguagem, mas é mais uma dependência binária para instalar e manter versionada num repo que ainda não tem nenhum gerenciador de hooks.
- **commitlint + husky** — padrão no ecossistema Node, mas o repo é Flutter/.NET; exigiria instalar Node só para checar mensagens de commit.
- **Checagem só em CI** — não impede o commit malformado localmente, e commits de documentação vão direto para `main` sem passar por PR, perdendo a rede de segurança do CI.

## Consequências

- Todo clone precisa rodar `git config core.hooksPath .githooks` uma vez; documentado no `README.md`.
- O hook e o script de CI compartilham a mesma lógica de checagem, evitando que os dois divirjam.
- `docs(prd): …` do histórico anterior a este ADR não é corrigido retroativamente; a CI só valida commits novos.
- Mensagens continuam em português; o hook checa só a estrutura, não o idioma da descrição.
