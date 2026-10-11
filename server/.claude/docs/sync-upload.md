# `POST /sync/upload`

Implementation rules for the sync upload endpoint. Index in [server/CLAUDE.md](../../CLAUDE.md); invariants in the [root CLAUDE.md](../../../CLAUDE.md).

Receives batches of PUT, PATCH and DELETE operations from the app's queue.

1. **Idempotent:** the same batch may arrive twice; resending neither duplicates nor corrupts (RNF-03).
2. **Authorizes each operation** by the token's user and their role in the notebook — `viewer` does not write (RNF-07). Every check goes through `INotebookAccess` (RNF-08).
3. **A permanent error does not block the queue:** the operation goes to the rejected table and the app is notified.
4. **Writes in a transaction.** From phase 3 on, records `block_history`.
5. **Per-block conflict:** the app sends the `version` it was based on; if the server has a newer version, it creates a copy of the block instead of overwriting (ADR 0006). Only the server increments `version` (ADR 0013).
6. An edit from someone who lost access to the notebook is rejected; the app offers to save it in a personal notebook (RF-17).
