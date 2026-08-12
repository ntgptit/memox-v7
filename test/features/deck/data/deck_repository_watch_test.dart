import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/deck/data/datasources/deck_dao.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../../card/data/support/card_text_fixture.dart';
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
        name: DeckName.parse('Existing').name!,
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
        name: DeckName.parse('Fresh').name!,
        schedulerType: SchedulerType.sm2,
      );
      await pumpEventQueue();

      expect(emissions.last.map((DeckEntity d) => d.name), <String>['Fresh']);
    });

    test('re-emits after an update', () async {
      final root = await h.deckRepository.createRootDeck(
        name: DeckName.parse('Before').name!,
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
        name: DeckName.parse('After').name!,
      );
      await pumpEventQueue();

      expect(emissions.last.single.name, 'After');
    });

    test('re-emits after a delete', () async {
      final root = await h.deckRepository.createRootDeck(
        name: DeckName.parse('Doomed').name!,
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
          .watchCardsByDeck(tree.leaf.id, limit: 50)
          .listen(emissions.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(emissions.last, isEmpty);

      final card = await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('f'),
        back: cardText('b', side: CardSide.back),
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
          front: cardText('f'),
          back: cardText('b', side: CardSide.back),
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
        study: StudyRepositoryImpl(StudyDao(h.db)),
        idGenerator: () => 'duplicate-id',
        clock: () => h.currentInstant,
      );
      await fixedIdRepository.createRootDeck(
        name: DeckName.parse('First').name!,
        schedulerType: SchedulerType.eightBox,
      );

      await expectLater(
        fixedIdRepository.createRootDeck(
          name: DeckName.parse('Second').name!,
          schedulerType: SchedulerType.eightBox,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('a missing deck surfaces as NotFoundFailure', () async {
      await expectLater(
        h.deckRepository
            .watchDeckList(
              parentDeckId: 'nope',
              now: testNow,
              utcOffset: Duration.zero,
            )
            .first,
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
      name: DeckName.parse('A-GrandLeaf').name!,
      parentDeckId: treeA.leaf.id,
    );
    await h.cardRepository.createCard(
      deckId: grandLeaf.id,
      front: cardText('a'),
      back: cardText('a', side: CardSide.back),
    );
    final treeB = await h.seedTree(prefix: 'B-', scheduler: SchedulerType.sm2);
    final cardB = await h.cardRepository.createCard(
      deckId: treeB.leaf.id,
      front: cardText('b'),
      back: cardText('b', side: CardSide.back),
    );
    await h.cardRepository.updateCard(
      cardId: cardB.id,
      front: cardText('b2'),
      back: cardText('b2', side: CardSide.back),
    );
    await h.deckRepository.renameDeck(
      deckId: treeA.root.id,
      name: DeckName.parse('A-Renamed').name!,
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
