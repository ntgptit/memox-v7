# Feature blueprint — derived from `features/deck` (M4.9…M4.10)

The Deck feature is the reference implementation. This file records **what to copy,
what to rename, and what must not be copied**, measured against the code as it
stands rather than as an ideal.

It is not a folder template to scaffold blindly. The repo's guards select files by
*suffix*, and MX-VIS-001 derives an audit path from a screen's location, so the
layout below is load-bearing — a plausible-looking alternative breaks a gate.

## The layout, and why it is flat

```
lib/features/<feature>/
├── domain/          <name>_entity.dart · <name>_repository.dart · <name>_model.dart
├── data/            <name>_repository_impl.dart · <name>_mapper.dart
│   └── local/       <name>_dao.dart
└── presentation/    <name>_screen.dart · <name>_controller.dart
                     <name>_widget.dart · <name>_state.dart
```

**No `entities/` / `usecases/` / `pages/` subfolders.** Three enforcers disagree
with them:

- `memox.naming.{domain,data,presentation}_file_role_suffix` — a file's *role* is
  carried by its suffix, and several guard scopes select by that suffix. A
  mis-suffixed file silently escapes the rules meant to cover it.
- `check_architecture.sh` `check_suffix` checks the **singular** folder names
  `/domain/entity/`, `/domain/usecase/`, `/presentation/screen/`,
  `/presentation/controller/`, `/data/model/` — plural folders match nothing and
  the check quietly passes on them.
- `test/visual_audit/screens/screen_audit_coverage.dart` builds the required
  audit path by stripping **only** the `presentation` segment. A `pages/`
  subfolder moves every companion to `…/features/<f>/pages/…`.

Add a subfolder only when a layer genuinely has enough files to need one, and
then use the singular names the suffix check knows.

`usecases/` is absent on purpose: the repository contract *is* the use-case
surface here, and a use-case class per method would be a pass-through. Add one
when a call orchestrates more than one repository.

## What `core/` and `shared/` already provide — do not re-create

| Need | Use |
|---|---|
| "now", injectable and testable | `core/time/clock_provider.dart` |
| turn off Riverpod's retry ladder on a local read | `core/state/retry_policy.dart` — `noAutomaticRetry` |
| failure types | `core/error/failure.dart` |
| Drift exception → `Failure` | `core/error/drift_error_mapper.dart` |
| the open database | `core/database/app_database_provider.dart` |
| spacing / radius / icon size / colours / text | `core/theme/*` — never a literal |
| screen chrome, list row, buttons, inputs, sheets, dialogs, empty/error/loading | `shared/widgets/mx_*` |
| localized strings | `lib/l10n/*.arb` + `context.l10n` |

**The rule that makes this checkable:** every import a feature makes to the
outside must resolve to `core/`, `shared/`, `l10n/` or `app/`. A feature reaching
into another feature's `data/` or `presentation/` is an error
(`check_architecture.sh` rule 3). Verify with:

```bash
git grep -nE "import '[^']*features/[a-z_]+/(data|presentation)/" -- lib/features
```

Anything a second feature would need from the first belongs in `core/` **before**
the clone, not after. Both entries in the table's first two rows were originally
inside `features/deck/presentation/` and were moved for exactly this reason.

## Domain purity

`domain/` compiles as plain Dart: no Flutter, no Drift, no Riverpod, no
`json_annotation`. `freezed_annotation` and `meta` are allowed — pure-Dart
annotation packages. Enforced by `check_architecture.sh` rule 1 and
`memox.architecture.domain_no_infrastructure_import`.

A Drift row must never appear above the repository. The mapper is the boundary:

- `data/<name>_mapper.dart` — `Row → Entity`, and `AggregateResult → ReadModel`
- read models live in `domain/` as `_model.dart`, not on the entity: a count that
  is only true at one instant does not belong on the type every write path uses

## Riverpod

Codegen only. `@riverpod` on a function for a read, on a class for anything with
commands. No manual `Provider`/`StateProvider`/`StateNotifierProvider`, no
`ChangeNotifier` — `memox.state_management.*` rejects all of them.

**Reads** are `AsyncValue`, consumed with `.when(loading:, data:, error:)`. Not
`hasValue`, not `requireValue`. Put `@Riverpod(retry: noAutomaticRetry)` on every
one that reads the local database.

**Writes** are a class notifier whose state is a form/submit state, *not*
`AsyncValue<void>`. The reason is concrete: a mutation has to distinguish "this
field is invalid" from "the operation failed" from "it succeeded, close the
sheet". `AsyncError(ValidationFailure)` collapses the first two, and the widget
then has to destructure a failure to find out which field to mark. See
`deck_submit_state.dart` for the shape:

```dart
isSubmitting · <field problems> · Failure? failure · isDone   → canSubmit
```

Every `submit` follows the same five steps, in this order:

1. `if (!state.canSubmit) return;` — the double-submit guard
2. validate locally against the domain rule, and return with a field problem set
3. `state = const XSubmitState(isSubmitting: true);`
4. `await` the repository; `if (!ref.mounted) return;` **before** touching state
5. success → `isDone: true`; `on Failure` → map onto field or `failure`

Never clear the user's input on failure. The widget owns the text, so a failed
write cannot destroy it — that is the point of keeping the controller out of it.

A controller never holds a `BuildContext` and never navigates. It exposes
`isDone` and the widget reacts via `ref.listen`, on the *transition* rather than
the value, so a sheet closes once instead of on every rebuild.

