<div align="center">
  <img src="docs/assets/icon.svg" alt="Jotline" width="160">
  <h1>Jotline</h1>
  <p><em>Your ideas and plans, anywhere you want — even offline.</em></p>

  <img src="https://skillicons.dev/icons?i=flutter,dart,sqlite,dotnet,cs,postgres,supabase" alt="Flutter, Dart, SQLite, .NET, C#, Postgres, Supabase">

  <p>
    <a href="#about">About</a> •
    <a href="#status">Status</a> •
    <a href="#stack">Stack</a> •
    <a href="#repository">Repository</a> •
    <a href="#getting-started">Getting started</a> •
    <a href="#docs">Docs</a> •
    <a href="#license">License</a> •
    <a href="#contact-me">Contact me</a>
  </p>
</div>

## About

Jotline is a mobile note-taking app organized in notebooks, built **offline-first**: it works entirely without internet and syncs on its own when the connection comes back. The device is the source of truth for whoever is writing; the cloud is a backup and a bridge between devices and, later, between people.

> _Jotline_ is a working name.

## Status

**Phase 1** — app only, local, no account and no server.

| Phase | Scope | Gate to the next phase |
| --- | --- | --- |
| 1 | Local app: notebooks, pages and blocks on SQLite | Editor spike done, schema with members and blocks closed, no data loss in internal use |
| 2 | Account, server and sync across devices | No stale items in the upload queue in field tests, authorization covered by tests, migration of pre-login data validated |
| 3 | Sharing, roles and version history | Per-block conflict metrics and explicit co-editing requests justify the cost of a CRDT |
| 4 _(conditional)_ | Real-time co-editing on the same block (CRDT) | — |

Progress is tracked in the [milestones](https://github.com/djotanas/jotline/milestones).

## Stack

| Layer | Technology | Phase |
| --- | --- | --- |
| App | Flutter (via FVM, 3.47.5) + Riverpod | 1 |
| Local database | SQLite with Drift | 1 |
| Preferences | hive_ce | 1 |
| Block editor | TBD (spike) | 1 |
| Backend | ASP.NET Core 10 | 2 |
| Data access | EF Core 10 + Postgres (Supabase) | 2 |
| Auth | Supabase Auth | 2 |
| Sync | PowerSync | 2 |
| Local dev | .NET Aspire | 2 |
| Observability | OpenTelemetry | 2 |

## Repository

```
app/        Flutter app (Riverpod + Drift/SQLite)       · phase 1
server/     ASP.NET Core 10 + Postgres + PowerSync      · phase 2
docs/prd/   product requirements, data model, sync, roadmap
docs/adr/   architecture decision records
```

## Getting started

### Requirements

- [Git](https://git-scm.com/)
- [FVM](https://fvm.app/) (installs the Flutter version pinned in `app/.fvmrc`)
- [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/)

### Commit convention

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/): `<type>[(<scope>)][!]: <description>`. Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Allowed scopes (optional): `app`, `server`, `docs`, `infra`.

```bash
git config core.hooksPath .githooks
```

This points git at the versioned `commit-msg` hook, which rejects a message that doesn't match the convention before it is committed. The same check runs again in CI on every push and pull request.

### Running the app

```bash
git clone https://github.com/djotanas/jotline.git
cd jotline/app
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run
```

> The `server/` starts in phase 2; there is nothing to run there yet.

## Docs

- [Product requirements (PRD)](docs/prd/PRD.md) — in Portuguese
- [Architecture decision records](docs/adr/)

## License

MIT — see [LICENSE](LICENSE).

## Contact me

> GitHub [@djotanas](https://github.com/djotanas) &nbsp;·&nbsp;
> Email [sennasjonatas@gmail.com](mailto:sennasjonatas@gmail.com) &nbsp;·&nbsp;
> LinkedIn [Jonatas Sennas](https://www.linkedin.com/in/jonatassennas/)
