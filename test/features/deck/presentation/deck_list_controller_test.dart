import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_list_now_controller.dart';
import 'package:memox/features/deck/presentation/controllers/deck_list_controller.dart';

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
    final subscription = container.listen<AsyncValue<DeckListSnapshot>>(
      deckListProvider(null),
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
      fixture.container.listen<AsyncValue<DeckListSnapshot>>(
        deckListProvider(null),
        (_, _) {},
      );
      await fixture.container.read(deckListProvider(null).future);
      expect(repository.deckListCallCount, 1);

      fixture.setNow(fixedNow.add(const Duration(hours: 3)));
      fixture.container.read(deckListNowProvider.notifier).refresh();
      await fixture.container.read(deckListProvider(null).future);

      expect(repository.deckListCallCount, 2);
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
        container.read(deckListProvider(null)),
        isA<AsyncLoading<DeckListSnapshot>>(),
      );
    });

    test('emits the summaries the repository publishes', () async {
      final container = containerWith(
        FakeDeckRepository.withSummaries(<DeckSummary>[
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

      final value = await container.read(deckListProvider(null).future);

      expect(
        value.decks.map((DeckSummary summary) => summary.deck.name),
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

      final value = await container.read(deckListProvider(null).future);

      expect(value.decks, isEmpty);
      expect(container.read(deckListProvider(null)).hasError, isFalse);
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
          container.read(deckListProvider(null).future),
          throwsA(same(failure)),
        );
        expect(
          container.read(deckListProvider(null)),
          isA<AsyncError<DeckListSnapshot>>(),
        );
      },
    );
  });

  group('subscription lifecycle', () {
    test('subscribes once, however many times the state is read', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);
      keepAlive(container);

      await container.read(deckListProvider(null).future);
      container.read(deckListProvider(null));
      container.read(deckListProvider(null));

      expect(repository.deckListCallCount, 1);
    });

    test(
      'invalidate opens a new subscription — retry genuinely retries',
      () async {
        final repository = FakeDeckRepository();
        final container = containerWith(repository);
        keepAlive(container);

        await container.read(deckListProvider(null).future);
        container.invalidate(deckListProvider(null));
        await container.read(deckListProvider(null).future);

        expect(repository.deckListCallCount, 2);
      },
    );

    test('a failed read can be retried into a successful one', () async {
      var attempt = 0;
      final repository = FakeDeckRepository(
        deckList: (_) {
          attempt += 1;
          if (attempt == 1) {
            return Stream<DeckListSnapshot>.error(
              const DatabaseFailure(message: 'read failed'),
            );
          }

          return Stream<DeckListSnapshot>.value(
            fakeListSnapshot(<DeckSummary>[
              fakeSummary(id: '1', name: 'Japanese'),
            ]),
          );
        },
      );
      final container = containerWith(repository);
      keepAlive(container);

      await expectLater(
        container.read(deckListProvider(null).future),
        throwsA(isA<DatabaseFailure>()),
      );

      container.invalidate(deckListProvider(null));
      final value = await container.read(deckListProvider(null).future);

      expect(value.decks.single.deck.name, 'Japanese');
    });

    test('disposing while the stream is still open throws nothing', () async {
      final controller = StreamController<DeckListSnapshot>();
      addTearDown(controller.close);

      final container = ProviderContainer(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          clockProvider.overrideWithValue(() => fixedNow),
          deckRepositoryProvider.overrideWithValue(
            FakeDeckRepository(deckList: (_) => controller.stream),
          ),
        ],
      );
      container.listen<AsyncValue<DeckListSnapshot>>(
        deckListProvider(null),
        (previous, next) {},
      );

      expect(container.dispose, returnsNormally);

      // An emission after disposal must not reach a torn-down provider.
      controller.add(fakeListSnapshot(const <DeckSummary>[]));
      await Future<void>.delayed(Duration.zero);
    });
  });
}