`autoDispose` (the generator default) for anything per-screen; `keepAlive` only
for the database and the repositories.

### The one thing that is duplicated, and the trade-off

The five steps above appear once per operation — six times in Deck, about eight
lines each. Three extractions were tried and rejected:

- an extension on the generated base couples app code to riverpod's
  `$`-prefixed internal `$Notifier`;
- a runner taking `read`/`write`/`isMounted` callbacks replaces eight readable
  lines with four lines of plumbing per call site;
- a `BaseController` hides the `ref.mounted` check, which is the one line that
  must be visible.

If the count grows past a second feature, generalise the **state class** rather
than the runner: `SubmitState<P>` with `Set<P> fieldProblems`, and each feature
supplying its own field enum. That keeps the visible steps and removes the
duplicated type. It is a real refactor across every call site and every
assertion, so it is worth doing once, deliberately — not halfway.

## Data layer

- one DAO per feature, receiving an already-open `AppDatabase`; nothing but
  `core/database/connection.dart` opens one (AD-08)
- **all SQL in `.drift` files** so `drift_dev` type-checks it at build time
  (AD-02). No business SQL in Dart.
- **query → `Stream` (`watch`), mutation → `Future`.** Reads re-emit on every
  write, from any screen, which is what removes manual refresh.
- multi-step writes go through `dao.runInTransaction`, and every guard that can
  refuse runs **before** the first mutation, so a refused write leaves no trace
- aggregate in SQL, never per row in Dart. One statement with grouped subqueries
  joined once; a Dart loop over rows is the N+1.
- pass `now` in as a parameter. A query that reads the SQL clock cannot be tested
  at its own boundary.

## Errors

`Failure` is the only error type that crosses the repository boundary. Every
repository method runs inside a guard that rethrows domain failures untouched and
maps anything else through `mapDatabaseError`. Streams too — `handleError`, or a
raw `DriftWrappedException` reaches a widget.

The UI maps the failure **type** to ARB copy, never its `message`: that string is
written for whoever reads a log and can name a table. See
`deck_labels_widget.dart` for the switch.

## Presentation

- `MxContentShell` for the screen; the `Mx*` component for anything it contains.
  No raw `Card`, styled `ListTile`, bare button, or hand-rolled empty/error
  surface when an `Mx` equivalent exists.
- no literal colour, text style, spacing, radius or duration — `ui_surfaces` is
  scoped for exactly that
- no user-visible string outside ARB; every key needs a `description`, and
  `placeholders` must come **before** `description` in the metadata block or the
  i18n rule reads the entry as undescribed
- a screen composes; it holds no query and no business rule
- a feature widget with a real second responsibility gets its own
  `_widget.dart` file **inside the feature** — never in `shared/`, which must not
  know a domain type

## Tests, and the level each belongs at

| What | Where | Against |
|---|---|---|
| SQL, cascade, transaction, rollback, invariants | `test/features/<f>/data/` | **real in-memory SQLite** — never a mocked executor |
| pure rules (validation, eligibility, arithmetic) | `test/features/<f>/domain/` | nothing — plain input/output |
| state machine, double-submit, failure mapping | `test/features/<f>/presentation/` | a fake of the **domain contract** |
| screen states, action matrix, responsive, semantics | `test/features/<f>/presentation/` | the same fake |
| routes, deep links, back, branch state | `test/app/router/` | the real router |
| colour coverage per state × theme | `test/visual_audit/screens/features/<f>/` | strict, through the real router |

**Do not drive a real Drift database from a widget test.** The stream
notification timer is still pending when the tree is torn down, and
`flutter_test` fails the test for that rather than for the behaviour. Assert
persistence in the data tests, assert the UI with a fake.

Deck's counts, as a size reference: 11 aggregate/due-parity integration · 16
domain · 12 read controller · 38 write controller · 49 widget · 6 route · 16
strict audit states.

A fake lives in `test/features/<f>/presentation/support/` and implements the
**domain contract**. Reads are supplied as *builders*, not values: a
single-subscription stream can only be listened to once, and retry listens twice.
Writes record their arguments so a widget test can assert what the form sent.

Keep files under 400 lines and 500 logical lines — `common.no_large_source_file`
and `common.max_file_lines`. Split at group boundaries, sharing the preamble, so
no fixture exists twice.

## Before you clone — the honest checklist

```bash
# nothing reaches into another feature
git grep -nE "import '[^']*features/[a-z_]+/(data|presentation)/" -- lib/features

# no literal user-visible string
flutter test test/l10n/no_hardcoded_strings_test.dart

# every gate the project actually has
.claude/skills/flutter-workflow/scripts/dod_check.sh
.claude/skills/flutter-workflow/scripts/check_docs.sh --db build/invariant_fixture_clean.db
```

Then answer the question that matters: **how many files does the clone have to
edit that are not about the new feature's subject?** For Deck → Card the answer
is zero outside `features/card/`, plus the ARB pair, plus the route table, plus
one WBS entry. If a clone would have to touch `core/` or `shared/` to make the
second feature work, that thing belonged there before the clone.

## Known guard false positive

`memox.state_management.no_generated_ref_subclass` matches the two-argument
`build` signature `ConsumerWidget` requires, reading Riverpod 3's widget-side ref
type as a Riverpod 2 generated `Ref` subclass. It fires on every `ConsumerWidget`
anyone writes.

Work around it the way Deck does — a plain widget wrapping `Consumer`, which is
better rebuild scoping anyway — and fix the rule upstream in the guard
repository, which this repo may not edit.
