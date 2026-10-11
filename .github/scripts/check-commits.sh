#!/bin/sh
set -u

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <range>" >&2
  exit 2
fi

range="$1"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
hook="$repo_root/.githooks/commit-msg"

tmp_msg=$(mktemp)
trap 'rm -f "$tmp_msg"' EXIT

bad_shas=""

for sha in $(git rev-list "$range"); do
  git log -1 --format=%B "$sha" > "$tmp_msg"
  if ! sh "$hook" "$tmp_msg" >/tmp/check-commits-out.$$ 2>&1; then
    bad_shas="$bad_shas $sha"
  fi
  rm -f /tmp/check-commits-out.$$
done

if [ -n "$bad_shas" ]; then
  echo "Commit message check failed for:$bad_shas" >&2
  exit 1
fi

echo "All commits in $range pass the message check."
exit 0
