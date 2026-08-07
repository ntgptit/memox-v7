import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_list_sort_model.dart';

import 'support/card_text_fixture.dart';
import '../../../database/support/test_database.dart';
import '../../deck/data/support/deck_repository_harness.dart';

/// Drift stores DateTime as unix **seconds**, not ISO text
/// (`store_date_time_values_as_text: false`), so a raw UPDATE has to write the
/// same shape the mapper reads back. The due-filter tests above got away with an
/// ISO string only because the row they wrote it to was the one the filter
/// excluded — a sort returns every row, so it has to be right.
int _epoch(DateTime at) => at.millisecondsSinceEpoch ~/ 1000;

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
      'UPDATE card_study_states SET learned_at = 1, answer_count = 3, '
      'current_box = 2 '
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

  test('the due filter shows cards that have come back around, not new ones', () async {
    final tree = await h.seedTree();
    // Never opened: `learned_at IS NULL`, so it is New (BR-90) and the Due pill
    // must not claim it as well. Since v5 the two are disjoint by shape,
    // not only by the predicate being written as a subtraction.
    await seedCardIn(tree.leaf.id, 'due null');
    final returning = await seedCardIn(tree.leaf.id, 'seen and ripe');
    final future = await seedCardIn(tree.leaf.id, 'later');
    await h.db.customStatement(
      'UPDATE card_study_states SET learned_at = 1, answer_count = 4, due_at = ? '
      'WHERE card_id = ?',
      <Object?>[_epoch(now.subtract(const Duration(days: 1))), returning],
    );
    // Reviewed, but not ripe yet — the third state the table names, and the one
    // neither pill may claim.
    await h.db.customStatement(
      'UPDATE card_study_states SET learned_at = 1, answer_count = 4, due_at = ? '
      'WHERE card_id = ?',
      <Object?>[_epoch(now.add(const Duration(days: 5))), future],
    );

    final items = await h.cardRepository
        .watchCardListItems(
          tree.leaf.id,
          limit: 50,
          filter: CardListFilter.due,
          now: now,
        )
        .first;

    expect(items.map((i) => i.card.id), <String>[returning]);
    expect(
      await h.cardRepository
          .watchFilteredCardCount(
            tree.leaf.id,
            filter: CardListFilter.due,
            now: now,
          )
          .first,
      1,
    );
  });

  test('due and new partition the session queue', () async {
    final tree = await h.seedTree();
    await seedCardIn(tree.leaf.id, 'untouched');
    final returning = await seedCardIn(tree.leaf.id, 'seen and ripe');
    final future = await seedCardIn(tree.leaf.id, 'later');
    await h.db.customStatement(
      'UPDATE card_study_states SET learned_at = 1, answer_count = 4, due_at = ? '
      'WHERE card_id = ?',
      <Object?>[_epoch(now.subtract(const Duration(days: 1))), returning],
    );
    await h.db.customStatement(
      'UPDATE card_study_states SET learned_at = 1, answer_count = 4, due_at = ? '
      'WHERE card_id = ?',
      <Object?>[_epoch(now.add(const Duration(days: 5))), future],
    );

    Future<int> countOf(CardListFilter filter) => h.cardRepository
        .watchFilteredCardCount(tree.leaf.id, filter: filter, now: now)
        .first;

    final due = await countOf(CardListFilter.due);
    final fresh = await countOf(CardListFilter.isNew);

    // Neither pill claims the same card, and together they are exactly what
    // BR-22 would hand a session: the untouched one and the returning one. That
    // sum is what the progress panel's Start-study button prints, so if this
    // ever stops holding the button starts lying about the session size.
    expect(due, 1);
    expect(fresh, 1);
    expect(due + fresh, 2);
    expect(await countOf(CardListFilter.all), 3);
  });

  test('the due filter insists on a clock', () async {
    final tree = await h.seedTree();

    expect(
      () => h.cardRepository.watchCardListItems(
        tree.leaf.id,
        limit: 50,
        filter: CardListFilter.due,
      ),
      throwsArgumentError,
    );
  });

  test('the state distribution counts every card by band (D5)', () async {
    final tree = await h.seedTree();
    await seedCardIn(tree.leaf.id, 'fresh'); // new (learned_at IS NULL)
    final mastered = await seedCardIn(tree.leaf.id, 'known');
    await h.db.customStatement(
      'UPDATE card_study_states SET learned_at = 1, answer_count = 20, '
      'current_box = 8 '
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

  test('due-first orders by due_at, NULL (a new card) at the front', () async {
    final tree = await h.seedTree();
    final later = await seedCardIn(tree.leaf.id, 'later');
    final sooner = await seedCardIn(tree.leaf.id, 'sooner');
    final untouched = await seedCardIn(tree.leaf.id, 'never reviewed');
    await h.db.customStatement(
      'UPDATE card_study_states SET learned_at = 1, due_at = ? WHERE card_id = ?',
      <Object?>[_epoch(now.add(const Duration(days: 9))), later],
    );
    await h.db.customStatement(
      'UPDATE card_study_states SET learned_at = 1, due_at = ? WHERE card_id = ?',
      <Object?>[_epoch(now.add(const Duration(days: 2))), sooner],
    );

    final items = await h.cardRepository
        .watchCardListItems(
          tree.leaf.id,
          limit: 50,
          sort: CardListSort.dueFirst,
        )
        .first;

    // NULL first (due now), then soonest, then furthest out.
    expect(items.map((i) => i.card.id), <String>[untouched, sooner, later]);
  });

  test('the default sort is still newest-first (UC-04 A4)', () async {
    final tree = await h.seedTree();
    final first = await seedCardIn(tree.leaf.id, 'older');
    final second = await seedCardIn(tree.leaf.id, 'newer');

    final items = await h.cardRepository
        .watchCardListItems(tree.leaf.id, limit: 50)
        .first;

    expect(items.map((i) => i.card.id), <String>[second, first]);
  });

  test(
    'a sort applies under a filter too (D3 — the two are orthogonal)',
    () async {
      final tree = await h.seedTree();
      final a = await seedCardIn(tree.leaf.id, 'flag a');
      final b = await seedCardIn(tree.leaf.id, 'flag b');
      await h.cardRepository.setCardFlag(cardId: a, isFlagged: true);
      await h.cardRepository.setCardFlag(cardId: b, isFlagged: true);
      await h.db.customStatement(
        'UPDATE card_study_states SET learned_at = 1, due_at = ? WHERE card_id = ?',
        <Object?>[_epoch(now.add(const Duration(days: 5))), b],
      );

      final items = await h.cardRepository
          .watchCardListItems(
            tree.leaf.id,
            limit: 50,
            filter: CardListFilter.flagged,
            sort: CardListSort.dueFirst,
          )
          .first;

      // Both flagged; `a` still has a NULL due date so it leads.
      expect(items.map((i) => i.card.id), <String>[a, b]);
    },
  );

  test(
    'search matches front or back, and narrows the count with it (S1)',
    () async {
      final tree = await h.seedTree();
      final hit = await seedCardIn(tree.leaf.id, 'ephemeral');
      await seedCardIn(tree.leaf.id, 'unrelated');

      final items = await h.cardRepository
          .watchCardListItems(tree.leaf.id, limit: 50, searchTerm: 'phemer')
          .first;

      expect(items.map((i) => i.card.id), <String>[hit]);
      // The count runs the same predicate, so the pill and the list agree.
      expect(
        await h.cardRepository
            .watchFilteredCardCount(tree.leaf.id, searchTerm: 'phemer')
            .first,
        1,
      );
    },
  );

  test('a search term composes with a filter (S1 x D3)', () async {
    final tree = await h.seedTree();
    final both = await seedCardIn(tree.leaf.id, 'flagged match');
    await seedCardIn(tree.leaf.id, 'unflagged match');
    await h.cardRepository.setCardFlag(cardId: both, isFlagged: true);

    final items = await h.cardRepository
        .watchCardListItems(
          tree.leaf.id,
          limit: 50,
          filter: CardListFilter.flagged,
          searchTerm: 'match',
        )
        .first;

    expect(items.map((i) => i.card.id), <String>[both]);
  });

  test(
    'a % the user types is matched literally, not as a wildcard (S1)',
    () async {
      final tree = await h.seedTree();
      final literal = await seedCardIn(tree.leaf.id, '100% sure');
      await seedCardIn(tree.leaf.id, '100 metres');

      final items = await h.cardRepository
          .watchCardListItems(tree.leaf.id, limit: 50, searchTerm: '100%')
          .first;

      // Under LIKE this also returned '100 metres', because `%` widened the match.
      expect(items.map((i) => i.card.id), <String>[literal]);
    },
  );

  test('a lone % finds only cards that contain one (S1)', () async {
    final tree = await h.seedTree();
    final hasPercent = await seedCardIn(tree.leaf.id, '50% off');
    await seedCardIn(tree.leaf.id, 'no symbol here');

    final items = await h.cardRepository
        .watchCardListItems(tree.leaf.id, limit: 50, searchTerm: '%')
        .first;

    // Under LIKE a bare wildcard returned the whole deck.
    expect(items.map((i) => i.card.id), <String>[hasPercent]);
  });

  test('search stays case-insensitive (S1)', () async {
    final tree = await h.seedTree();
    final hit = await seedCardIn(tree.leaf.id, 'Ephemeral');

    final items = await h.cardRepository
        .watchCardListItems(tree.leaf.id, limit: 50, searchTerm: 'EPHEM')
        .first;

    expect(items.map((i) => i.card.id), <String>[hit]);
  });

  // The case that was broken until the folded columns landed. It is the
  // *stored* text being uppercase that breaks it, not the term: SQLite's
  // `lower()` left `Ô` alone while Dart's `toLowerCase()` folded it, so the two
  // sides of the comparison disagreed. Lowercase content passed, which is why
  // this survived casual testing in an app whose content is Vietnamese and
  // Korean.
  test(
    'an uppercase non-ASCII card is found by its lowercase form (S1)',
    () async {
      final tree = await h.seedTree();
      final hit = await seedCardIn(tree.leaf.id, 'CÔNG NGHỆ');
      await seedCardIn(tree.leaf.id, 'unrelated');

      final items = await h.cardRepository
          .watchCardListItems(tree.leaf.id, limit: 50, searchTerm: 'công nghệ')
          .first;

      expect(items.map((i) => i.card.id), <String>[hit]);
    },
  );

  test('and the reverse: lowercase content, uppercase term (S1)', () async {
    final tree = await h.seedTree();
    final hit = await seedCardIn(tree.leaf.id, 'động từ');

    final items = await h.cardRepository
        .watchCardListItems(tree.leaf.id, limit: 50, searchTerm: 'ĐỘNG')
        .first;

    expect(items.map((i) => i.card.id), <String>[hit]);
  });

  // Case folding only — the same line `TagName` draws (BR-93). Making this
  // match is a product decision about diacritic-insensitive search (S1), not
  // something a folding fix should smuggle in.
  test('folding is case only, not diacritics (S1)', () async {
    final tree = await h.seedTree();
    await seedCardIn(tree.leaf.id, 'công nghệ');

    final items = await h.cardRepository
        .watchCardListItems(tree.leaf.id, limit: 50, searchTerm: 'cong nghe')
        .first;

    expect(items, isEmpty);
  });

  test('the count agrees with the list on a folded match (S1)', () async {
    final tree = await h.seedTree();
    await seedCardIn(tree.leaf.id, 'CÔNG NGHỆ');

    final count = await h.cardRepository
        .watchFilteredCardCount(tree.leaf.id, searchTerm: 'công')
        .first;

    expect(count, 1);
  });
}
