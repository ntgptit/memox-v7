import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/datasources/card_dao.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';

import '../../../database/support/test_database.dart';

/// Tags, the flag and the state counters, on a real SQLite database.
///
/// The value-object tests prove `TagName` folds; these prove the *database*
/// agrees — a fold that Dart performs and SQLite does not enforce is a rule with
/// no teeth, and that is the exact failure `COLLATE NOCASE` would have shipped.
void main() {
  Future<AppDatabase> seeded() async {
    final db = openTestDatabase();
    addTearDown(db.close);

    await insertRootDeck(db, id: 'root');
    await insertSubDeck(
      db,
      id: 'leaf',
      parentId: 'root',
      rootDeckId: 'root',
      contentType: 'card',
    );

    return db;
  }

  /// A study state with the columns this file needs to control directly. The
  /// shared helper does not expose box or interval, and inventing values for
  /// them is the whole point here.
  Future<void> stateFor(
    AppDatabase db, {
    required String cardId,
    required String schedulerType,
    required int answerCount,
    int? currentBox,
    int? intervalDays,
  }) => db.customInsert(
    'INSERT INTO card_study_states (card_id, scheduler_type, '
    'scheduler_version, scheduler_generation, answer_count, lapse_count, '
    'current_box, interval_days) VALUES (?, ?, 1, 1, ?, 0, ?, ?)',
    variables: <Variable<Object>>[
      Variable<String>(cardId),
      Variable<String>(schedulerType),
      Variable<int>(answerCount),
      if (currentBox == null)
        const Variable<int>(null)
      else
        Variable<int>(currentBox),
      if (intervalDays == null)
        const Variable<int>(null)
      else
        Variable<int>(intervalDays),
    ],
  );

  Future<void> insertTagRow(
    AppDatabase db,
    CardDao dao, {
    required String id,
    required String name,
  }) async {
    final parsed = TagName.parse(name).name!;
    await dao.insertTag(
      TagsCompanion.insert(
        id: id,
        name: parsed.value,
        nameFolded: parsed.folded,
        createdAt: testNow,
      ),
    );
  }

  group('the unique index enforces BR-93, not just the value object', () {
    test('two spellings of one name collide at the database', () async {
      final db = await seeded();
      final dao = CardDao(db);

      await insertTagRow(db, dao, id: 't1', name: 'Động từ');

      // The case `COLLATE NOCASE` gets wrong: SQLite folds ASCII only, so under
      // NOCASE these two are different strings and both would be inserted.
      await expectLater(
        insertTagRow(db, dao, id: 't2', name: 'động từ'),
        throwsA(anything),
      );
    });

    test('ASCII case collides too', () async {
      final db = await seeded();
      final dao = CardDao(db);

      await insertTagRow(db, dao, id: 't1', name: 'Noun');

      await expectLater(
        insertTagRow(db, dao, id: 't2', name: 'noun'),
        throwsA(anything),
      );
    });

    test('a genuinely different name is allowed', () async {
      final db = await seeded();
      final dao = CardDao(db);

      await insertTagRow(db, dao, id: 't1', name: 'noun');
      await insertTagRow(db, dao, id: 't2', name: 'nouns');

      expect(await dao.watchAllTags().first, hasLength(2));
    });

    test('lookup finds the row through the fold, not the spelling', () async {
      final db = await seeded();
      final dao = CardDao(db);
      await insertTagRow(db, dao, id: 't1', name: 'TOPIK II');

      final found = await dao.tagByFoldedName(
        TagName.parse('topik ii').name!.folded,
      );

      expect(found?.id, 't1');
      expect(found?.name, 'TOPIK II', reason: 'the spelling is what is stored');
    });
  });

  group('links', () {
    test('one statement returns the tags for a whole window', () async {
      // The N+1 this query exists to avoid: a list of 50 cards asking per row
      // is 50 round trips on every rebuild.
      final db = await seeded();
      final dao = CardDao(db);

      await insertCard(db, id: 'c1', deckId: 'leaf');
      await insertCard(db, id: 'c2', deckId: 'leaf');
      await insertTagRow(db, dao, id: 't1', name: 'noun');
      await insertTagRow(db, dao, id: 't2', name: 'people');
      await dao.linkTag('c1', 't1');
      await dao.linkTag('c1', 't2');
      await dao.linkTag('c2', 't1');

      final rows = await dao.watchTagsForCards(<String>['c1', 'c2']).first;

      expect(rows, hasLength(3));
      expect(
        rows.where((row) => row.cardId == 'c1').map((row) => row.name),
        <String>['noun', 'people'],
      );
    });

    test('unlinking removes the link and leaves the tag', () async {
      final db = await seeded();
      final dao = CardDao(db);

      await insertCard(db, id: 'c1', deckId: 'leaf');
      await insertTagRow(db, dao, id: 't1', name: 'noun');
      await dao.linkTag('c1', 't1');

      expect(await dao.unlinkTag('c1', 't1'), 1);
      expect(await dao.watchTagsForCard('c1').first, isEmpty);
      expect(
        await dao.watchAllTags().first,
        hasLength(1),
        reason: 'a tag is not owned by the card that dropped it',
      );
    });

    test('the count is what BR-94 is checked against', () async {
      final db = await seeded();
      final dao = CardDao(db);

      await insertCard(db, id: 'c1', deckId: 'leaf');
      for (var i = 0; i < 3; i++) {
        await insertTagRow(db, dao, id: 't$i', name: 'tag$i');
        await dao.linkTag('c1', 't$i');
      }

      expect(await dao.tagCountForCard('c1'), 3);
    });
  });

  group('the flag', () {
    test('the filtered window holds only flagged cards', () async {
      final db = await seeded();
      final dao = CardDao(db);

      await insertCard(db, id: 'c1', deckId: 'leaf');
      await insertCard(db, id: 'c2', deckId: 'leaf');
      // The count joins the study state, which BR-09 says is born with the
      // card — the fixture has to honour that invariant to be read at all.
      await insertReviewState(db, cardId: 'c1');
      await insertReviewState(db, cardId: 'c2');
      await dao.setCardFlag('c2', isFlagged: true);

      final flagged = await dao
          .watchFlaggedCardsByDeck('leaf', limit: 50)
          .first;

      expect(flagged.map((card) => card.id), <String>['c2']);
      expect(
        await dao
            .watchCardCount(deckId: 'leaf', filter: CardListFilter.flagged)
            .first,
        1,
      );
    });

    test('setting the flag touches nothing else on the row', () async {
      // BR-92: the flag is the user's mark on content, not an edit of it. A
      // companion covering the whole row would let a flag toggle rewrite `front`.
      final db = await seeded();
      final dao = CardDao(db);
      await insertCard(db, id: 'c1', deckId: 'leaf');

      final before = await dao.cardById('c1');
      await dao.setCardFlag('c1', isFlagged: true);
      final after = await dao.cardById('c1');

      expect(after!.isFlagged, 1);
      expect(after.front, before!.front);
      expect(after.back, before.back);
      expect(after.updatedAt, before.updatedAt);
    });

    test('unflagging is the same write in reverse', () async {
      final db = await seeded();
      final dao = CardDao(db);
      await insertCard(db, id: 'c1', deckId: 'leaf');

      await insertReviewState(db, cardId: 'c1');
      await dao.setCardFlag('c1', isFlagged: true);
      await dao.setCardFlag('c1', isFlagged: false);

      expect((await dao.cardById('c1'))!.isFlagged, 0);
      expect(
        await dao
            .watchCardCount(deckId: 'leaf', filter: CardListFilter.flagged)
            .first,
        0,
      );
    });
  });

  group('state counts', () {
    Future<CardStateCountsByDeckResult> countsOf(AppDatabase db) => CardDao(db)
        .watchCardStateCounts(
          'leaf',
          reviewingBox: 4,
          masteredBox: kMasteredBox,
          reviewingDays: kReviewingIntervalDays,
          masteredDays: kMasteredIntervalDays,
        )
        .first;

    test('the four buckets partition the deck, on eight_box', () async {
      final db = await seeded();

      await insertCard(db, id: 'n', deckId: 'leaf');
      await stateFor(
        db,
        cardId: 'n',
        schedulerType: 'eight_box',
        answerCount: 0,
        currentBox: 1,
      );
      for (final entry in <String, int>{'b': 3, 'r': 4, 'm': 8}.entries) {
        await insertCard(db, id: entry.key, deckId: 'leaf');
        await stateFor(
          db,
          cardId: entry.key,
          schedulerType: 'eight_box',
          answerCount: 1,
          currentBox: entry.value,
        );
      }

      final counts = await countsOf(db);

      expect(counts.total, 4);
      expect(counts.newCount, 1);
      expect(counts.beginningCount, 1);
      expect(counts.reviewingCount, 1);
      expect(counts.masteredCount, 1);
    });

    test('and on sm2, at the same distances in time', () async {
      final db = await seeded();

      await insertCard(db, id: 'n', deckId: 'leaf');
      await stateFor(
        db,
        cardId: 'n',
        schedulerType: 'sm2',
        answerCount: 0,
        intervalDays: 0,
      );
      for (final entry in <String, int>{'b': 7, 'r': 8, 'm': 128}.entries) {
        await insertCard(db, id: entry.key, deckId: 'leaf');
        await stateFor(
          db,
          cardId: entry.key,
          schedulerType: 'sm2',
          answerCount: 1,
          intervalDays: entry.value,
        );
      }

      final counts = await countsOf(db);

      expect(counts.newCount, 1);
      expect(counts.beginningCount, 1);
      expect(counts.reviewingCount, 1);
      expect(counts.masteredCount, 1);
    });

    test('a card never reviewed is new even at box 1', () async {
      // The same ordering `cardStateOf` applies: `eight_box` seeds box 1 at
      // creation (BR-09), so testing the box before the review count would
      // count every untouched card as beginning.
      final db = await seeded();

      await insertCard(db, id: 'c1', deckId: 'leaf');
      await stateFor(
        db,
        cardId: 'c1',
        schedulerType: 'eight_box',
        answerCount: 0,
        currentBox: 1,
      );

      final counts = await countsOf(db);

      expect(counts.newCount, 1);
      expect(counts.beginningCount, 0);
    });

    test('SQL and Dart put the same card in the same bucket', () async {
      // Two implementations of BR-89…BR-91 — one in `card.drift`, one in
      // `card_state_model.dart` — because a count over the deck cannot be done
      // in Dart without reading every row. This is what keeps them one rule.
      final db = await seeded();

      const boxes = <int>[1, 3, 4, 7, 8];
      for (final box in boxes) {
        await insertCard(db, id: 'b$box', deckId: 'leaf');
        await stateFor(
          db,
          cardId: 'b$box',
          schedulerType: 'eight_box',
          answerCount: 1,
          currentBox: box,
        );
      }

      final counts = await countsOf(db);
      final dart = <CardState, int>{};
      for (final box in boxes) {
        final state = _stateForBox(box);
        dart[state] = (dart[state] ?? 0) + 1;
      }

      expect(counts.beginningCount, dart[CardState.beginning] ?? 0);
      expect(counts.reviewingCount, dart[CardState.reviewing] ?? 0);
      expect(counts.masteredCount, dart[CardState.mastered] ?? 0);
    });
  });
}

/// The Dart projection for an eight-box card that has been reviewed once.
CardState _stateForBox(int box) {
  if (box >= kMasteredBox) return CardState.mastered;
  if (box >= 4) return CardState.reviewing;

  return CardState.beginning;
}
