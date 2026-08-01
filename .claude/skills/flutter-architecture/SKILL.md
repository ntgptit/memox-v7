---
name: flutter-architecture
description: The layering and code-style rules for this Flutter codebase — feature-first folder structure, what each layer may import, when a use case or an interface is actually worth creating, the analysis_options.yaml lint configuration, guard-clause control flow, banning magic values, and file/class naming conventions. Use this skill when creating a new feature folder, deciding where a file belongs, reviewing whether code respects layer boundaries, configuring or tightening lints, resolving an import that feels wrong, or when tempted to add an abstraction. Also use it before any code review or commit that adds new files. Covers checklist phases 4 and 5, and it ships `scripts/check_architecture.sh` to verify the boundaries mechanically.
---

# Architecture and code conventions

Covers checklist Phases 4 (structure, dependency rules) and 5 (lint, code style,
naming).

## Folder structure

```
lib/
├── app/
│   ├── app.dart            # MaterialApp.router, theme wiring
│   ├── bootstrap.dart      # startup sequence, error boundaries
│   ├── router/             # GoRouter config, route paths, guards
│   └── config/             # EnvConfig and flavor definitions
├── core/                   # cross-cutting infrastructure, no feature logic
│   ├── error/              # Failure hierarchy + exception→failure mapping
│   ├── network/            # Dio client, interceptors
│   ├── database/           # Drift database, migrations
│   ├── storage/            # secure storage, preferences
│   ├── logging/            # logger abstraction
│   ├── theme/              # tokens, ThemeData
│   ├── localization/       # ARB setup, l10n helpers
│   └── utils/              # genuinely generic helpers
├── shared/                 # reusable across features
│   ├── widgets/            # design-system components
│   ├── models/             # shared value types
│   └── extensions/
├── features/
│   └── <feature>/
│       ├── data/           # repositories/, mappers/, datasources/, models/
│       ├── domain/         # entities/, repositories/, models/, usecases/, failures/
│       └── presentation/   # screens/, controllers/, states/, widgets/, providers/
│           └── widgets/    # exactly four buckets, one level deep (AD-15):
│                           #   sections/ items/ overlays/ support/
└── main.dart
```

**Placing a widget** is four questions asked in order, stopping at the first
yes — the full contract, the rationale and the rejected alternatives are AD-15
in `docs/architecture.md`:

1. Does it open *over* the screen (`showModalBottomSheet`/`showDialog`)? → `overlays/`
2. Is it the repeated row of a list, or a part only that row uses? → `items/`
3. Does the screen compose it directly into its body or chrome? → `sections/`
4. Does it serve more than one bucket above (ARB mapping, render-only extension)? → `support/`

Nothing sits directly in `widgets/`, buckets never nest, a bucket is created
only when it has real content, and the bucket list is app-wide: a fifth name is
an AD-15 change, not a new folder. `architecture_boundary_test.dart` owns the
full shape; the guard rule `memox.architecture.widgets_grouped_into_buckets` is
the second net.

`core/` is infrastructure with no knowledge of any feature. The moment
`core/network/` mentions a specific endpoint, or `core/database/` imports a
feature entity, the boundary has broken — that code belongs in the feature.

## Dependency rules

```
presentation ──► domain ◄── data
        (never presentation ──► data)
```

- **domain** imports Dart and other domain code. Not Flutter, not Dio, not
  Drift, not `json_annotation`. The test is simple: a domain file must compile
  in a plain Dart package. If it needs `package:flutter` for `@immutable` or
  `Color`, restructure — `@immutable` can come from `meta`, and a `Color` in a
  domain entity means a UI concept leaked into the model.
- **data** implements the repository contracts declared in domain, and depends
  on domain. Never the reverse.
- **presentation** talks to use cases, or to repository contracts directly when
  there is no use case. Never to a data source, never to Drift, never to Dio.
- **features are islands.** A feature may not import another feature's `data/`
  or `presentation/`. If two features need the same thing, it moves to `shared/`
  or `core/`, or one feature exposes a domain-level contract the other depends
  on. Cross-feature imports are how a codebase becomes impossible to change.
- **no cycles.** If A needs B and B needs A, extract the shared piece.

Verify mechanically rather than by eye:

```bash
.claude/skills/flutter-architecture/scripts/check_architecture.sh
```

## Pragmatic, not ceremonial

Clean Architecture here is a means, not the goal. The checklist says so
explicitly, and it is the part most often ignored:

- **Not every feature needs every layer.** A settings screen that toggles a
  local preference does not need an entity, a contract, an implementation and a
  use case to wrap one boolean. It needs a controller and a storage call.
