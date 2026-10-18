#!/bin/bash
set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
script="$script_dir/kill_test.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

failures=0

block() {
  printf '{"type":"text","content_json":"{\\"text\\":\\"%s\\",\\"marks\\":[]}"}' "$1"
}

passing_line() {
  printf '{"iteration":%s,"passed":true,"reason":"ok","expected":[%s],"actual":[%s]}\n' \
    "$1" "$(block a)" "$(block a)"
}

failing_line() {
  printf '{"iteration":%s,"passed":false,"reason":"blocks","expected":[%s,%s],"actual":[%s]}\n' \
    "$1" "$(block alfa)" "$(block beta)" "$(block alfa)"
}

assert_report() {
  local name=$1 expected_code=$2 expected_text=$3
  shift 3
  local output code
  output=$(bash "$script" --report "$@" 2>&1)
  code=$?
  if [ "$code" -ne "$expected_code" ]; then
    echo "FAIL ($name): exit code $code, expected $expected_code" >&2
    failures=$((failures + 1))
  fi
  if ! printf '%s\n' "$output" | grep -qF -- "$expected_text"; then
    echo "FAIL ($name): '$expected_text' not in output:" >&2
    printf '%s\n' "$output" >&2
    failures=$((failures + 1))
  fi
}

for i in $(seq 1 100); do passing_line "$i"; done > "$tmp/passing.jsonl"
assert_report "passing file" 0 "100/100 iterations, 0 divergences" \
  "$tmp/passing.jsonl" 100 7000

{
  for i in $(seq 1 6); do passing_line "$i"; done
  failing_line 7
  for i in $(seq 8 10); do passing_line "$i"; done
} > "$tmp/failing.jsonl"
assert_report "failing file counts" 1 "10/10 iterations, 1 divergences" \
  "$tmp/failing.jsonl" 10 7000
assert_report "failing file seed" 1 "iteration 7 (seed 7007)" \
  "$tmp/failing.jsonl" 10 7000
assert_report "failing file expected" 1 'expected: [text {"text":"alfa","marks":[]}, text {"text":"beta","marks":[]}]' \
  "$tmp/failing.jsonl" 10 7000
assert_report "failing file actual" 1 'actual: [text {"text":"alfa","marks":[]}]' \
  "$tmp/failing.jsonl" 10 7000

for i in $(seq 1 3); do passing_line "$i"; done > "$tmp/short.jsonl"
assert_report "missing iterations" 1 "3/5 iterations, 0 divergences" \
  "$tmp/short.jsonl" 5 7000
assert_report "missing iterations message" 1 "incomplete" \
  "$tmp/short.jsonl" 5 7000

if [ "$failures" -ne 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi
echo "all kill_test.sh report checks passed"
