# LESSONS - auto-maintained by scripts/lessons.py

> Machine-owned. Do NOT hand-edit. Changes are overwritten on the next `lessons.py` write.
> Canonical state lives in `.specs/lessons.json`. Edit lessons only via the script.
> promote_threshold=2 distinct features · window_days=45 · quarantine_threshold=2

## Confirmed (load these at Specify/Design)

Corroborated across multiple features. Safe to apply as guidance.

_none_

## Candidates (under observation - do NOT load as guidance yet)

Seen once or not yet corroborated. Tracked, not trusted.

### L-001 - When a requirement says a script prints a message, the shell test must capture stderr and assert the message text, not only the exit code
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `shell-tests` · harmful: 0
- features: m01-foundation
- evidence: validation.md M6 / COMMIT-03 .github/scripts/commit-msg_test.sh:23 (shell-tests)
- last seen: 2026-10-11T23:17:12Z

### L-002 - Test numeric limits at the exact boundary: accept the maximum and reject maximum plus one
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `shell-tests` · harmful: 0
- features: m01-foundation
- evidence: validation.md M5 / COMMIT-05 .github/scripts/commit-msg_test.sh:47 (shell-tests)
- last seen: 2026-10-11T23:17:12Z

### L-003 - Keep the locale identifier identical across spec, design and l10n config, and assert both language and country code when the spec names one
- signal: `spec_precision_gap` · recurrence: 1 feature(s) · scope: `l10n` · harmful: 0
- features: m01-foundation
- evidence: validation.md STRUCT-06 app/test/app_test.dart:96 (l10n)
- last seen: 2026-10-11T23:17:12Z

### L-004 - When the design canvas uses text styles absent from the typography token table, add them as tokens in the spec instead of deriving them with copyWith in components
- signal: `spec_precision_gap` · recurrence: 1 feature(s) · scope: `design-system` · harmful: 0
- features: m01-foundation
- evidence: validation.md COMP-15 (design-system)
- last seen: 2026-10-11T23:17:12Z

## Quarantined (failed when applied - ignore)

A confirmed lesson that recurred alongside failure. Kept for the maintainer to review.

_none_
