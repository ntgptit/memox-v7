# CI pipeline and release builds

## GitHub Actions

`.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x.x'    # pin — must match the version in docs/architecture.md
          channel: stable
          cache: true

      - run: flutter pub get

      # Codegen first: analyze and test both need the generated files, and
      # running it here is also what detects stale committed output below.
      - name: Generate code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Fail if generated code is stale
        run: |
          if [[ -n "$(git status --porcelain)" ]]; then
            echo "Generated code differs from what is committed:"
            git status --porcelain
            git diff
            exit 1
          fi

      - name: Format
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze
        run: flutter analyze

      # Separate step on purpose: flutter analyze does NOT run riverpod_lint.
      - name: Custom lint (riverpod_lint)
        run: dart run custom_lint

      - name: Architecture boundaries
        run: .claude/skills/flutter-architecture/scripts/check_architecture.sh

      - name: Test
        run: flutter test --coverage

      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: failed-golden-diffs
          path: '**/failures/**'

  build-android:
    needs: verify
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: '17' }
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.x.x', channel: stable, cache: true }
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter build apk --debug --flavor development -t lib/main_development.dart

  build-ios:
    needs: verify
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.x.x', channel: stable, cache: true }
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      # --no-codesign: PR validation needs a compile check, not a signed artifact.
      - run: flutter build ios --no-codesign --flavor development -t lib/main_development.dart
```

Notes on choices that are easy to get wrong:

- **Pin the Flutter version.** `channel: stable` alone means the pipeline
  silently changes under you, and a stable release eventually breaks something.
- **Uploading golden failure diffs on failure** is what makes a golden failure
  diagnosable in CI. Without it you get "goldens differ" and no image.
- **Cache `~/.pub-cache`** via the action's `cache: true`; it is most of the
  pipeline's wall time.
- **iOS on `macos-latest`** costs several times more runner minutes. Running it
  only on the main branch is a reasonable trade if minutes are limited.

## Release builds

```bash
# Android App Bundle for the store
flutter build appbundle \
  --release \
  --flavor production \
  -t lib/main_production.dart \
  --dart-define-from-file=env/prod.json \
  --obfuscate --split-debug-info=build/symbols/android

# iOS archive
flutter build ipa \
  --release \
  --flavor production \
  -t lib/main_production.dart \
  --dart-define-from-file=env/prod.json \
  --obfuscate --split-debug-info=build/symbols/ios
```

**Keep `build/symbols/`.** Obfuscated crash reports are unreadable without the
matching symbol files, and they must match that exact build — archive them
alongside the artifact, per version.

## Signing

Android: keystore from CI secrets, decoded at build time into a path referenced
by `key.properties`. Never commit the keystore or `key.properties`.

```yaml
- name: Decode keystore
  run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/upload-keystore.jks
```

iOS: certificate and provisioning profile from secrets into a temporary keychain
— `apple-actions/import-codesign-certs` handles the fiddly parts.

Losing the Android upload key means you cannot update the listing without Play's
key-reset process. Back it up somewhere durable and outside the repo.

## Versioning

`version: 1.4.2+87` in `pubspec.yaml` — name plus build number. The build number
must increase on every store upload; both stores reject a repeat. Deriving it
from the CI run number removes the manual step and the duplicate-rejection
round-trip.

## Deployment

`fastlane`, or the store CLIs, from a tag-triggered workflow. Always to internal
testing first, then staged rollout: 10% → 50% → 100%, watching crash-free
percentage between steps. A staged rollout is the rollback plan — a bad release
caught at 10% affects a tenth of the users.
