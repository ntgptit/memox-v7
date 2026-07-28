---
name: flutter-testing
description: Testing strategy and patterns for this Flutter app — unit tests for use cases, repositories, mappers, validators, Drift queries and migrations and error mapping; Riverpod controller tests for state transitions; widget tests with ProviderScope covering loading/empty/error/dark-mode/text-scale; golden tests with stable rendering; and integration tests for cold start, auth, CRUD, offline and deep links. Use this skill whenever writing, fixing or reviewing any test, setting up mocks or fakes, deciding what needs test coverage, debugging a flaky or failing test, or configuring golden-test tolerances. Covers checklist phase 15.
---

# Testing

Covers checklist Phase 15.

Testing strategy in one line: **test what can be wrong, at the cheapest level
that can catch it.** A rule that can be tested as a pure function should not be
tested through a widget — a widget test that fails tells you far less about why.

Record the strategy in `docs/testing-strategy.md`, including what you have
deliberately decided not to test and why.

## Layout

```
test/
├── features/<feature>/
│   ├── domain/       use case, validation
│   ├── data/         repository, mapper, data source
│   └── presentation/ controller, widget
├── core/             error mapping, database, migrations
└── helpers/          fakes, builders, pump helpers
integration_test/     end-to-end flows
```

`mocktail` for mocks — no codegen, so a changed signature is a compile error
where it matters rather than a stale generated file.

## Unit tests

Cover use cases, repositories, mappers, validators, Drift queries, migrations
and error mapping. For each: the success path, each failure path, and the edge
cases from `docs/business-rules.md`.

The failure paths are the point. A repository test that only asserts the happy
path leaves untested exactly the code that runs when a user is having a bad day.

```dart
test('falls back to cache when the network fails', () async {
  when(() => remote.fetchDecks()).thenThrow(DioException(/* ... */));
  when(() => local.getAll()).thenAnswer((_) async => [deckDto]);

  final result = await repository.getDecks();

  expect(result, hasLength(1));
  verify(() => local.getAll()).called(1);
});

test('throws NetworkFailure when network fails and cache is empty', () async {
  when(() => remote.fetchDecks()).thenThrow(DioException(/* ... */));
  when(() => local.getAll()).thenAnswer((_) async => []);

  expect(() => repository.getDecks(), throwsA(isA<NetworkFailure>()));
});
```

**Error mapping deserves a dedicated table-driven test** — every status code and
every `DioExceptionType` mapped to its expected `Failure`. It is high-traffic
code that manual testing almost never exercises.

**Migration tests** matter more than they look. Use Drift's schema fixtures to
migrate from each released version to current, and assert the data survived. A
migration bug only shows for users with existing data — everyone except you.

## Controller tests

No widgets needed. Build a container with overrides and read the notifier:

```dart
ProviderContainer makeContainer({required DeckRepository repository}) {
  final container = ProviderContainer(
    overrides: [deckRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);   // or providers leak between tests
  return container;
}
```

Cover: initial state, loading→loaded, loading→error, refresh, submit success,
submit failure, **duplicate submit**, and **no state update after dispose**.

The last two are the ones that catch real bugs. Duplicate submit reproduces the
double-tap; the dispose test reproduces the user leaving a screen mid-request,
which throws on a disposed notifier and is otherwise found in production.

```dart
test('does not update state after dispose', () async {
  final completer = Completer<List<Deck>>();
  when(() => repository.getDecks()).thenAnswer((_) => completer.future);

  final container = makeContainer(repository: repository);
  container.read(deckListControllerProvider);
  container.dispose();

  completer.complete([deck]);
  await Future<void>.delayed(Duration.zero);
  // Passes by not throwing — a disposed notifier assigned to would throw here.
});
```

## Widget tests

Always wrap in `ProviderScope` with overrides, and in the app theme and l10n
delegates — a widget test without the theme can pass while the real screen has
no styling.

Put the wrapper in `test/helpers/` once. Every test writing its own is how they
drift apart and stop reflecting the real app.

Cover per screen: main text and actions, loading, empty, error, validation
messages, small-screen overflow, dark mode, and large text scale.

Overflow is caught by checking for an exception after pumping:

```dart
testWidgets('renders at 2x text scale without overflow', (tester) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(wrap(
    const DeckListScreen(),
    textScale: 2.0,
    overrides: [/* ... */],
  ));
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
});
```

Find by semantic label or key, not by literal text — text moves to ARB and
changes with locale, and a test asserting English strings breaks the moment a
translation lands.

## Golden tests

For shared components and screens needing pixel parity. Light and dark, at a
standard mobile size.

Goldens fail for uninteresting reasons unless the rendering environment is
pinned: load a real font in `flutter_test_config.dart` (the default Ahem font
renders as boxes), and generate on one platform — CI-generated goldens will not
match locally-generated ones.

Do not golden-test anything with uncontrolled variation — relative timestamps,
random content, network images, animations mid-flight. Freeze or inject those,
or the test fails daily and gets ignored, which is worse than not having it.

The checklist's pixel-difference threshold (under 3%) is for comparing against
the design kit. For golden regression tests between runs, keep tolerance at or
near zero — the whole point is to notice change.

## Integration tests

`integration_test/`, driving real user actions.

Cover: cold start, login and logout, main navigation, create/update/delete,
offline→online transitions, app restart with state restored, and each deep link.

Deep links and cold start are the highest-value cases here, because they are the
ones nobody exercises during development — you already have the app open and
already logged in.

Flutter Web plus Playwright is a reasonable way to run flows early and cheaply,
but it is not a substitute: platform channels, secure storage, SQLite and deep
links all behave differently. Run the suite on a real Android and iOS device
before release.

## What to test, honestly

Test business rules, state transitions, error paths, mappers, migrations and
anything with a conditional. Do not test the framework, generated code, or that
a constant equals itself.

Coverage percentage is a weak signal — a suite at 90% that never exercises a
failure path is worse than one at 60% that does. Ask which failure a test would
catch; if there is no answer, it is not earning its maintenance cost.
