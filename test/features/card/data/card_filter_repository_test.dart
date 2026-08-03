import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';

import 'support/card_text_fixture.dart';
import '../../../database/support/test_database.dart';
import '../../deck/data/support/deck_repository_harness.dart';

/// The list filters on a real SQLite database (D3): each narrows the read and
/// its count to the cards its predicate matches, and nothing else.
void main() {
  final h = installDeckRepositoryHarness();
  final now = testNow;

  Future<String> seedCardIn(String deckId, String front) async {
    final card = await h.cardRepository.createCard(
      deckId: deckId,
      front: cardText(front),
      back: cardText('back', side: CardSide.back),
    );

    return card.id;
  }

  test('the flagged filter shows only flagged cards (BR-92)', () async {
    final tree = await h.seedTree();
    final flagged = await seedCardIn(tree.leaf.id, 'marked');
    await seedCardIn(tree.leaf.id, 'plain');
    await h.cardRepository.setCardFlag(cardId: flagged, isFlagged: true);

    final items = await h.cardRepository
        .watchCardListItems(
          tree.leaf.id,
          limit: 50,
          filter: CardListFilter.flagged,
        )
        .first;

    expect(items.map((i) => i.card.id), <String>[flagged]);
    expect(
      await h.cardRepository
          .watchFilteredCardCount(tree.leaf.id, filter: CardListFilter.flagged)
          .first,
      1,
    );
  });

  test('the new filter shows only never-reviewed cards (BR-90)', () async {
    final tree = await h.seedTree();
    final fresh = await seedCardIn(tree.leaf.id, 'fresh');
    final reviewed = await seedCardIn(tree.leaf.id, 'seen');
    // Advance one card past new.
    await h.db.customStatement(
      'UPDATE card_review_states SET review_count = 3, current_box = 2 '
      'WHERE card_id = ?',
      <Object?>[reviewed],
    );

    final items = await h.cardRepository
        .watchCardListItems(
          tree.leaf.id,
          limit: 50,
          filter: CardListFilter.isNew,
        )
        .first;

    expect(items.map((i) => i.card.id), <String>[fresh]);
  });

  test('the due-now filter shows cards due now, by BR-22', () async {
    final tree = await h.seedTree();
    final dueNull = await seedCardIn(tree.leaf.id, 'due null');
    final future = await seedCardIn(tree.leaf.id, 'later');
    // A future due date drops out of the due set; NULL stays (a new card).
    await h.db.customStatement(
      'UPDATE card_review_states SET due_at = ? WHERE card_id = ?',
      <Object?>[now.add(const Duration(days: 5)).toIso8601String(), future],
    );

    final items = await h.cardRepository
        .watchCardListItems(
          tree.leaf.id,
          limit: 50,
          filter: CardListFilter.dueNow,
          now: now,
        )
        .first;

    expect(items.map((i) => i.card.id), <String>[dueNull]);
    expect(
      await h.cardRepository
          .watchFilteredCardCount(
            tree.leaf.id,
            filter: CardListFilter.dueNow,
            now: now,
          )
          .first,
      1,
    );
  });

  test('due-now insists on a clock', () async {
    final tree = await h.seedTree();

    expect(
      () => h.cardRepository.watchCardListItems(
        tree.leaf.id,
        limit: 50,
        filter: CardListFilter.dueNow,
      ),
      throwsArgumentError,
    );
  });

  test('the state distribution counts every card by band (D5)', () async {
    final tree = await h.seedTree();
    await seedCardIn(tree.leaf.id, 'fresh'); // new (review_count 0)
    final mastered = await seedCardIn(tree.leaf.id, 'known');
    await h.db.customStatement(
      'UPDATE card_review_states SET review_count = 20, current_box = 8 '
      'WHERE card_id = ?',
      <Object?>[mastered],
    );

    final dist = await h.cardRepository
        .watchCardStateDistribution(tree.leaf.id)
        .first;

    expect(dist.total, 2);
    expect(dist.isNew, 1);
    expect(dist.mastered, 1);
    expect(dist.masteredFraction, 0.5);
  });
}