- **A feature that has a `usecases/` folder gets one use case per interaction**
  (AD-12). This is a deliberate change from the older rule below, made by the
  project owner before the second feature was cloned: uniformity is what turns a
  new feature into a clone rather than a judgement call at every operation. Six of
  Deck's ten hold the input validation that used to run twice — once in a
  controller and once again in the repository. Four are thin, and that is the
  accepted cost.

  The older rule still applies to a feature small enough not to have the folder at
  all: a settings toggle needs a controller and a storage call, not five layers.
  What changed is that *within* a Clean Architecture feature, the layer is uniform.

- **A rule that needs the data as it stands at the moment of writing does not go
  in a use case.** Depth limits, first-child locks, emptiness checks and subtree
  moves run inside `runInTransaction`. Hoisting one above the repository puts the
  check outside the transaction — a race between the check and the write. Tidier
  place, wrong answer.
- **Do not write an interface for a single implementation you will never
  swap.** The exception that earns its keep is the repository contract, because
  it is what lets domain stay framework-free and lets tests substitute fakes.
  Beyond that, wait for the second implementation.
- **Do not build for imagined scale.** The cost of adding a layer later, once
  the need is real, is nearly always lower than the cost of carrying an unused
  one through every change.

When you deviate from the standard shape, write one line in
`docs/architecture.md` saying what and why. The next person then reads a
decision instead of an inconsistency.

## Control flow

Guard clauses, early return, fail fast:

```dart
Future<Deck> loadDeck(String id) async {
  if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');

  final deck = await _repository.findById(id);
  if (deck == null) throw const NotFoundFailure(message: 'Deck not found');

  return deck;
}
```

Avoid `else`. An `else` almost always means the guard was written as a branch
instead of an exit — invert the condition and return early. Nested conditionals
are the readability problem this rule exists to prevent; after three levels
nobody reliably tracks which branch they are in.

`switch` on a sealed class or enum is the exception, and is encouraged — with no
`default` clause, so that adding a variant produces a compile error at every
place that must handle it. A `default` throws that safety away.

Never `catch (_) {}`. If a failure is genuinely ignorable, catch the specific
exception type and write the reason:

```dart
try {
  await _analytics.log(event);
} on AnalyticsException catch (e, s) {
  // Analytics must never break a user flow; log and continue.
  _logger.warning('analytics failed', e, s);
}
```

## No magic values

Any string or number carrying meaning goes in a named const, an enum or a
sealed class. This includes route paths, storage keys, API paths, retry counts,
page sizes, animation durations and every spacing value.

Finite state is an enum or sealed class — never loose strings, and never a set
of booleans. Three booleans encode eight states, of which perhaps three are
legal; the other five will eventually happen.

## Naming

Files are `snake_case` ending in the suffix that states the role:
`*_screen.dart`, `*_widget.dart`, `*_controller.dart`, `*_state.dart`,
`*_repository.dart` (contract), `*_repository_impl.dart` (implementation),
`*_use_case.dart`, `*_model.dart` (DTO), `*_entity.dart` (domain).

The `_model` / `_entity` split is load-bearing: `_model` is the wire or database
shape and may change when the API changes; `_entity` is the domain shape and
should not. Naming them apart keeps people from passing a DTO into the UI.

Booleans read as predicates: `isLoading`, `hasError`, `canSubmit`,
`shouldRetry`. Avoid `Utils`, `Manager`, `Helper` — they attract unrelated code
because nothing is out of scope for a name that means nothing.

## Lint

`references/analysis_options.yaml` is the configuration to copy into the project
root. It turns on `strict-casts`, `strict-inference`, `strict-raw-types`, and
promotes the rules that matter to `error`.

It deliberately does **not** declare a `custom_lint` plugin. `custom_lint` and
`riverpod_lint` are descoped — see `Deferred and descoped` in `docs/wbs.md`. Do
not add the block back: a plugin declared but not installed is silently ignored,
so the rules look configured and never run.

The Riverpod checks that `riverpod_lint` used to provide — `ref.read` inside
`build()` being the one that matters most — are now owned by
**code-verification-guard**, run as a separate gate:

```bash
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7
```

Nothing merges with an analyzer error. A warning you intend to keep needs an
`// ignore:` with a comment saying why — a bare ignore is a defect with a lid on
it.

## Size limits

No file of thousands of lines, no widget of hundreds. When a `build()` method
grows past roughly a screenful, split by UI section into private widget classes
— not into `Widget _buildHeader()` methods, which look like a split but keep the
whole thing rebuilding as one unit. Separate widget classes give you `const`
constructors and narrower rebuilds for free.
