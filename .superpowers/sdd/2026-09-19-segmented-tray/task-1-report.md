# Task 1 report — SegmentedTray

## Outcome

Implemented the typed `MxSegmentedTray<T>` shared selector and migrated the
Progress range, Settings appearance, and Settings new-card-order callers. The
component owns the recessed 40dp paint surface, selected 32dp/8dp thumb,
4dp tray padding, 2dp option gap, 48dp semantic/tap targets, focus ring, and
exclusive selection semantics. The existing semantic theme roles and canonical
decoration token are used without theme changes.

The Widgetbook Controls catalog now has a SegmentedTray playground with
two/three-option, selected-option, enabled, and variant knobs.

## TDD evidence

`flutter test test/shared/widgets/mx_segmented_tray_test.dart` was run before
the production component existed and failed to load the missing
`mx_segmented_tray.dart` API. The resulting focused suite has eight tests for
the typed callback, exclusive semantics, 48dp target, exact geometry, intrinsic
width, focus ring, RTL/text scale, and 2-or-3-option precondition.

## Verification

- `flutter test test/shared/widgets/mx_segmented_tray_test.dart test/features/progress/presentation/progress_deck_screen_test.dart test/features/settings/presentation/settings_accessibility_test.dart test/features/settings/presentation/settings_screen_states_test.dart test/features/settings/presentation/settings_screen_geometry_test.dart test/app/widgetbook_coverage_test.dart` — passed, 62 tests.
- `flutter analyze --no-pub` — passed with no issues.
- `cd widgetbook && flutter pub get && flutter test` — passed, 8 tests.
- `flutter test test/features/progress/presentation/progress_deck_geometry_test.dart` — 9 tests passed and 1 unrelated existing metric-grid assertion failed: at line 224, measured numeral width `100.34400177001953` exceeds the asserted cell width `91.0` at 320dp/text scale 2. The failing metric grid is independent of the range selector migration.

## Verification concerns

- The project-profile-required command `node tool/verify/run.mjs --quick --test ...` cannot run because the exact checked path `tool/verify/run.mjs` is absent (`Test-Path tool/verify/run.mjs` returned `False`). This is non-blocking under the task plan, whose required repository verification is explicit.
- The repository DoD shell script is CRLF-encoded and cannot run under the default WSL `bash` (`$'\r': command not found` / `pipefail\r: invalid option name`). A CRLF-normalized invocation under Git Bash started its changed-path plan (full, 552 files), but the project-wide test suite still contains the independent Progress geometry failure above; it is not claimed clean here.

## Scope

No persistence, controller/domain, global theme, `MxPillButton`, language
three-choice control, or golden image changes were made.
