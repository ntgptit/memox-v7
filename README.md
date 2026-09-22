# memox

Flutter flashcard / spaced-repetition app. Android is the release target; Web is
kept building because it is the E2E channel, not a production target (AD-04).

## Prerequisites

- Flutter stable with Dart SDK `^3.12.2` (`pubspec.yaml`)
- An Android emulator or device for the integration suite
- Generated code is **not committed** — you must produce it before anything runs

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -t lib/main.dart
```

**The `build_runner` step is not optional.** Drift queries, Riverpod providers
and the `.g.dart` files are all generated, and `.gitignore` keeps them out of the
repository. Hundreds of analyzer errors on a fresh clone almost always mean this
step was skipped, not that the code is broken.

`lib/main.dart` resolves to the development config so `flutter run` and
`flutter build web` keep working without a flavor. Android builds a flavored
variant, so a device build needs one — `development`, `staging` or `production`,
declared in `android/app/build.gradle.kts`:

```bash
flutter run --flavor development -t lib/main_development.dart
```

## Where things are

Start with [`CLAUDE.md`](CLAUDE.md), then
[`docs/document-conventions.md`](docs/document-conventions.md) — it defines the
reading order for everything else. Progress lives in
[`docs/wbs.md`](docs/wbs.md), and [`docs/README.md`](docs/README.md) indexes
every document and says which ones are deliberately not written yet.

## Verifying a change

```bash
.claude/skills/flutter-workflow/scripts/dod_check.sh
```

That covers the mechanical half of the Definition of Done; the judgement half is
in `CLAUDE.md`. Two checks worth running directly when you touch documentation
or the schema:

```bash
python .claude/skills/flutter-workflow/scripts/check_docs.py
python .claude/skills/flutter-workflow/scripts/verify_invariants.py
```

Adding anything under `lib/features/` additionally needs the device suite, which
CI deliberately does not run:

```bash
flutter test integration_test/ -d emulator-5554 --flavor development
```

CI workflow definitions live in [`.github/workflows/`](.github/workflows/).
