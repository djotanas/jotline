#!/bin/bash
# Runs the kill test on the connected Android device or emulator (KILL-04,
# KILL-05): builds and installs the instrumented profile APK, force-stops it
# at a random delay 100 times, and prints the divergences found.
#
#   app/tool/kill_test.sh [iterations]          # iterations defaults to 100
#   app/tool/kill_test.sh --report FILE N SEED  # only parse a results.jsonl
#
# KILL_SEED sets the base seed (default: epoch seconds); the delay of
# iteration i is derived from KILL_SEED + i. ANDROID_SERIAL picks the device.
set -u

package=com.jon.jotline
results_path=files/kill/results.jsonl

report() {
  python3 - "$@" <<'PY'
import json
import sys

path, expected, seed_base = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
rows = [json.loads(line) for line in open(path) if line.strip()]
bad = [row for row in rows if not row["passed"]]


def show(blocks):
    return "[" + ", ".join(f'{b["type"]} {b["content_json"]}' for b in blocks) + "]"


print(f"{len(rows)}/{expected} iterations, {len(bad)} divergences")
for row in bad:
    n = row["iteration"]
    print(f"divergence at iteration {n} (seed {seed_base + n}): {row['reason']}")
    print(f"  expected: {show(row['expected'])}")
    print(f"  actual: {show(row['actual'])}")
if len(rows) != expected:
    print(f"incomplete: {len(rows)} of {expected} iterations verified")
sys.exit(1 if bad or len(rows) != expected else 0)
PY
}

if [ "${1:-}" = "--report" ]; then
  report "$2" "$3" "$4"
  exit $?
fi

iterations=${1:-100}
seed_base=${KILL_SEED:-$(date +%s)}
app_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=$(mktemp)
trap 'rm -f "$out"' EXIT

cd "$app_dir" || exit 2
fvm flutter build apk --profile -t integration_test/kill/kill_app.dart || exit 2
adb install -r build/app/outputs/flutter-apk/app-profile.apk || exit 2
adb shell pm clear "$package" >/dev/null

line_count() {
  adb exec-out run-as "$package" cat "$results_path" 2>/dev/null | grep -c . || true
}

adb shell am start -n "$package/.MainActivity" >/dev/null
sleep 4
echo "kill test: $iterations iterations, base seed $seed_base"
for i in $(seq 1 "$iterations"); do
  RANDOM=$((seed_base + i))
  delay_ms=$((500 + RANDOM % 5501))
  sleep "$(awk "BEGIN { print $delay_ms / 1000 }")"
  adb shell am force-stop "$package"
  adb shell am start -n "$package/.MainActivity" >/dev/null
  for _ in $(seq 1 40); do
    [ "$(line_count)" -ge "$i" ] && break
    sleep 0.5
  done
  echo "iteration $i seed $((seed_base + i)) delay ${delay_ms}ms"
done
adb shell am force-stop "$package"
adb exec-out run-as "$package" cat "$results_path" > "$out"
report "$out" "$iterations" "$seed_base"
