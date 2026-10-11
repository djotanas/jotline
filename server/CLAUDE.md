# CLAUDE.md — server (.NET)

> **Phase 2 — not started yet.** Do not create code here while the roadmap is in phase 1, unless explicitly asked.

Jotline backend: write authority, authorization, invites and attachments. General rules and invariants in the [root CLAUDE.md](../CLAUDE.md); requirements in [docs/prd/PRD.md](../docs/prd/PRD.md) (§6–§8).

## Stack

- **ASP.NET Core 10**, Minimal APIs, modular monolith (ADR 0007). SDK 10.0.x.
- **Data:** EF Core 10 + Npgsql on Postgres (Supabase).
- **Auth:** Supabase Auth (JWT) — the same token works for the API and PowerSync (ADR 0008).
- **Read/replication:** PowerSync Cloud replicates Postgres to each device's SQLite, only the notebooks the user is a member of.
- **Attachments:** Supabase Storage with a presigned URL issued by the API; the file does not go through the API.
- **Local dev:** .NET Aspire runs the API, Postgres and PowerSync.
- **Observability:** OpenTelemetry (sync and API traces and metrics).
- **Phase 3:** SignalR for lightweight notifications; `block_history` table.

## Commands

_To be defined in the scaffold._ The Aspire AppHost runs API + Postgres + PowerSync.

## Structure

_To be defined in the scaffold._

## References

Read the doc before touching the topic (ADR 0014).

| When | File |
| --- | --- |
| Implementing or changing `POST /sync/upload` (batch, authorization, rejected operations, conflict) | [`server/.claude/docs/sync-upload.md`](.claude/docs/sync-upload.md) |

## Rules

- IDs come from the client (UUID v7); the server does not generate IDs for synced entities. `Guid.CreateVersion7()` only for the server's own entities.
- Authorship always comes from the token's user, never from the payload. The app replaces the anonymous local user with the account's user before the first upload (ADR 0011).
- Invites, accepting them and role changes require being online — the server is the authority on permissions.
- `INotebookAccess` and the per-member sync rules have tests; every change to them is reviewed (critical leak risk, PRD §11).
