import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/di/deck_repository_provider.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/root_deck_summary_model.dart';
import 'package:memox/features/deck/presentation/controllers/root_decks_controller.dart';

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

  /// Subscribes so the provider stays alive for the length of the test.
  void keepAlive(ProviderContainer container) {
    final subscription = container.listen<AsyncValue<List<RootDeckSummary>>>(
      rootDeckSummariesProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);
  }

  group('the clock', () {
    test('is injected, never read from the wall clock', () {
      final container = containerWith(FakeDeckRepository());

      expect(container.read(deckListNowProvider), fixedNow);
    });

    test('refresh re-measures it', () {
      var current = fixedNow;
      final container = ProviderContainer(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          clockProvider.overrideWithValue(() => current),
        ],
      );
      addTearDown(container.dispose);
      container.listen<DateTime>(deckListNowProvider, (previous, next) {});

      current = fixedNow.add(const Duration(hours: 3));
      container.read(deckListNowProvider.notifier).refresh();

      expect(
        container.read(deckListNowProvider),
        fixedNow.add(const Duration(hours: 3)),
      );
    });

    test('a new boundary re-reads the aggregate', () async {
      // What makes a resume update the due counts: the summary provider watches
      // the instant, so moving it opens a new read.
      var current = fixedNow;
      final repository = FakeDeckRepository();
      final container = ProviderContainer(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => current),
        ],
      );
      addTearDown(container.dispose);
      container.listen<AsyncValue<List<RootDeckSummary>>>(
        rootDeckSummariesProvider,
        (previous, next) {},
      );
      await container.read(rootDeckSummariesProvider.future);
      expect(repository.summariesCallCount, 1);

      current = fixedNow.add(const Duration(hours: 3));
      container.read(deckListNowProvider.notifier).refresh();
      await container.read(rootDeckSummariesProvider.future);

      expect(repository.summariesCallCount, 2);
    });
  });

  group('reading', () {
    test('starts in loading before the stream has answered', () {
      final container = containerWith(FakeDeckRepository.pending());
      keepAlive(container);

      expect(
        container.read(rootDeckSummariesProvider),
        isA<AsyncLoading<List<RootDeckSummary>>>(),
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

      final value = await container.read(rootDeckSummariesProvider.future);

      expect(value.map((summary) => summary.deck.name), <String>[
        'Japanese',
        'Spanish',
      ]);
      expect(value.first.totalCardCount, 12);
      expect(value.first.dueCardCount, 3);
      expect(value.first.hasDueCards, isTrue);
      expect(value.last.hasDueCards, isFalse);
    });

    test('an empty tree is data, not an error (BR-29)', () async {
      final container = containerWith(FakeDeckRepository());
      keepAlive(container);

      final value = await container.read(rootDeckSummariesProvider.future);

      expect(value, isEmpty);
      expect(container.read(rootDeckSummariesProvider).hasError, isFalse);
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
          container.read(rootDeckSummariesProvider.future),
          throwsA(same(failure)),
        );
        expect(
          container.read(rootDeckSummariesProvider),
          isA<AsyncError<List<RootDeckSummary>>>(),
        );
      },
    );
  });

  group('subscription lifecycle', () {
    test('subscribes once, however many times the state is read', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);
      keepAlive(container);

      await container.read(rootDeckSummariesProvider.future);
      container.read(rootDeckSummariesProvider);
      container.read(rootDeckSummariesProvider);

      expect(repository.summariesCallCount, 1);
    });

    test(
      'invalidate opens a new subscription — retry genuinely retries',
      () async {
        final repository = FakeDeckRepository();
        final container = containerWith(repository);
        keepAlive(container);

        await container.read(rootDeckSummariesProvider.future);
        container.invalidate(rootDeckSummariesProvider);
        await container.read(rootDeckSummariesProvider.future);

        expect(repository.summariesCallCount, 2);
      },
    );

    test('a failed read can be retried into a successful one', () async {
      var attempt = 0;
      final repository = FakeDeckRepository(
        summaries: () {
          attempt += 1;
          if (attempt == 1) {
            return Stream<List<RootDeckSummary>>.error(
              const DatabaseFailure(message: 'read failed'),
            );
          }

          return Stream<List<RootDeckSummary>>.value(<RootDeckSummary>[
            fakeSummary(id: '1', name: 'Japanese'),
          ]);
        },
      );
      final container = containerWith(repository);
      keepAlive(container);

      await expectLater(
        container.read(rootDeckSummariesProvider.future),
        throwsA(isA<DatabaseFailure>()),
      );

      container.invalidate(rootDeckSummariesProvider);
      final value = await container.read(rootDeckSummariesProvider.future);

      expect(value.single.deck.name, 'Japanese');
    });

    test('disposing while the stream is still open throws nothing', () async {
      final controller = StreamController<List<RootDeckSummary>>();
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
      container.listen<AsyncValue<List<RootDeckSummary>>>(
        rootDeckSummariesProvider,
        (previous, next) {},
      );

      expect(container.dispose, returnsNormally);

      // An emission after disposal must not reach a torn-down provider.
      controller.add(const <RootDeckSummary>[]);
      await Future<void>.delayed(Duration.zero);
    });
  });
}
