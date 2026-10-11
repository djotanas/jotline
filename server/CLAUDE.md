# CLAUDE.md — server (.NET)

> **Fase 2 — ainda não iniciado.** Não crie código aqui enquanto o roadmap estiver na fase 1, salvo pedido explícito.

Backend do Jotline: autoridade das escritas, autorização, convites e anexos. Regras gerais e invariantes no [CLAUDE.md da raiz](../CLAUDE.md); requisitos em [docs/prd/PRD.md](../docs/prd/PRD.md) (§6–§8).

## Stack

- **ASP.NET Core 10**, Minimal APIs, monólito modular (ADR 0007). SDK 10.0.x.
- **Dados:** EF Core 10 + Npgsql sobre Postgres (Supabase).
- **Auth:** Supabase Auth (JWT) — o mesmo token vale para a API e o PowerSync (ADR 0008).
- **Leitura/replicação:** PowerSync Cloud replica o Postgres para o SQLite de cada aparelho, só os cadernos de que o usuário é membro.
- **Anexos:** Supabase Storage com URL pré-assinada emitida pela API; o arquivo não passa pela API.
- **Dev local:** .NET Aspire sobe API, Postgres e PowerSync.
- **Observabilidade:** OpenTelemetry (traces e métricas do sync e da API).
- **Fase 3:** SignalR para avisos leves; tabela `block_history`.

## Comandos

_A definir no scaffold._ O AppHost do Aspire sobe API + Postgres + PowerSync.

## Estrutura

_A definir no scaffold._

## Regras de `POST /sync/upload`

Recebe lotes de operações PUT, PATCH e DELETE vindos da fila do app.

1. **Idempotente:** o mesmo lote pode chegar duas vezes; reenviar não duplica nem corrompe (RNF-03).
2. **Autoriza cada operação** pelo usuário do token e pelo papel no caderno — `viewer` não grava (RNF-07). Toda checagem passa por `INotebookAccess` (RNF-08).
3. **Erro permanente não trava a fila:** a operação vai para a tabela de rejeitados e o app é avisado.
4. **Grava em transação.** A partir da fase 3, registra `block_history`.
5. **Conflito por bloco:** o app envia a `version` em que se baseou; se o servidor tem versão mais nova, cria uma cópia do bloco em vez de sobrescrever (ADR 0006). Só o servidor incrementa `version` (ADR 0013).
6. Edição de quem perdeu acesso ao caderno é rejeitada; o app oferece salvá-la num caderno pessoal (RF-17).

## Outras regras

- IDs vêm do cliente (UUID v7); o servidor não gera IDs de entidades sincronizadas. `Guid.CreateVersion7()` só para entidades do próprio servidor.
- Autoria vem sempre do usuário do token, nunca do payload. O app troca o usuário local anônimo pelo da conta antes do primeiro upload (ADR 0011).
- Convites, aceite e mudança de papel exigem online — o servidor é a autoridade de permissões.
- `INotebookAccess` e as regras de sync por membro têm testes; toda mudança nelas é revisada (risco crítico de vazamento, PRD §11).
