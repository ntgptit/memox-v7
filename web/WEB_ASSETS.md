# Vendored drift web assets

`sqlite3.wasm` and `drift_worker.js` are prebuilt binaries downloaded from the
upstream releases. They are **not** produced by `flutter build`, and nothing in
the build fails when they are missing or stale — the app compiles, loads, and
then cannot open a database at runtime. Web is the E2E channel (AD-04), so that
failure would show up as an E2E suite that passes against an app with no
persistence at all.

Their versions must track `pubspec.lock`. `test/database/web_assets_test.dart`
fails when they drift apart, because a drift upgrade that forgets these two files
has no other symptom until someone opens the app in a browser.

| File | Source | Version |
|---|---|---|
| `sqlite3.wasm` | `simolus3/sqlite3.dart` release `sqlite3-3.5.0` | sqlite3 3.5.0 |
| `drift_worker.js` | compiled from the **locked** drift with `dart compile js` (below) | drift 2.34.0 |

The worker is compiled locally rather than downloaded. The prebuilt worker
attached to a drift release embeds whatever `sqlite3` glue drift was built
against at release time, and that glue can lag the `sqlite3.wasm` ABI — the
drift-2.34.0 release worker fails against sqlite3-3.5.0 with
`LinkError: import "dart" "xFileControl" requires a callable`. Compiling from
this project's own lockfile makes the worker and the wasm agree by
construction (found by the M4.9 web runtime test, the first thing to actually
open the web database).

## Rebuilding after an upgrade

```bash
curl -sSL -o web/sqlite3.wasm \
  https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-<VER>/sqlite3.wasm

# worker entrypoint (temp file):
#   import 'package:drift/wasm.dart';
#   void main() => WasmDatabase.workerMainForOpen();
dart compile js -O4 --packages=.dart_tool/package_config.json \
  -o web/drift_worker.js <temp>/drift_worker_entry.dart
```

Then update the table above and the constants in `web_assets_test.dart` — the
test reads both, so a half-done upgrade fails rather than shipping.

## The copies in `test/`

`test/sqlite3.wasm` and `test/drift_worker.js` are byte-for-byte copies.
`flutter test --platform chrome` serves the project's `test/` directory at the
site root, so the root-absolute production URLs in
`lib/core/database/connection.dart` resolve during the web runtime test.
`web_assets_test.dart` asserts the copies stay identical to the originals.
