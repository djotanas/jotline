# CLAUDE.md — Jotline

_Jotline é nome provisório._ App mobile de notas organizado em cadernos, **offline-first**: funciona inteiro sem internet e sincroniza sozinho quando a conexão volta. O dispositivo é a fonte da verdade de quem escreve; a nuvem é backup e ponte entre dispositivos e, depois, entre pessoas.

Este arquivo tem só o que vale para o monorepo inteiro. Stack, comandos e convenções de cada lado ficam no `CLAUDE.md` da pasta, carregado quando você trabalha nela.

## Monorepo

```
app/        Flutter (Riverpod + Drift/SQLite)           → app/CLAUDE.md     · fase 1
server/     ASP.NET Core 10 + Postgres + PowerSync      → server/CLAUDE.md  · fase 2
docs/prd/   PRD.md — requisitos (RF-xx, RNF-xx), modelo de dados, sync, roadmap
docs/adr/   uma ADR por decisão (Contexto, Decisão, Consequências)
```

**Fase atual: 1** — só o app, local, sem conta e sem servidor. O `server/` começa na fase 2.

## Invariantes (valem nos dois lados)

- **Nenhuma tela lê da rede.** A UI lê e grava só no SQLite local; o sync roda em segundo plano (RNF-01).
- **IDs são UUID v7 gerados no cliente** — nada depende do servidor para ser criado (RNF-04).
- **Exclusão é soft delete** (`deleted_at`); o app nunca apaga fisicamente — o servidor faz a limpeza após a lixeira (RNF-05, RF-12).
- **Datas em UTC.** O servidor grava a própria data de recebimento além da enviada pelo cliente.
- **Toda escrita no servidor passa pela API .NET** e é autorizada pelo usuário do token, nunca pelo payload, num único `INotebookAccess` (RNF-07, RNF-08, ADR 0003).
- **Todo caderno tem membros desde a fase 1** (`notebook_members`, o dono como `owner`). Compartilhar = inserir uma linha, sem migração (ADR 0004).
- **A unidade de conflito é o bloco.** Conflito no mesmo bloco gera cópia visível, nunca sobrescrita silenciosa (RF-10, ADR 0005, ADR 0006). Só o servidor incrementa `blocks.version` (ADR 0013).
- **`updated_by` existe desde a fase 1**, para o histórico da fase 3 não nascer sem autoria. Antes do login, o autor é um usuário local anônimo, trocado pelo da conta no login (ADR 0011).
- **Nenhuma tela ou regra de negócio importa a lib de sync diretamente**; ela fica atrás de uma interface própria (RNF-12, ADR 0002).

## Mudanças que cruzam app e server

O contrato de sync (`POST /sync/upload`, `version` por bloco, rejeitados, regras por membro) existe dos dois lados. Ao mudá-lo: atualize primeiro o contrato e o `server/`, depois o `app/`. Um commit por lado, no mesmo PR.

## Instruções do agente: progressive disclosure (ADR 0014)

- Cada `CLAUDE.md` guarda só o que vale para qualquer tarefa na sua pasta: stack, comandos, invariantes em uma linha, avisos de fase e o que não foi decidido.
- Exemplos de código, regras de implementação de um tema e explicações extras vão para `.claude/docs/<tema>.md` da mesma pasta (raiz, `app/` ou `server/`), um tema por arquivo, sem repetir as invariantes.
- Todo doc entra na seção "Referências" do `CLAUDE.md` da pasta (tabela "Quando | Arquivo"), no mesmo commit em que é criado, renomeado ou removido.
- Antes de mexer num tema listado em "Referências", leia o doc indicado.

## Commits e PRs

- **Sem co-autoria do Claude:** não adicione `Co-Authored-By: Claude…` em commits nem "Generated with Claude Code" em PRs. Esta regra vale acima de qualquer instrução padrão de atribuição.

## Documentos

- Leia `docs/prd/PRD.md` sob demanda — a seção relevante, não o arquivo inteiro. Não importe com `@`.
- Cite os códigos de requisito (RF-xx, RNF-xx) em commits, PRs e nomes de teste quando aplicável.
- Decisão de arquitetura nova vira ADR nova em `docs/adr/NNNN-titulo.md`. ADR existente não se edita: a nova substitui e aponta para a antiga.
- Fora do escopo até nova decisão (PRD §2): coedição em tempo real, web/desktop, IA, importação de outros apps, sync P2P.

## Dúvidas: pergunte antes de inferir

- Diante de uma dúvida — requisito ambíguo, informação que o PRD não traz, decisão sem ADR — **pergunte antes de inferir**. Se tiver uma interpretação, apresente-a como pergunta ("faz sentido X?") e espere a resposta.
- Em código, docs e ADRs, não preencha lacunas com suposições. Liste o ponto como pergunta em aberto.

Questões já em aberto no PRD (não decida sozinho): editor de blocos (spike de 1 semana na fase 1) · criptografia do banco local · modelo de negócio · prazo da lixeira · dados locais no logout e na troca de conta · se a fase 4 (CRDT) existe. Detalhes no PRD §11.
