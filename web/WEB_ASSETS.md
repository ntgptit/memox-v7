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
| `drift_worker.js` | `simolus3/drift` release `drift-2.34.0` | drift 2.34.0 |

## Re-downloading after an upgrade

```bash
curl -sSL -o web/sqlite3.wasm \
  https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-<VER>/sqlite3.wasm
curl -sSL -o web/drift_worker.js \
  https://github.com/simolus3/drift/releases/download/drift-<VER>/drift_worker.js
```

Then update the table above and the constants in `web_assets_test.dart` — the
test reads both, so a half-done upgrade fails rather than shipping.
