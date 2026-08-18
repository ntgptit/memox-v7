import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';

import 'support/trash_harness.dart';

/// **The semantic half of BR-257.** `query_inventory_test.dart` proves every
/// statement *mentions* the exclusion; this drives the production repositories
/// over a database holding tombstones and proves nothing comes back.
///
/// Neither replaces the other: the guard catches a statement nobody considered,
/// this catches one that was considered wrongly.
void main() {
  final h = installTrashHarness();

  test('the deck list counts nothing that is in Trash', () async {
    final tree = await h.seedTree(cardCount: 3);

    var snapshot = await h.deckRepository
        .watchDeckList(parentDeckId: null, now: h.now, utcOffset: Duration.zero)
        .first;
    expect(snapshot.decks.single.totalCardCount, 3);

    await h.cardRepository.deleteCard(tree.cardIds.first);

    snapshot = await h.deckRepository
        .watchDeckList(parentDeckId: null, now: h.now, utcOffset: Duration.zero)
        .first;
    expect(snapshot.decks.single.totalCardCount, 2);
    expect(snapshot.decks.single.newCardCount, 2);
  });

  test(
    'a level inside a deck drops a deleted sub-deck and its cards',
    () async {
      final tree = await h.seedTree(cardCount: 2);

      await h.deckRepository.deleteDeck(tree.leaf.id);

      final snapshot = await h.deckRepository
          .watchDeckList(
            parentDeckId: tree.branch.id,
            now: h.now,
            utcOffset: Duration.zero,
          )
          .first;

      expect(snapshot.decks, isEmpty);
    },
  );

  test('the card list and its counts drop a deleted card', () async {
    final tree = await h.seedTree(cardCount: 2);

    await h.cardRepository.deleteCard(tree.cardIds.first);

    final items = await h.cardRepository
        .watchCardListItems(tree.leaf.id, limit: 50)
        .first;
    final count = await h.cardRepository
        .watchFilteredCardCount(tree.leaf.id)
        .first;
    final distribution = await h.cardRepository
        .watchCardStateDistribution(tree.leaf.id)
        .first;

    expect(items.map((item) => item.card.id), <String>[tree.cardIds.last]);
    expect(count, 1);
    expect(distribution.total, 1);
  });

  test('search does not find a deleted card', () async {
    final tree = await h.seedTree(cardCount: 2);
    await h.cardRepository.deleteCard(tree.cardIds.first);

    final matches = await h.cardRepository
        .watchCardListItems(tree.leaf.id, limit: 50, searchTerm: 'front')
        .first;

    expect(matches, hasLength(1));

    // "Select all" reads the same predicate, so it must select the same set —
    // this is the read a bulk delete acts on.
    final ids = await h.cardRepository.readCardIdsMatching(tree.leaf.id);
    expect(ids, <String>[tree.cardIds.last]);
  });

  test('a move picker does not offer a deleted deck', () async {
    final tree = await h.seedTree();
    final sibling = await h.deckRepository.createSubDeck(
      name: DeckName.parse('Sibling').name!,
      parentDeckId: tree.branch.id,
    );

    await h.deckRepository.deleteDeck(sibling.id);

    final targets = await h.cardRepository.watchMoveTargets(tree.leaf.id).first;

    expect(targets.map((target) => target.deckId), isNot(contains(sibling.id)));
  });

  test('study counts and the queue ignore a deleted card', () async {
    final tree = await h.seedTree(cardCount: 2);
    final study = StudyRepositoryImpl(StudyDao(h.db));

    var entry = await study.watchStudyEntry(tree.root.id, now: h.now).first;
    expect(entry.newCount, 2);

    await h.cardRepository.deleteCard(tree.cardIds.first);

    entry = await study.watchStudyEntry(tree.root.id, now: h.now).first;
    expect(entry.newCount, 1);
  });

  test('the deletion impact counts only what is still there', () async {
    final tree = await h.seedTree(cardCount: 3);
    await h.cardRepository.deleteCard(tree.cardIds.first);

    final impact = await h.deckRepository.getDeletionImpact(tree.branch.id);

    // Two cards and one sub-deck — the tombstone is not something the dialog
    // may promise to take, because it is not going anywhere (BR-258).
    expect(impact.cardCount, 2);
    expect(impact.descendantDeckCount, 1);
  });

  test('a deck in Trash reads as gone to every write path', () async {
    final tree = await h.seedTree();
    await h.deckRepository.deleteDeck(tree.leaf.id);

    // `deckById` is filtered, so every repository that reads through it turns a
    // tombstone into `NotFoundFailure` — which is what BR-257 means by "hidden"
    // on the write side.
    await expectLater(
      h.deckRepository.renameDeck(
        deckId: tree.leaf.id,
        name: DeckName.parse('New name').name!,
      ),
      throwsA(isA<Object>()),
    );
  });
}
