#!/bin/sh
set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
hook="$repo_root/.githooks/commit-msg"

tmp_msg=$(mktemp)
trap 'rm -f "$tmp_msg"' EXIT

failures=0

assert_accepts() {
  printf '%s\n' "$1" > "$tmp_msg"
  if ! sh "$hook" "$tmp_msg" >/dev/null 2>&1; then
    echo "FAIL (expected accept): $1" >&2
    failures=$((failures + 1))
  fi
}

assert_rejects() {
  printf '%s\n' "$1" > "$tmp_msg"
  if sh "$hook" "$tmp_msg" >/dev/null 2>&1; then
    echo "FAIL (expected reject): $1" >&2
    failures=$((failures + 1))
  fi
}

assert_rejects_with_help() {
  printf '%s\n' "$1" > "$tmp_msg"
  if stderr=$(sh "$hook" "$tmp_msg" 2>&1 >/dev/null); then
    echo "FAIL (expected reject): $1" >&2
    failures=$((failures + 1))
  elif ! printf '%s\n' "$stderr" | grep -qF "$2"; then
    echo "FAIL (expected '$2' in output): $1" >&2
    failures=$((failures + 1))
  fi
}

assert_accepts "feat(app): x"
assert_accepts "docs: x"
assert_accepts "fix!: x"
assert_accepts "refactor(infra)!: x"
assert_accepts "Merge branch 'a'"
assert_accepts 'Revert "feat: x"'

printf 'feat(app): x\n# comment line after header\nmore body\n' > "$tmp_msg"
if ! sh "$hook" "$tmp_msg" >/dev/null 2>&1; then
  echo "FAIL (expected accept): header followed by comment lines" >&2
  failures=$((failures + 1))
fi

assert_rejects "feature: x"
assert_rejects "feat(prd): x"
assert_rejects_with_help "feature: x" "Expected format:"
assert_rejects_with_help "feature: x" "Allowed types:"
assert_rejects_with_help "feat(prd): x" "Allowed scopes"
assert_rejects "feat:x"
assert_rejects "feat: "

long_header="feat: $(printf 'x%.0s' $(seq 1 100))"
assert_rejects "$long_header"

header_100="feat: $(printf 'x%.0s' $(seq 1 94))"
assert_accepts "$header_100"

header_101="feat: $(printf 'x%.0s' $(seq 1 95))"
assert_rejects "$header_101"

: > "$tmp_msg"
if sh "$hook" "$tmp_msg" >/dev/null 2>&1; then
  echo "FAIL (expected reject): empty file" >&2
  failures=$((failures + 1))
fi

printf '# only a comment\n# another comment\n' > "$tmp_msg"
if sh "$hook" "$tmp_msg" >/dev/null 2>&1; then
  echo "FAIL (expected reject): comments-only file" >&2
  failures=$((failures + 1))
fi

if [ "$failures" -gt 0 ]; then
  echo "$failures case(s) failed." >&2
  exit 1
fi

echo "All commit-msg hook cases passed."
exit 0
