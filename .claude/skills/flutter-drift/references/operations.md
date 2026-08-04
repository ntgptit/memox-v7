# Code generation, logging, backup

The parts of database work that are not schema and not queries: keeping
generated code honest, seeing what the database is doing, and getting data out of
it safely.

## Code generation

Generated code is not committed in this repo (`.gitignore` says why), so a fresh
clone does not analyze, test or run until it is generated:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Hundreds of analyzer errors right after cloning almost always means this step was
skipped, not that the code is broken.

While developing, `dart run build_runner watch --delete-conflicting-outputs`
keeps it current.

Rules that hold regardless:

- **Never hand-edit a `.g.dart`.** The next build silently reverts it, so the fix
  works until someone else runs the generator.
- **Never put logic in a generated extension.** Same reason, plus it is invisible
  to review.
- **Applications pin dependencies** via `pubspec.lock`, committed. Drift's
  runtime and `drift_dev` must move together — a mismatch produces generated code
  the runtime cannot use, and the error message points at neither.
- **`drift`, `drift_dev` and `drift_flutter` are one set; `flutter_riverpod`,
  `riverpod_annotation` and `riverpod_generator` are another.** Bump each set
  together.

CI must prove the committed state is the generated state:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
git diff --exit-code            # after a fresh build_runner build
```

The last line is the one that catches the real failure: someone changed a
`.drift` file, did not regenerate, and everything passed locally because their
machine still had the old output. `flutter-workflow/scripts/check_generated.sh`
exists for exactly this.

## Logging

Card content, notes, learning history, imports, media and backups are private
(AD-08). A database log touches all of them at once, so the rules are stricter
here than anywhere else in the app:

- **Never log row content, at any level.** Not in debug, not "temporarily".
- **Never log query parameters in a release build** — a parameter *is* row
  content.
- **Never log the database path.**

What is safe and useful: the statement text, its duration, the row count, the
transaction duration, and migration `from`/`to`. `query_log_interceptor.dart`
does the first two and is gated on `kDebugMode` — a compile-time constant rather
than a runtime flag, so the tree shaker removes the interceptor and its log lines
from a release build entirely. For anything adjacent to private data that is
stronger than a flag that can be set wrong and still ship.

Beyond that:

- Give slow queries a **threshold** rather than logging everything; a log nobody
  reads is a log that hides the one line that mattered.
- **Never swallow a database exception.** If it is genuinely ignorable, catch it
  narrowly and say why in a comment.
- A migration failure needs enough context in the crash report to identify the
  `from` → `to` path, because you cannot ask the device for its schema.
- Drift's DevTools integration inspects the database live during development —
  use it instead of adding a debug screen that dumps rows.

## Backup, export and import

Nothing here is built yet; these are the constraints for when it is, and they are
the ones people get wrong.

**Copying the file is not a backup while the database is open.** A copy taken
mid-transaction is a torn snapshot. If WAL is ever enabled, the `-wal` and `-shm`
sidecar files are part of the database — copying only the main file loses every
committed transaction still in the WAL. Checkpoint first, or use SQLite's own
backup API.

**An export carries its own version metadata** — schema version and app version —
because an import six months later has to decide whether it can read it at all.

**Import into a temporary database first**, validate it there, then swap. An
import that writes directly into the live database and fails halfway has
destroyed the data it was meant to add to.

**Export only on explicit user request**, and never include anything the user did
not ask to export. On Android, check how the app's backup settings interact with
the database file before assuming a reinstall starts clean — a restored file at
an older schema version is a migration path that has to work.

## Security

- No secrets in the database. Tokens and keys go to secure storage, and are
  cleared on logout along with any cached user content.
- Encryption is a door left open in `connection.dart`, not a feature — if the
  threat model ever requires it, add it there so "is this database encrypted"
  keeps one answer. Never hand-roll the cipher.
- A production database file must never appear in a test fixture or a repository.
