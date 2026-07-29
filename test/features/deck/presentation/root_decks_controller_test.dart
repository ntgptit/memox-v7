import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/di/deck_repository_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/deck_entity.dart';
import 'package:memox/features/deck/presentation/root_decks_controller.dart';

import 'support/fake_deck_repository.dart';

/// `rootDecksProvider`, driven through the domain contract.
///
/// Every test builds its own container. A shared one would carry a live Drift
/// subscription — and the `keepAlive` repository behind it — into the next
/// test, and the failure would surface in an unrelated file.
void main() {
  /// A container wired to [repository] and disposed with the test.
  ///
  /// `envConfigProvider` is overridden because its root implementation throws
  /// on purpose; without it nothing in the tree can be read at all.
  ProviderContainer containerWith(FakeDeckRepository repository) {
    final container = ProviderContainer(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        deckRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    return container;
  }

  /// Subscribes so the provider stays alive for the length of the test.
  ///
  /// Without a listener an autoDispose provider is torn down between reads, so
  /// every assertion would observe a fresh subscription rather than the one
  /// under test — which is precisely what the subscription-count tests measure.
  void keepAlive(ProviderContainer container) {
    final subscription = container.listen<AsyncValue<List<DeckEntity>>>(
      rootDecksProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);
  }

  group('reading', () {
    test('starts in loading before the stream has answered', () {
      final container = containerWith(FakeDeckRepository.pending());
      keepAlive(container);

      expect(
        container.read(rootDecksProvider),
        isA<AsyncLoading<List<DeckEntity>>>(),
      );
    });

    test('emits the decks the repository publishes', () async {
      final decks = <DeckEntity>[
        fakeRootDeck(id: 'deck-1', name: 'Japanese'),
        fakeRootDeck(id: 'deck-2', name: 'Spanish'),
      ];
      final container = containerWith(FakeDeckRepository.emitting(decks));
      keepAlive(container);

      final value = await container.read(rootDecksProvider.future);

      expect(value.map((deck) => deck.name), <String>['Japanese', 'Spanish']);
    });

    test('an empty tree is data, not an error', () async {
      // The distinction the empty state depends on: "you have no decks" is a
      // successful read, and rendering it as a failure tells the user something
      // is broken when nothing is.
      final container = containerWith(
        FakeDeckRepository.emitting(const <DeckEntity>[]),
      );
      keepAlive(container);

      final value = await container.read(rootDecksProvider.future);

      expect(value, isEmpty);
      expect(container.read(rootDecksProvider).hasError, isFalse);
    });

    test('a stream failure surfaces as an error state', () async {
      const failure = DatabaseFailure(message: 'read failed');
      final container = containerWith(FakeDeckRepository.failing(failure));
      keepAlive(container);

      await expectLater(
        container.read(rootDecksProvider.future),
        throwsA(same(failure)),
      );
      expect(container.read(rootDecksProvider).error, same(failure));

      // The state *type*, not just the error, because that is what pins the
      // `noAutomaticRetry` decision. Riverpod's default retry ladder reports
      // `AsyncLoading(retrying: true)` for the whole ~13 seconds it spends
      // backing off, so re-enabling it would silently turn this screen's error
      // state into a very long spinner — and would hang the `expectLater`
      // above rather than failing it quickly.
      expect(
        container.read(rootDecksProvider),
        isA<AsyncError<List<DeckEntity>>>(),
      );
    });
  });

  group('subscription lifecycle', () {
    test('subscribes once, however many times the state is read', () async {
      final repository = FakeDeckRepository.emitting(const <DeckEntity>[]);
      final container = containerWith(repository);
      keepAlive(container);

      await container.read(rootDecksProvider.future);
      container.read(rootDecksProvider);
      container.read(rootDecksProvider);

      // A second subscription would mean a second Drift `watch()` per screen,
      // which is invisible until the query gets expensive.
      expect(repository.watchRootDecksCallCount, 1);
    });

    test(
      'invalidate opens a new subscription — retry genuinely retries',
      () async {
        final repository = FakeDeckRepository.emitting(const <DeckEntity>[]);
        final container = containerWith(repository);
        keepAlive(container);

        await container.read(rootDecksProvider.future);
        container.invalidate(rootDecksProvider);
        await container.read(rootDecksProvider.future);

        expect(repository.watchRootDecksCallCount, 2);
      },
    );

    test('a failed read can be retried into a successful one', () async {
      // The behaviour the error state's button promises. Built as a builder
      // rather than a stored stream because the first listen is consumed.
      var attempt = 0;
      final repository = FakeDeckRepository(() {
        attempt += 1;
        if (attempt == 1) {
          return Stream<List<DeckEntity>>.error(
            const DatabaseFailure(message: 'read failed'),
          );
        }

        return Stream<List<DeckEntity>>.value(<DeckEntity>[
          fakeRootDeck(id: 'deck-1', name: 'Japanese'),
        ]);
      });
      final container = containerWith(repository);
      keepAlive(container);

      await expectLater(
        container.read(rootDecksProvider.future),
        throwsA(isA<DatabaseFailure>()),
      );

      container.invalidate(rootDecksProvider);
      final value = await container.read(rootDecksProvider.future);

      expect(value.single.name, 'Japanese');
    });

    test('disposing while the stream is still open throws nothing', () async {
      final controller = StreamController<List<DeckEntity>>();
      addTearDown(controller.close);

      final container = ProviderContainer(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(
            FakeDeckRepository(() => controller.stream),
          ),
        ],
      );
      container.listen<AsyncValue<List<DeckEntity>>>(
        rootDecksProvider,
        (previous, next) {},
      );

      expect(container.dispose, returnsNormally);

      // An emission after disposal must not reach a torn-down provider. It is
      // the shape that shows up as "setState called after dispose" once a real
      // Drift stream is behind it.
      controller.add(const <DeckEntity>[]);
      await Future<void>.delayed(Duration.zero);
    });
  });
}
