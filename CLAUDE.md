# memox-v7

Flutter application, rebuilt from scratch against `docs/checklist.md`.

**Stack:** Flutter (stable) · Riverpod 3.x + codegen · GoRouter · Dio · Drift/SQLite · Material 3 + design tokens
**Architecture:** Pragmatic Clean Architecture, feature-first.

## How work is driven here

`docs/checklist.md` is the canonical 22-phase plan. `docs/wbs.md` is the live
progress ledger — it is the single source of truth for what is done, in flight,
and blocked. Update it in the same commit as the code it describes; a WBS that
lags the code is worse than no WBS, because the next session trusts it.

The `.claude/skills/` directory holds one skill per area of the checklist. Start
with **flutter-workflow** when you do not know which phase you are in — it routes
to the right skill and refuses to let phases run out of order.

Phases run in dependency order, not checklist order: business requirements →
use cases → WBS → foundation → architecture boundaries → theme/tokens → minimal
shared components → router → data foundation → features as vertical slices →
tests → CI/CD → release. Do not build UI for a flow whose business rules are
still open; the rework costs more than the wait.

## Non-negotiables

These are the rules that survive every phase. Everything else is guidance.

**Layering.** `domain/` imports no Flutter, no Dio, no Drift — only Dart and
other domain code. If a domain file needs `package:flutter`, the abstraction is
wrong. `data/` implements domain contracts. `presentation/` talks to use cases or
repository contracts, never to a data source directly. Features never import
another feature's `data/` or `presentation/` internals.

**Control flow.** Guard clauses, early return, fail fast. Avoid `else` — an
`else` branch usually means a guard clause was skipped. Never swallow errors
with `catch (_) {}`; if a failure is genuinely ignorable, catch it narrowly and
say why in a comment.

**No magic values.** Strings and numbers that carry meaning belong in a const, an
enum, or a sealed class. Finite states are enums or sealed classes, never loose
strings or a pile of booleans.

**UI discipline.** No business logic in `build()`. No API calls or database
access from a widget. No hardcoded colors, text styles, or padding — everything
comes from design tokens. No user-visible string outside the ARB files.

**State.** Immutable. Data and task-status are separate concerns — one
`isLoading` boolean for every operation on a screen is a bug waiting to happen.
Controllers never hold a `BuildContext`.

**Errors.** Data-layer exceptions map to a domain `Failure` at the repository
boundary. The UI never sees a `DioException`. User-facing messages never leak
stack traces, URLs, or SQL.

**Security.** Tokens live in secure storage and are cleared on logout. No
secrets in the repo. No sensitive data in logs, at any level.

## Naming

Files are `snake_case` with a suffix that states the role: `*_screen.dart`,
`*_widget.dart`, `*_controller.dart`, `*_state.dart`, `*_repository.dart`,
`*_repository_impl.dart`, `*_use_case.dart`, `*_model.dart`, `*_entity.dart`.
Booleans read as predicates: `isX`, `hasX`, `canX`, `shouldX`. Avoid `Utils`,
`Manager`, `Helper` unless the responsibility is genuinely that and is named
precisely.

## Definition of Done

No task is done until: scope matches the WBS entry, acceptance criteria pass,
`dart format` clean, `flutter analyze` clean (zero errors *and* warnings),
related tests pass, UI uses tokens and was checked in light + dark + small
screen + large text scale, loading/empty/error/success all covered, basic
accessibility checked, docs and WBS updated, CI green.

Run `.claude/skills/flutter-workflow/scripts/dod_check.sh` for the mechanical
half of that list. The judgement half is still yours.

## Commits

Conventional Commits: `feat(auth): ...`, `fix(sync): ...`, `chore(deps): ...`.
Scope is the feature name. Keep PRs small and single-purpose — no drive-by
refactors outside the stated scope.
