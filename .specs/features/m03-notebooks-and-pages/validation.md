# M03 — Validation

## PERF-01 — Launch to new page

Metric (decided): an integration test in profile mode drives the app and measures only app time, with no human pauses. The clock starts when the app is built and stops when the minimal page of a new page is in the widget tree. The notebook is seeded through the repository, so the keyboard is not involved. Three marks are reported: `toListMs` (notebooks list shown), `toNotebookMs` (notebook open) and `toPageMs` (new page open). **PERF-02 compares `toPageMs` with 1000 ms.**

Test: `app/integration_test/perf/launch_to_new_page_test.dart`, driver `app/test_driver/perf_driver.dart`.

Limit: the clock starts at the first `pumpWidget`, so engine and process start are not included. For that, also record the cold start from `adb shell am start -W -n com.jon.jotline/.MainActivity` (`TotalTime`) after `adb shell am force-stop com.jon.jotline`, with the profile APK installed.

### Procedure

1. Mid-range Android device, USB debugging on, battery saver off, normal brightness. Same animation scales in all runs (`adb shell settings get global window_animation_scale`, `transition_animation_scale`, `animator_duration_scale`). `animator_duration_scale` may return `null` (default, equals 1.0): record it as `1.0 (default)`. Note battery saver and brightness. `adb` is in `$ANDROID_HOME/platform-tools`.
2. From `app/`, five times (one process each, so each run is a fresh start of the app process):

   ```
   fvm flutter drive --driver=test_driver/perf_driver.dart \
     --target=integration_test/perf/launch_to_new_page_test.dart \
     --profile -d DEVICE_ID
   ```

   Before each run, `rm -f app/build/launch_to_new_page.json`. Each run writes that file; if it is missing the run failed, so repeat it. Copy it as `run-N.json` before the next run. Discard nothing silently: if the first run is much faster than the rest, say so in the result.
3. Cold-start cross-check, after the first drive (it builds `app-profile.apk`): `adb install -r app/build/app/outputs/flutter-apk/app-profile.apk`. Then 5 times: `adb shell am force-stop com.jon.jotline; sleep 2; adb shell am start -W -n com.jon.jotline/.MainActivity`, and write down `TotalTime` (ms).
4. Sanity: `fvm flutter test integration_test/perf -d DEVICE_ID` (debug) must pass; it writes no json and its time is not a measurement. `fvm flutter test integration_test` includes this test.
5. Record the medians in the table.

### Known limitation

The existing e2e flows (`notebooks_flow_test.dart` and the others) pass in debug but fail under `--profile`: the tap on "Criar caderno" after typing does not create the notebook. This is why the measurement seeds data instead of typing. Not investigated.

### Dry run on the emulator (not valid for PERF-01)

sdk_gphone64_x86_64, Android 15, profile, 5 runs, `toPageMs`: 1196, 1270, 1180, 1633, 1014 (median 1196 ms); `toListMs` median 516 ms; `toNotebookMs` median 991 ms. A second dry run by a validating subagent gave `toPageMs` median 1896 ms (866–2351) and `TotalTime` median 2090 ms: emulator numbers vary a lot between sessions.

### Result

| Field | Value |
| --- | --- |
| Device model | |
| Android version | |
| Build | profile |
| Animation scale (window/transition/animator) | |
| Battery saver / brightness | |
| `toListMs` runs / median | |
| `toNotebookMs` runs / median | |
| `toPageMs` runs / median | |
| `am start -W` TotalTime runs / median | |

PERF-02: if the `toPageMs` median is 1000 ms or more, a follow-up issue is drafted with this measurement.
