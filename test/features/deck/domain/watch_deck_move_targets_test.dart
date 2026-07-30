import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/domain/usecases/watch_deck_move_targets_use_case.dart';

import '../presentation/support/fake_deck_repository.dart';

/// `WatchDeckMoveTargetsUseCase` — one read per emission.
///
/// The rule it applies is tested in `deck_move_target_test.dart`, which is pure.
/// What is tested here is the *read*: this use case used to call
/// `watchAllDecks().asyncMap(...)` and then `getDeckById(deckId)` inside the map,
/// so every emission ran a second query — for a deck that was already in the list
/// it had just been handed, read from a later snapshot.
///
/// The counts below are the assertion. A version that asks twice cannot pass them,
/// and no behavioural check on the returned targets would have noticed: with a
/// quiet database both snapshots agree, which is why the old shape looked correct
/// for as long as it did.
void main() {
  /// Two roots on the same scheduler, one with a child — enough for a real
  /// candidate list.
  ({DeckEntity source, DeckEntity target, List<DeckEntity> all}) tree() {
    final rootA = fakeRootDeck(id: 'a', name: 'A');
    final source = fakeSubDeck(
      id: 'a-child',
      name: 'Child',
      parentId: 'a',
      rootId: 'a',
    );
    final rootB = fakeRootDeck(id: 'b', name: 'B');

    return (
      source: source,
      target: rootB,
      all: <DeckEntity>[rootA, source, rootB],
    );
  }

  group('one read per emission', () {
    test('a single emission costs exactly one repository read', () async {
      final fixture = tree();
      final repository = FakeDeckRepository(
        allDecks: () => Stream<List<DeckEntity>>.value(fixture.all),
      );

      final targets = await WatchDeckMoveTargetsUseCase(repository)(
        fixture.source.id,
      ).first;

      expect(targets, isNotEmpty);
      expect(
        repository.allDecksCallCount,
        1,
        reason: 'the tree is read once, not once per candidate',
      );
    });

    test('three emissions cost three reads, not six', () async {
      // The second query used to run *per emission*, so the ratio is what shows
      // it is gone. `allDecksCallCount` counts subscriptions rather than
      // emissions, so the number that would have doubled is the one the fake can
      // no longer even record: the contract has no single-deck read left.
      final fixture = tree();
      final controller = StreamController<List<DeckEntity>>();
      addTearDown(controller.close);
      final repository = FakeDeckRepository(allDecks: () => controller.stream);

      final emissions = <List<DeckMoveTarget>>[];
      final subscription = WatchDeckMoveTargetsUseCase(repository)(
        fixture.source.id,
      ).listen(emissions.add);
      addTearDown(subscription.cancel);

      for (var i = 0; i < 3; i++) {
        controller.add(fixture.all);
        await pumpEventQueue();
      }

      expect(emissions, hasLength(3));
      expect(repository.allDecksCallCount, 1);
    });
  });

  group('the source comes from the same emission', () {
    test('a renamed source is reflected without a second read', () async {
      // The behaviour the old second query was there to provide, now provided by
      // the emission itself: `watchAllDecks` is unfiltered, so a rename of the
      // source arrives in the same list as the candidates.
      final fixture = tree();
      final renamed = fixture.source.copyWith(name: 'Renamed');
      final controller = StreamController<List<DeckEntity>>();
      addTearDown(controller.close);

      final emissions = <List<DeckMoveTarget>>[];
      final subscription = WatchDeckMoveTargetsUseCase(
        FakeDeckRepository(allDecks: () => controller.stream),
      )(fixture.source.id).listen(emissions.add);
      addTearDown(subscription.cancel);

      controller.add(fixture.all);
      await pumpEventQueue();
      controller.add(<DeckEntity>[
        for (final DeckEntity deck in fixture.all)
          if (deck.id == fixture.source.id) renamed else deck,
      ]);
      await pumpEventQueue();

      // The source is not a target of itself, so its name shows up as the
      // `itself` rejection on its own row.
      final own = emissions.last.firstWhere(
        (DeckMoveTarget t) => t.deck.id == fixture.source.id,
      );
      expect(own.deck.name, 'Renamed');
    });

    test('a source absent from the emission errors as NotFoundFailure', () async {
      // Deleted from another screen while the picker was open. Typed, so the
      // screen closes with a way back instead of listing destinations for a deck
      // that is gone.
      final fixture = tree();

      await expectLater(
        WatchDeckMoveTargetsUseCase(
          FakeDeckRepository(
            allDecks: () => Stream<List<DeckEntity>>.value(
              fixture.all
                  .where((DeckEntity d) => d.id != fixture.source.id)
                  .toList(),
            ),
          ),
        )(fixture.source.id).first,
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('an empty database errors rather than offering nothing', () async {
      // Distinguishable on purpose: "no eligible targets" is an empty list the
      // picker renders as an empty state, and "the deck is gone" is a failure. An
      // implementation that returned `const []` for a missing source would collapse
      // the two.
      await expectLater(
        WatchDeckMoveTargetsUseCase(
          FakeDeckRepository(
            allDecks: () =>
                Stream<List<DeckEntity>>.value(const <DeckEntity>[]),
          ),
        )('a-child').first,
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });
}
