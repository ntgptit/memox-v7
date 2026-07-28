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
│       ├── data/           # local/, remote/, model/, repository/
│       ├── domain/         # entity/, repository/, usecase/
│       └── presentation/   # screen/, widget/, state/, controller/
└── main.dart
```

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
- **Create a use case when it holds business logic or has more than one caller.**
  A use case whose entire body is `return repository.getThings()` adds a file,
  an indirection and a test for nothing. Call the repository.
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
root. It turns on `strict-casts`, `strict-inference`, `strict-raw-types`,
promotes the rules that matter to `error`, and enables the `custom_lint` plugin
that `riverpod_lint` needs.

Note that `flutter analyze` does **not** run `riverpod_lint` — that needs
`dart run custom_lint` as a separate step, in CI too. This trips people up: the
rules appear configured, and silently never run.

Nothing merges with an analyzer error. A warning you intend to keep needs an
`// ignore:` with a comment saying why — a bare ignore is a defect with a lid on
it.

## Size limits

No file of thousands of lines, no widget of hundreds. When a `build()` method
grows past roughly a screenful, split by UI section into private widget classes
— not into `Widget _buildHeader()` methods, which look like a split but keep the
whole thing rebuilding as one unit. Separate widget classes give you `const`
constructors and narrower rebuilds for free.
