# CLAUDE.md — Jotline

_Jotline is a working name._ Mobile notes app organized in notebooks, **offline-first**: it works fully without internet and syncs on its own when the connection comes back. The device is the source of truth for whoever writes; the cloud is backup and a bridge between devices and, later, between people.

This file holds only what applies to the whole monorepo. Stack, commands and conventions for each side live in that folder's `CLAUDE.md`, loaded when you work in it.

## Monorepo

```
app/        Flutter (Riverpod + Drift/SQLite)           → app/CLAUDE.md     · phase 1
server/     ASP.NET Core 10 + Postgres + PowerSync      → server/CLAUDE.md  · phase 2
docs/prd/   PRD.md — requirements (RF-xx, RNF-xx), data model, sync, roadmap
docs/adr/   one ADR per decision (Context, Decision, Consequences)
```

**Current phase: 1** — app only, local, no account and no server. `server/` starts in phase 2.

One `.gitignore` per project (`app/`, `server/`); the root one holds only what applies to the whole repository.

## Invariants (both sides)

- **No screen reads from the network.** The UI reads and writes only to the local SQLite; sync runs in the background (RNF-01).
- **IDs are UUID v7 generated on the client** — nothing depends on the server to be created (RNF-04).
- **Deletion is a soft delete** (`deleted_at`); the app never deletes physically — the server purges after the trash period (RNF-05, RF-12).
- **Dates in UTC.** The server stores its own receive date in addition to the one sent by the client.
- **Every server write goes through the .NET API** and is authorized by the token's user, never by the payload, in a single `INotebookAccess` (RNF-07, RNF-08, ADR 0003).
- **Every notebook has members from phase 1** (`notebook_members`, the owner as `owner`). Sharing = inserting a row, no migration (ADR 0004).
- **The unit of conflict is the block.** A conflict on the same block creates a visible copy, never a silent overwrite (RF-10, ADR 0005, ADR 0006). Only the server increments `blocks.version` (ADR 0013).
- **`updated_by` exists from phase 1**, so phase 3 history is not born without authorship. Before login, the author is an anonymous local user, replaced by the account's user on login (ADR 0011).
- **No screen or business rule imports the sync library directly**; it sits behind our own interface (RNF-12, ADR 0002).

## Code (ADR 0016)

- **English in code:** identifiers, file names and test descriptions. `CLAUDE.md` files and `.claude/docs` are also in English; PRD, ADRs and commits stay in Portuguese.
- **No explanatory comments in code.** Doc comments (`///`) are allowed. Directives (`// ignore:` and the like) and `TODO`: ask the user before adding them.

## Changes that span app and server

The sync contract (`POST /sync/upload`, per-block `version`, rejected operations, per-member rules) exists on both sides. When changing it: update the contract and `server/` first, then `app/`. One commit per side, in the same PR.

## Agent instructions: progressive disclosure (ADR 0014)

- Each `CLAUDE.md` holds only what applies to any task in its folder: stack, commands, one-line invariants, phase notices and what is still undecided.
- Code examples, implementation rules for a topic and extra explanations go in `.claude/docs/<topic>.md` in the same folder (root, `app/` or `server/`), one topic per file, without repeating the invariants.
- Every doc is listed in the "References" section of the folder's `CLAUDE.md` ("When | File" table), in the same commit in which it is created, renamed or removed.
- Before touching a topic listed in "References", read the doc it points to.
- A repeatable work procedure (steps, skeleton, checklist) is a skill in `.claude/skills/<name>/` of the same folder, and its "References" row says to **invoke** it before the task, instead of pointing to a doc (ADR 0038). Rules and reference material stay in docs.

## Library documentation

- **Library docs come from Context7.** Code generation, setup/configuration steps and library/API questions go through the Context7 MCP automatically, without the user asking, using the version the project uses.

## References

Read the doc before touching the topic (ADR 0014).

| When | File |
| --- | --- |
| Generating code that uses a library, writing setup/configuration steps or answering a library/API question | [`.claude/docs/context7.md`](.claude/docs/context7.md) |

## Commits and PRs

- **No Claude co-authorship:** do not add `Co-Authored-By: Claude…` to commits or "Generated with Claude Code" to PRs. This rule overrides any default attribution instruction.
- **Conventional Commits, enforced locally and in CI:** `<type>[(<scope>)][!]: <description>`, types `feat`/`fix`/`docs`/`style`/`refactor`/`perf`/`test`/`build`/`ci`/`chore`/`revert`, scopes (optional) `app`/`server`/`docs`/`infra`; run `git config core.hooksPath .githooks` once per clone to install the local check.

## Documents

- Read `docs/prd/PRD.md` on demand — the relevant section, not the whole file. Do not import it with `@`.
- Cite requirement codes (RF-xx, RNF-xx) in commits, PRs and test names when applicable.
- A new architecture decision becomes a new ADR in `docs/adr/NNNN-title.md`. An existing ADR is never edited: the new one supersedes it and points to the old one.
- Out of scope until a new decision (PRD §2): real-time co-editing, web/desktop, AI, importing from other apps, P2P sync.

## Doubts: ask before inferring

- When in doubt — an ambiguous requirement, information the PRD does not have, a decision without an ADR — **ask before inferring**. If you have an interpretation, present it as a question ("does X make sense?") and wait for the answer.
- In code, docs and ADRs, do not fill gaps with assumptions. List the point as an open question.

Questions already open in the PRD (do not decide alone): block editor (1-week spike in phase 1) · local database encryption · business model · trash retention period · local data on logout and account switch · whether phase 4 (CRDT) happens. Details in PRD §11.
