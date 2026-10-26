# Blocked tests: stop, do not work around

## e2e on a phone

- e2e, perf and kill tests run on the user's Android phone over adb.
- Before running one, check `adb devices`. If no device is listed as `device`, abort the run and ask the user to connect it.
- Do not try another route: no emulator, no `adb connect` loops, no other host, no skipping the test, no marking the task as verified.
- Tasks that need the device stay unticked and uncommitted until the user reconnects it.

## Any other test (unit, widget, integration)

- If something prevents a test from running (toolchain, build, missing dependency, environment), do not search for alternative ways to run it.
- Stop, report the problem to the user (command, error, what was tried) and wait. The user fixes it.
- Never weaken, skip or delete the test to get around the block.
