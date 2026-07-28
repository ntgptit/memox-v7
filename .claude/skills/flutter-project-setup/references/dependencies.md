# Dependencies

Add with `flutter pub add <pkg>` / `flutter pub add --dev <pkg>` so version
constraints are written correctly, then commit `pubspec.lock`.

Do not hardcode versions from memory — check pub.dev for the current release
that matches the Flutter version in use. Versions below are the major line this
project targets, not exact pins.

## Runtime

**Not yet for memox:** `dio` is deliberately absent until the Spring Boot
integration begins (AD-05 in `docs/architecture.md`) — the MVP makes no network
calls, and an unused HTTP client still costs build time, still needs upgrading,
and still suggests a network layer exists. Add it when the first real request
does.

| Package | Line | Why it is here |
|---|---|---|
| `flutter_riverpod` | 3.x | State + DI. Compile-safe, testable without a widget tree. |
| `riverpod_annotation` | 3.x | Annotations for the generator. |
| `go_router` | 14+ | Declarative routing, deep links, redirect guards. |
| `dio` | 5.x | HTTP with interceptors, cancellation and typed errors. **Deferred — see above.** |
| `drift` | 2.x | Typed SQLite with migrations and reactive queries. |
| `sqlite3_flutter_libs` | — | Ships the SQLite binary. Required by Drift on mobile. |
| `path_provider` | — | Locates the database directory. |
| `path` | — | Joins that path portably. |
| `freezed_annotation` | — | Immutable data classes, unions, `copyWith`. |
| `json_annotation` | — | JSON codegen annotations. |
| `intl` | — | Locale-aware dates and numbers. |
| `collection` | — | `firstWhereOrNull`, equality helpers. Avoids hand-rolled bugs. |
| `uuid` | — | Client-generated IDs. Needed **from day one** even without sync: changing the primary-key strategy later means rewriting every foreign key (AD-03). |
| `flutter_secure_storage` | — | Keychain / EncryptedSharedPreferences for tokens. **Deferred** — memox has no tokens until auth arrives. |

Add only when the need is real:

| Package | Add when |
|---|---|
| `connectivity_plus` | You show an offline state or trigger sync on reconnect. Note it reports link state, not reachability — a captive portal reads as online. |
| `cached_network_image` | You render remote images in lists. |
| `sentry_flutter` / `firebase_crashlytics` | Phase 18, entering release. Not before. |
| `flutter_localizations` + `intl` ARB | Phase 12. It ships with Flutter — enable via `flutter: generate: true`. |

## Dev

| Package | Why |
|---|---|
| `build_runner` | Runs all generators. |
| `riverpod_generator` | `@riverpod` → providers. |
| `riverpod_lint` | Catches the Riverpod mistakes the analyzer cannot see. |
| `custom_lint` | Host required by `riverpod_lint`. |
| `drift_dev` | Drift table and DAO codegen. |
| `freezed` | Data class codegen. |
| `json_serializable` | `fromJson` / `toJson`. |
| `mocktail` | Mocks without codegen — less friction than `mockito`. |
| `golden_toolkit` *or* `alchemist` | Golden tests with stable fonts. Pick one, only when Phase 15.4 starts. |
| `flutter_lints` | Baseline rule set that `analysis_options.yaml` extends. |

## Code generation

```bash
dart run build_runner build --delete-conflicting-outputs   # one-shot
dart run build_runner watch --delete-conflicting-outputs   # while developing
```

`--delete-conflicting-outputs` is nearly always what you want; without it a
renamed file leaves a stale generated file that then fails the build in a way
that points at the wrong place.

CI must run codegen and then fail if the tree is dirty — that is what catches a
generated file committed stale (Phase 19.1).

## Traps worth knowing before you hit them

- **Riverpod 3 dropped the generated per-provider `Ref` subclasses.** Write
  `Ref ref`, not `MyThingRef ref`. Examples written for 2.x will not compile.
- **`riverpod_lint` needs `custom_lint` enabled** in `analysis_options.yaml`
  (`analyzer: plugins: - custom_lint`) or its rules silently do nothing. Run
  `dart run custom_lint` in CI, because `flutter analyze` does not run them.
- **Drift needs `sqlite3_flutter_libs`** on mobile or it fails at runtime, not
  build time — an easy one to miss until a device test.
- **`flutter_secure_storage` on Android** needs `minSdkVersion` 23+ for the
  EncryptedSharedPreferences backend.
- **`intl` version conflicts** with `flutter_localizations` regularly. Let pub
  resolve it rather than pinning `intl` by hand.

## Auditing what is already there

```bash
flutter pub outdated
flutter pub deps --style=compact
```

For each direct dependency ask: is it still used, is it still maintained, is
there a second package doing the same job, and is the licence acceptable? Drop
what fails. An unused dependency still costs build time and still breaks on
upgrade.
