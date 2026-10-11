# `POST /sync/upload`

Regras de implementação do endpoint de upload do sync. Índice em [server/CLAUDE.md](../../CLAUDE.md); invariantes no [CLAUDE.md da raiz](../../../CLAUDE.md).

Recebe lotes de operações PUT, PATCH e DELETE vindos da fila do app.

1. **Idempotente:** o mesmo lote pode chegar duas vezes; reenviar não duplica nem corrompe (RNF-03).
2. **Autoriza cada operação** pelo usuário do token e pelo papel no caderno — `viewer` não grava (RNF-07). Toda checagem passa por `INotebookAccess` (RNF-08).
3. **Erro permanente não trava a fila:** a operação vai para a tabela de rejeitados e o app é avisado.
4. **Grava em transação.** A partir da fase 3, registra `block_history`.
5. **Conflito por bloco:** o app envia a `version` em que se baseou; se o servidor tem versão mais nova, cria uma cópia do bloco em vez de sobrescrever (ADR 0006). Só o servidor incrementa `version` (ADR 0013).
6. Edição de quem perdeu acesso ao caderno é rejeitada; o app oferece salvá-la num caderno pessoal (RF-17).
