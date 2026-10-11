# Library documentation (Context7)

How to fetch library and API documentation with the Context7 MCP. Index in the [root CLAUDE.md](../../CLAUDE.md).

## When

Use Context7 automatically, without the user asking, whenever the task involves:

- generating code that uses a library, framework, SDK or API (Flutter, Riverpod, Drift, PowerSync, ASP.NET Core, EF Core, Npgsql and the like);
- setup or configuration steps (packages, code generation, build, CLI tools, cloud services);
- questions about a library's API, syntax, configuration, version migration or library-specific errors.

Use it even when the answer seems known: training data may be behind the versions in use.

Do not use it for refactoring, scripts written from scratch, business logic debugging, code review or general programming concepts.

## Steps

1. `resolve-library-id` with the library name and what to look up, unless the `/org/project` ID is already known.
2. Pick the best match: exact name, description relevance, snippet count, source reputation (High/Medium), benchmark score. If nothing fits, retry with another name or phrasing (`next.js`, not `nextjs`).
3. `query-docs` with the chosen ID and a question scoped to a single concept. Several concepts → one call per concept with the same ID, unless the question is about how they interact.
4. Answer and write code based on the fetched docs.

## Versions

Use the version the project actually uses, not the latest:

- `app/`: `pubspec.yaml` (constraint) and `pubspec.lock` (resolved version).
- `server/`: the `.csproj` files (from phase 2).

When Context7 offers version-specific IDs, pick the one matching that version. If the docs found are for a different major version than the project's, say so before using them.

## Rules

- **Docs from Context7 do not override the project's invariants and ADRs.** If a library's recommended pattern conflicts with them (e.g. a screen calling the PowerSync SDK directly), the project wins.
- **Context7 found nothing, or the docs contradict the code in use?** Say so and ask; do not fill the gap from memory.
