import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/di/deck_repository_provider.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/root_deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/root_deck_summary_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_list_now_controller.dart';
import 'package:memox/features/deck/presentation/controllers/root_deck_list_controller.dart';

import 'support/fake_deck_repository.dart';

/// The root-list read providers, driven through the domain contract.
///
/// Every test builds its own container. A shared one would carry a live Drift
/// subscription — and the `keepAlive` repository behind it — into the next test,
/// and the failure would surface in an unrelated file.
void main() {
  /// A fixed instant. Nothing here reads the wall clock, so the `now` the
  /// aggregate is measured against is a value a test can assert on.
  final fixedNow = DateTime.utc(2026, 7, 29, 12);

  ProviderContainer containerWith(FakeDeckRepository repository) {
    final container = ProviderContainer(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        deckRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => fixedNow),
      ],
    );
    addTearDown(container.dispose);

    return container;
  }

  /// A container whose clock the test can move, for the cases that need a
  /// re-measure to land at a genuinely different instant.
  ({ProviderContainer container, void Function(DateTime) setNow}) containerAt(
    DateTime start,
    FakeDeckRepository repository,
  ) {
    var current = start;
    final container = ProviderContainer(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        deckRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => current),
      ],
    );
    addTearDown(container.dispose);

    return (container: container, setNow: (DateTime at) => current = at);
  }

  /// Subscribes so the provider stays alive for the length of the test.
  void keepAlive(ProviderContainer container) {
    final subscription = container.listen<AsyncValue<RootDeckListSnapshot>>(
      rootDeckListProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);
  }

  group('re-measuring', () {
    test('a new boundary re-reads the aggregate', () async {
      // What makes both triggers work — resume and the due-boundary timer. Neither
      // does anything unless moving the instant opens a new read, and this is that
      // link on its own.
      final repository = FakeDeckRepository();
      final fixture = containerAt(fixedNow, repository);
      fixture.container.listen<AsyncValue<RootDeckListSnapshot>>(
        rootDeckListProvider,
        (_, _) {},
      );
      await fixture.container.read(rootDeckListProvider.future);
      expect(repository.summariesCallCount, 1);

      fixture.setNow(fixedNow.add(const Duration(hours: 3)));
      fixture.container.read(deckListNowProvider.notifier).refresh();
      await fixture.container.read(rootDeckListProvider.future);

      expect(repository.summariesCallCount, 2);
      expect(repository.readInstants, <DateTime>[
        fixedNow,
        fixedNow.add(const Duration(hours: 3)),
      ]);
    });
  });

  group('reading', () {
    test('starts in loading before the stream has answered', () {
      final container = containerWith(FakeDeckRepository.pending());
      keepAlive(container);

      expect(
        container.read(rootDeckListProvider),
        isA<AsyncLoading<RootDeckListSnapshot>>(),
      );
    });

    test('emits the summaries the repository publishes', () async {
      final container = containerWith(
        FakeDeckRepository.withSummaries(<RootDeckSummary>[
          fakeSummary(
            id: '1',
            name: 'Japanese',
            totalCardCount: 12,
            dueCardCount: 3,
          ),
          fakeSummary(id: '2', name: 'Spanish'),
        ]),
      );
      keepAlive(container);

      final value = await container.read(rootDeckListProvider.future);

      expect(
        value.decks.map((RootDeckSummary summary) => summary.deck.name),
        <String>['Japanese', 'Spanish'],
      );
      expect(value.decks.first.totalCardCount, 12);
      expect(value.decks.first.dueCardCount, 3);
      expect(value.decks.first.hasDueCards, isTrue);
      expect(value.decks.last.hasDueCards, isFalse);
    });

    test('an empty tree is data, not an error (BR-29)', () async {
      final container = containerWith(FakeDeckRepository());
      keepAlive(container);

      final value = await container.read(rootDeckListProvider.future);

      expect(value.decks, isEmpty);
      expect(container.read(rootDeckListProvider).hasError, isFalse);
    });

    test(
      'a stream failure reaches the UI as an error, not as a spinner',
      () async {
        // Pins `noAutomaticRetry`. Riverpod's default retry ladder reports
        // `AsyncLoading(retrying: true)` for the ~13 seconds it spends backing
        // off, so re-enabling it would turn this screen's error state into a very
        // long spinner — and would hang the `expectLater` below rather than fail
        // it quickly.
        const failure = DatabaseFailure(message: 'read failed');
        final container = containerWith(FakeDeckRepository.failing(failure));
        keepAlive(container);

        await expectLater(
          container.read(rootDeckListProvider.future),
          throwsA(same(failure)),
        );
        expect(
          container.read(rootDeckListProvider),
          isA<AsyncError<RootDeckListSnapshot>>(),
        );
      },
    );
  });

  group('subscription lifecycle', () {
    test('subscribes once, however many times the state is read', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);
      keepAlive(container);

      await container.read(rootDeckListProvider.future);
      container.read(rootDeckListProvider);
      container.read(rootDeckListProvider);

      expect(repository.summariesCallCount, 1);
    });

    test(
      'invalidate opens a new subscription — retry genuinely retries',
      () async {
        final repository = FakeDeckRepository();
        final container = containerWith(repository);
        keepAlive(container);

        await container.read(rootDeckListProvider.future);
        container.invalidate(rootDeckListProvider);
        await container.read(rootDeckListProvider.future);

        expect(repository.summariesCallCount, 2);
      },
    );

    test('a failed read can be retried into a successful one', () async {
      var attempt = 0;
      final repository = FakeDeckRepository(
        summaries: () {
          attempt += 1;
          if (attempt == 1) {
            return Stream<RootDeckListSnapshot>.error(
              const DatabaseFailure(message: 'read failed'),
            );
          }

          return Stream<RootDeckListSnapshot>.value(
            fakeListSnapshot(<RootDeckSummary>[
              fakeSummary(id: '1', name: 'Japanese'),
            ]),
          );
        },
      );
      final container = containerWith(repository);
      keepAlive(container);

      await expectLater(
        container.read(rootDeckListProvider.future),
        throwsA(isA<DatabaseFailure>()),
      );

      container.invalidate(rootDeckListProvider);
      final value = await container.read(rootDeckListProvider.future);

      expect(value.decks.single.deck.name, 'Japanese');
    });

    test('disposing while the stream is still open throws nothing', () async {
      final controller = StreamController<RootDeckListSnapshot>();
      addTearDown(controller.close);

      final container = ProviderContainer(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          clockProvider.overrideWithValue(() => fixedNow),
          deckRepositoryProvider.overrideWithValue(
            FakeDeckRepository(summaries: () => controller.stream),
          ),
        ],
      );
      container.listen<AsyncValue<RootDeckListSnapshot>>(
        rootDeckListProvider,
        (previous, next) {},
      );

      expect(container.dispose, returnsNormally);

      // An emission after disposal must not reach a torn-down provider.
      controller.add(fakeListSnapshot(const <RootDeckSummary>[]));
      await Future<void>.delayed(Duration.zero);
    });
  });

  group('the due boundary', () {
    /// A container whose clock advances itself to whatever instant it is asked
    /// for, driven inside `testWidgets` so `Timer` runs on fake time.
    ///
    /// The clock has to move when the timer fires, or the test proves nothing: a
    /// re-measure at the same instant reads the same counts and the guard in
    /// `_armBoundary` would then refuse to re-arm. So `setNow` is called from the
    /// test as it pumps, mirroring what a real clock does while a real timer waits.
    ({ProviderContainer container, void Function(DateTime) setNow}) driven(
      FakeDeckRepository repository, {
      required DateTime start,
    }) {
      var current = start;
      final container = ProviderContainer(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => current),
        ],
      );
      addTearDown(container.dispose);
      container.listen<AsyncValue<RootDeckListSnapshot>>(
        rootDeckListProvider,
        (_, _) {},
      );

      return (container: container, setNow: (DateTime at) => current = at);
    }

    /// A repository whose snapshot always claims the same next boundary.
    FakeDeckRepository servingBoundary(DateTime? nextDueAt) =>
        FakeDeckRepository(
          summaries: () => Stream<RootDeckListSnapshot>.value(
            fakeListSnapshot(<RootDeckSummary>[
              fakeSummary(id: '1', name: 'Japanese', totalCardCount: 4),
            ], nextDueAt: nextDueAt),
          ),
        );

    testWidgets('a boundary in the future re-reads when it is crossed', (
      tester,
    ) async {
      // The bug this fixes: the user sits on the list, a card comes due, and the
      // badge keeps saying what it said an hour ago. Resume was the only trigger.
      final DateTime boundary = fixedNow.add(const Duration(minutes: 30));
      final repository = servingBoundary(boundary);
      final fixture = driven(repository, start: fixedNow);
      await tester.pump();
      expect(repository.summariesCallCount, 1);

      // Not yet. A timer that fired early would re-read for nothing.
      await tester.pump(const Duration(minutes: 29));
      expect(repository.summariesCallCount, 1);

      fixture.setNow(boundary.add(const Duration(seconds: 1)));
      await tester.pump(const Duration(minutes: 2));

      expect(repository.summariesCallCount, 2);
      expect(
        repository.readInstants.last,
        boundary.add(const Duration(seconds: 1)),
        reason: 'the re-read must measure against the new instant, not the old',
      );
    });

    testWidgets('no boundary means no timer at all', (tester) async {
      // Nothing scheduled to come due — no cards, or every card already due. A
      // periodic timer would wake here anyway; this one does not exist.
      final repository = servingBoundary(null);
      driven(repository, start: fixedNow);
      await tester.pump();

      await tester.pump(const Duration(days: 2));

      expect(repository.summariesCallCount, 1);
      // `flutter_test` fails a test that leaves a Timer pending, so reaching the
      // end of this one is itself the assertion that none was armed.
    });

    testWidgets('a boundary past the ceiling still re-measures', (
      tester,
    ) async {
      // `kMaxDueBoundaryDelay` exists because a `setTimeout` delay is a 32-bit
      // millisecond count on the web. A boundary beyond it must degrade to one
      // wake at the ceiling, not to a timer that fires immediately and forever.
      final repository = servingBoundary(
        fixedNow.add(const Duration(days: 400)),
      );
      final fixture = driven(repository, start: fixedNow);
      await tester.pump();
      expect(repository.summariesCallCount, 1);

      fixture.setNow(fixedNow.add(kMaxDueBoundaryDelay));
      await tester.pump(kMaxDueBoundaryDelay + const Duration(seconds: 1));

      expect(repository.summariesCallCount, 2);
      expect(repository.readInstants.last, fixedNow.add(kMaxDueBoundaryDelay));

      // Disposed here rather than in a tear-down, because this is the one case
      // that *does* leave a timer armed: 399 days still remain, so the ceiling
      // fires again. `flutter_test` asserts on pending timers before tear-downs
      // run, and that assertion is worth keeping — so the test says explicitly
      // that it is ending a still-running schedule.
      fixture.container.dispose();
    });

    testWidgets('disposing cancels the pending wake-up', (tester) async {
      final repository = servingBoundary(
        fixedNow.add(const Duration(minutes: 30)),
      );
      final fixture = driven(repository, start: fixedNow);
      await tester.pump();

      fixture.container.dispose();
      await tester.pump(const Duration(hours: 2));

      expect(
        repository.summariesCallCount,
        1,
        reason:
            'a timer surviving disposal would read through a torn-down '
            'provider',
      );
    });

    testWidgets('one emission never leaves two timers pending', (tester) async {
      // Each rebuild re-arms. If the previous timer were not cancelled, the
      // wake-ups would multiply with every re-read — the failure mode that makes a
      // timer bug look like a performance problem months later.
      final DateTime boundary = fixedNow.add(const Duration(minutes: 10));
      final repository = servingBoundary(boundary);
      final fixture = driven(repository, start: fixedNow);
      await tester.pump();

      // Three rebuilds, each arming a timer for the same boundary.
      for (var i = 1; i <= 3; i++) {
        fixture.setNow(fixedNow.add(Duration(seconds: i)));
        fixture.container.read(deckListNowProvider.notifier).refresh();
        await tester.pump();
      }
      final int readsBeforeBoundary = repository.summariesCallCount;

      fixture.setNow(boundary.add(const Duration(seconds: 1)));
      await tester.pump(const Duration(minutes: 11));

      expect(
        repository.summariesCallCount,
        readsBeforeBoundary + 1,
        reason: 'exactly one wake-up fired, however many times it was re-armed',
      );
    });
  });
}
