---
name: flutter-project-setup
description: Stands up the Flutter project skeleton and everything that is decided once and constrains the rest of the build — toolchain check, git repo conventions, `flutter create` with the right org and IDs, the dependency set and why each package is there, dev dependencies and code generation, build flavors for dev/staging/prod, the bootstrap function with error boundaries, and the Failure/error model. Use this skill when creating a new Flutter app, adding or auditing dependencies, wiring `main.dart` and bootstrap, setting up environments or flavors, configuring build_runner, or designing how errors are represented across layers. Covers checklist phases 2, 3 and 6.
---

# Project setup and foundation

Covers checklist Phases 2 (environment), 3 (dependencies) and 6 (bootstrap,
flavors, error model). These are grouped because they are decided once and
constrain everything after — the flavor decides the log level bootstrap
installs, and the error model decides what the error boundary reports.

Prerequisite: `docs/product.md` exists and answers platforms, online/offline and
auth. Those three answers change the dependency set, so setting up before they
are settled means redoing it.

## 2.1 Toolchain

```bash
flutter --version && flutter doctor -v
```

Use Flutter stable. Record the exact version in `docs/architecture.md` and pin
it in CI — "works on my machine" is nearly always a toolchain drift.

If `flutter` is not on PATH in this environment, say so plainly and continue
with the work that does not need it (docs, decisions, file layout). Do not
fabricate command output.

## 2.2 Repository conventions

- `.gitignore` — start from the Flutter template, then confirm it excludes
  generated code you do not intend to commit (`*.g.dart`, `*.freezed.dart`),
  `.env` files, signing keys, and `**/google-services.json` if it holds secrets.
- **Generated code: commit or not?** Pick one and write it down. Committing them
  makes checkout-and-run work and makes diffs noisy; not committing them means
  CI must run `build_runner` before analyze. Not committing is the better default
  here because CI already runs codegen as a freshness check (Phase 19.1).
- Conventional Commits, scoped by feature: `feat(auth):`, `fix(sync):`.
- Branch naming: `feat/<slice>`, `fix/<issue>`, `chore/<thing>`.
- PR and issue templates in `.github/`.
- Branch protection on the default branch; no direct pushes.

## 2.3 Creating the project

```bash
flutter create \
  --org <reverse.domain> \
  --project-name <package_name> \
  --platforms=android,ios \
  .
```

Get `--org` right the first time — changing the application ID after a store
release means a new listing, not an update.

Then: delete the counter demo, reduce `main.dart` to a bootstrap call, set the
minimum SDK deliberately (each bump you defer costs you plugin compatibility
later), and confirm a clean build before writing any feature code.

`main.dart` after this step should be a handful of lines: choose the
environment config, call `bootstrap`. Nothing else.

## 3. Dependencies

Read `references/dependencies.md` for the full list with the reason each package
is present and the traps in each one.

The rule that matters more than the list: **do not add a package without a
stated reason, and never two packages for one job.** Every dependency is a
permanent liability — it can break on a Flutter upgrade, be abandoned, or carry
a licence problem. Before adding one, check its last publish date, its open
issue count against a Flutter-stable release, and its licence.

Add with `flutter pub add` so constraints are written correctly, then commit
`pubspec.lock`.

## 6.1 Bootstrap

`bootstrap()` owns startup, `main()` owns nothing but calling it. The reason to
separate them is testability and flavors — three `main_*.dart` entrypoints can
share one bootstrap, and a test can call bootstrap with fakes.

Order matters, because later steps report failures through earlier ones:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Logging — first, so everything after it can report.
3. Environment config — decides log level and base URL.
4. Storage and database — these can fail; a database that fails to open is a
   startup failure the user must see, not a silent crash loop.
5. Error boundaries.
6. `runApp` inside a `ProviderScope`, with any overrides for pre-resolved
   async dependencies.

Error boundaries need all three of these; each catches what the others miss:

- `FlutterError.onError` — framework errors, including build errors.
- `PlatformDispatcher.instance.onError` — uncaught async errors.
- `ErrorWidget.builder` — replace the red screen in release with something that
  does not leak a stack trace to the user.

Anything that can throw during startup belongs inside a guarded zone that shows
a real error screen. A white screen with no explanation is the worst failure
mode available, because it is indistinguishable from a hang.

## 6.2 Environments and flavors

Three flavors: development, staging, production. Each carries app name,
application ID suffix, API base URL, log level, feature flags and analytics
config.

Model the config as an immutable class chosen at the entrypoint — not read from
a global mutable singleton, and never branched on with `kDebugMode` scattered
through feature code:

```dart
final class EnvConfig {
  const EnvConfig({
    required this.name,
    required this.apiBaseUrl,
    required this.logLevel,
    required this.isAnalyticsEnabled,
  });
  // ...
}
```

Expose it through a Riverpod provider overridden in `bootstrap`, so any layer
reads it the same way and tests can substitute one.

Secrets never live in the repo. `--dart-define-from-file` with an ignored file
locally, CI secrets in the pipeline. Development never points at production
credentials — the day someone runs a destructive test against prod data is the
day you wish this had been enforced.

Distinct application IDs per flavor (`com.x.app.dev`) so all three install side
by side on one device. Read `references/flavors.md` for the Android and iOS
wiring.

## 6.3 Error model

This is the contract between layers, so get it right before any feature uses it.

**Data layer throws typed exceptions.** `DioException`, `DriftWrappedException`
and friends are caught at the *repository boundary* and never travel further.

**Domain layer speaks `Failure`.** A sealed class, so `switch` over it is
exhaustive and the compiler tells you when a new failure type needs handling:

```dart
sealed class Failure {
  const Failure({required this.message, this.cause});
  final String message;   // safe to show a user
  final Object? cause;    // for logs only, never rendered
}

final class NetworkFailure extends Failure { ... }
final class UnauthorizedFailure extends Failure { ... }
final class ForbiddenFailure extends Failure { ... }
final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, required this.fieldErrors});
  final Map<String, String> fieldErrors;  // drives inline form errors
}
final class NotFoundFailure extends Failure { ... }
final class ConflictFailure extends Failure { ... }
final class DatabaseFailure extends Failure { ... }
final class UnknownFailure extends Failure { ... }
```

`ValidationFailure` carries field errors because that is what the UI needs to
show an error under the right input. A validation failure flattened to one
string forces the UI to guess.

**Result type or exceptions?** Either works. Pick one and hold to it —
`Result<T>` makes failure explicit in the signature at the cost of ceremony;
throwing `Failure` and catching in the controller is lighter but easier to
forget. Whichever you choose, the invariant is that a `DioException` never
reaches presentation.

**Messages are for users.** No URLs, SQL, stack traces or internal identifiers.
The technical detail goes in `cause` and into logs. When mapping an unexpected
error, log the original and show something generic — a leaked stack trace in a
snackbar is both a bad experience and an information disclosure.

Put the mapping in one place (`core/error/`) so every repository maps the same
exception to the same failure, and test it (Phase 15.1) — error mapping is the
code most likely to be wrong and least likely to be exercised by hand.
