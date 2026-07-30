import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/card_entity.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/data/datasources/deck_dao.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../../../database/invariant_queries.dart';
import '../../../database/support/test_database.dart';
import 'support/deck_repository_harness.dart';

/// Stream and failure-boundary integration tests, plus the invariant sweep
/// over repository-written data. Part of the suite rooted in
/// `deck_repository_impl_test.dart`.
void main() {
  final h = installDeckRepositoryHarness();

  group('watch()', () {
    test('emits the current value on listen', () async {
      await h.deckRepository.createRootDeck(
        name: DeckName.parseOrThrow('Existing'),
        schedulerType: SchedulerType.eightBox,
      );

      final emissions = <List<DeckEntity>>[];
      final subscription = h.deckRepository.watchRootDecks().listen(
        emissions.add,
      );
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      expect(emissions, isNotEmpty);
      expect(emissions.first.map((DeckEntity d) => d.name), <String>[
        'Existing',
      ]);
    });

    test('re-emits after an insert', () async {
      final emissions = <List<DeckEntity>>[];
      final subscription = h.deckRepository.watchRootDecks().listen(
        emissions.add,
      );
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(emissions.last, isEmpty);

      await h.deckRepository.createRootDeck(
        name: DeckName.parseOrThrow('Fresh'),
        schedulerType: SchedulerType.sm2,
      );
      await pumpEventQueue();

      expect(emissions.last.map((DeckEntity d) => d.name), <String>['Fresh']);
    });

    test('re-emits after an update', () async {
      final root = await h.deckRepository.createRootDeck(
        name: DeckName.parseOrThrow('Before'),
        schedulerType: SchedulerType.eightBox,
      );
      final emissions = <List<DeckEntity>>[];
      final subscription = h.deckRepository.watchRootDecks().listen(
        emissions.add,
      );
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await h.deckRepository.renameDeck(
        deckId: root.id,
        name: DeckName.parseOrThrow('After'),
      );
      await pumpEventQueue();

      expect(emissions.last.single.name, 'After');
    });

    test('re-emits after a delete', () async {
      final root = await h.deckRepository.createRootDeck(
        name: DeckName.parseOrThrow('Doomed'),
        schedulerType: SchedulerType.eightBox,
      );
      final emissions = <List<DeckEntity>>[];
      final subscription = h.deckRepository.watchRootDecks().listen(
        emissions.add,
      );
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(emissions.last, hasLength(1));

      await h.deckRepository.deleteDeck(root.id);
      await pumpEventQueue();

      expect(emissions.last, isEmpty);
    });

    test('watchCardsByDeck follows card writes', () async {
      final tree = await h.seedTree();
      final emissions = <List<CardEntity>>[];
      final subscription = h.cardRepository
          .watchCardsByDeck(tree.leaf.id)
          .listen(emissions.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(emissions.last, isEmpty);

      final card = await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: 'f',
        back: 'b',
      );
      await pumpEventQueue();
      expect(emissions.last.single.front, 'f');

      await h.cardRepository.deleteCard(card.id);
      await pumpEventQueue();
      expect(emissions.last, isEmpty);
    });

    test('watchDeckTree covers every depth of one root', () async {
      final tree = await h.seedTree();
      final emissions = <List<DeckEntity>>[];
      final subscription = h.deckRepository
          .watchDeckTree(tree.root.id)
          .listen(emissions.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      expect(emissions.last.map((DeckEntity d) => d.id).toSet(), <String>{
        tree.root.id,
        tree.branch.id,
        tree.leaf.id,
      });
    });
  });

  group('failure boundary', () {
    test('no raw Drift/SQLite exception escapes the repository', () async {
      final tree = await h.seedTree();
      await h.db.customStatement(
        'CREATE TRIGGER fail_any_card BEFORE INSERT ON cards '
        "BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );

      Object? caught;
      try {
        await h.cardRepository.createCard(
          deckId: tree.leaf.id,
          front: 'f',
          back: 'b',
        );
      } on Object catch (error) {
        caught = error;
      }

      expect(caught, isNotNull);
      expect(caught, isA<Failure>());
    });

    test('a known constraint conflict surfaces as ConflictFailure', () async {
      // The same client id twice: a real PRIMARY KEY violation.
      final fixedIdRepository = DeckRepositoryImpl(
        DeckDao(h.db),
        idGenerator: () => 'duplicate-id',
        clock: () => h.currentInstant,
      );
      await fixedIdRepository.createRootDeck(
        name: DeckName.parseOrThrow('First'),
        schedulerType: SchedulerType.eightBox,
      );

      await expectLater(
        fixedIdRepository.createRootDeck(
          name: DeckName.parseOrThrow('Second'),
          schedulerType: SchedulerType.eightBox,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('a missing deck surfaces as NotFoundFailure', () async {
      await expectLater(
        h.deckRepository.getDeckById('nope'),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectLater(
        h.cardRepository.deleteCard('nope'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  test('a full repository scenario leaves all 15 invariants clean', () async {
    final treeA = await h.seedTree(prefix: 'A-');
    final grandLeaf = await h.deckRepository.createSubDeck(
      name: DeckName.parseOrThrow('A-GrandLeaf'),
      parentDeckId: treeA.leaf.id,
    );
    await h.cardRepository.createCard(
      deckId: grandLeaf.id,
      front: 'a',
      back: 'a',
    );
    final treeB = await h.seedTree(prefix: 'B-', scheduler: SchedulerType.sm2);
    final cardB = await h.cardRepository.createCard(
      deckId: treeB.leaf.id,
      front: 'b',
      back: 'b',
    );
    await h.cardRepository.updateCard(
      cardId: cardB.id,
      front: 'b2',
      back: 'b2',
    );
    await h.deckRepository.renameDeck(
      deckId: treeA.root.id,
      name: DeckName.parseOrThrow('A-Renamed'),
    );

    // Same-scheduler move plus a delete, then check every invariant.
    final treeC = await h.seedTree(prefix: 'C-');
    await h.deckRepository.moveDeck(
      deckId: treeA.branch.id,
      targetParentDeckId: treeC.leaf.id,
    );
    await h.deckRepository.deleteDeck(treeB.branch.id);

    for (final entry in invariantQueries.entries) {
      expect(
        await violations(h.db, entry.value),
        isEmpty,
        reason: 'invariant ${entry.key} must stay clean',
      );
    }
  });
}
