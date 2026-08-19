import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/data/repositories/card_detail_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_history_event_model.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';

import '../../../database/support/test_database.dart';
import '../../deck/data/support/deck_repository_harness.dart';
import 'support/card_history_fixture.dart';
import 'support/card_text_fixture.dart';

/// Ordering and paging (BR-241).
///
/// Real SQLite, because everything under test is a property of the statement:
/// whether the tie-break makes the order total, whether the cursor survives a
/// row arriving between two pages, and whether the read costs one statement or
/// fifty. What a row is allowed to *say* is `card_history_rows_test.dart`.
void main() {
  final h = installDeckRepositoryHarness();
  late CardHistoryFixture fixture;

  setUp(() => fixture = CardHistoryFixture(h));

  CardDetailRepositoryImpl repository() => CardDetailRepositoryImpl(h.db);

  Future<({CardEntity card, String session, String root})> seedCard({
    String front = 'front',
  }) async {
    final tree = await h.seedTree();
    final card = await h.cardRepository.createCard(
      deckId: tree.leaf.id,
      front: cardText(front),
      back: cardText('back', side: CardSide.back),
    );
    final session = await fixture.seedSession(
      deckId: tree.leaf.id,
      rootDeckId: tree.root.id,
    );

    return (card: card, session: session, root: tree.root.id);
  }

  List<String> idsOf(CardHistoryPageModel page) =>
      page.events.map((CardHistoryEventModel event) => event.id).toList();

  group('order (BR-241)', () {
    test('newest first', () async {
      final seed = await seedCard();
      await fixture.seedRun(
        cardId: seed.card.id,
        sessionId: seed.session,
        count: 3,
      );

      final page = await repository().loadCardHistoryPage(seed.card.id);

      // Written oldest-first, one minute apart; read back the other way round.
      expect(idsOf(page), <String>['a-0002', 'a-0001', 'a-0000']);
    });

    test('ties on answered_at break by id descending, so the order is '
        'total', () async {
      final seed = await seedCard();
      // The same instant three times — two turns of one session can share a
      // millisecond, and without the id the order would be whatever SQLite
      // happened to return.
      for (final id in <String>['tie-a', 'tie-c', 'tie-b']) {
        await fixture.seedAnswer(
          id: id,
          cardId: seed.card.id,
          sessionId: seed.session,
          answeredAt: testNow,
        );
      }

      final page = await repository().loadCardHistoryPage(seed.card.id);

      expect(idsOf(page), <String>['tie-c', 'tie-b', 'tie-a']);
    });

    test('another card\'s reviews never appear', () async {
      final seed = await seedCard();
      final other = await h.cardRepository.createCard(
        deckId: seed.card.deckId,
        front: cardText('other'),
        back: cardText('other', side: CardSide.back),
      );
      await fixture.seedRun(
        cardId: seed.card.id,
        sessionId: seed.session,
        count: 2,
      );
      await fixture.seedRun(
        cardId: other.id,
        sessionId: seed.session,
        count: 2,
        prefix: 'other',
      );

      final page = await repository().loadCardHistoryPage(seed.card.id);

      expect(page.events, hasLength(2));
      expect(idsOf(page).every((String id) => id.startsWith('a-')), isTrue);
    });
  });

  group('paging (BR-241)', () {
    test('a page holds fifty and says there is another', () async {
      final seed = await seedCard();
      await fixture.seedRun(
        cardId: seed.card.id,
        sessionId: seed.session,
        count: 51,
      );

      final page = await repository().loadCardHistoryPage(seed.card.id);

      expect(page.events, hasLength(kCardHistoryPageSize));
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, isNotNull);
    });

    test('exactly fifty rows is the end, not a full page with more behind '
        'it', () async {
      final seed = await seedCard();
      await fixture.seedRun(
        cardId: seed.card.id,
        sessionId: seed.session,
        count: kCardHistoryPageSize,
      );

      final page = await repository().loadCardHistoryPage(seed.card.id);

      // The probe row is what makes this answerable at all: a page that comes
      // back exactly full is otherwise indistinguishable from the last one.
      expect(page.events, hasLength(kCardHistoryPageSize));
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('two pages are disjoint and cover everything', () async {
      final seed = await seedCard();
      await fixture.seedRun(
        cardId: seed.card.id,
        sessionId: seed.session,
        count: 60,
      );

      final first = await repository().loadCardHistoryPage(seed.card.id);
      final second = await repository().loadCardHistoryPage(
        seed.card.id,
        after: first.nextCursor,
      );

      final all = <String>[...idsOf(first), ...idsOf(second)];
      expect(all.toSet(), hasLength(60));
      expect(second.hasMore, isFalse);
      // Still one descending run across the boundary — a cursor that included
      // its own row, or skipped one, would show up here and nowhere else.
      final sorted = <String>[...all]
        ..sort((String a, String b) => b.compareTo(a));
      expect(all, sorted);
    });

    test('a review written between two pages neither duplicates nor drops a '
        'row', () async {
      final seed = await seedCard();
      await fixture.seedRun(
        cardId: seed.card.id,
        sessionId: seed.session,
        count: 60,
      );
      final first = await repository().loadCardHistoryPage(seed.card.id);

      // Newest of all, so it lands above the window the reader is holding —
      // exactly where an OFFSET would push one already-shown row down into the
      // next page and show it twice.
      await fixture.seedAnswer(
        id: 'z-newest',
        cardId: seed.card.id,
        sessionId: seed.session,
        answeredAt: testNow.add(const Duration(days: 1)),
      );

      final second = await repository().loadCardHistoryPage(
        seed.card.id,
        after: first.nextCursor,
      );

      final all = <String>[...idsOf(first), ...idsOf(second)];
      expect(all.toSet(), hasLength(all.length), reason: 'no duplicates');
      expect(all, isNot(contains('z-newest')));
      // The ten oldest are still all present: the insert above the window did
      // not push one out of the pair of pages.
      expect(all, hasLength(60));
    });

    test('ties spanning a page boundary are not lost', () async {
      final seed = await seedCard();
      // 60 rows on one instant: the boundary falls inside a group of equal
      // timestamps, which is the case a timestamp-only cursor cannot page
      // through at all.
      for (var index = 0; index < 60; index++) {
        await fixture.seedAnswer(
          id: 'same-${index.toString().padLeft(4, '0')}',
          cardId: seed.card.id,
          sessionId: seed.session,
          answeredAt: testNow,
        );
      }

      final first = await repository().loadCardHistoryPage(seed.card.id);
      final second = await repository().loadCardHistoryPage(
        seed.card.id,
        after: first.nextCursor,
      );

      final all = <String>{...idsOf(first), ...idsOf(second)};
      expect(all, hasLength(60));
    });

    test('a page costs one statement, whatever it holds', () async {
      final seed = await seedCard();
      await fixture.seedRun(
        cardId: seed.card.id,
        sessionId: seed.session,
        count: 51,
      );
      h.clearStatements();

      await repository().loadCardHistoryPage(seed.card.id);

      expect(h.countStatements('FROM study_answers'), 1);
    });

    test(
      'both page statements seek instead of sorting the whole history',
      () async {
        final seed = await seedCard();
        await fixture.seedRun(
          cardId: seed.card.id,
          sessionId: seed.session,
          count: 120,
        );

        // **The statement drift actually ran, not one copied into the test.** A
        // hand-written SQL string here would keep passing after the `.drift`
        // query was changed, which is precisely the regression a plan assertion
        // exists to catch. The interceptor already records every statement, so
        // the plan is taken from the text that reached SQLite.
        h.clearStatements();
        final first = await repository().loadCardHistoryPage(seed.card.id);
        final firstSql = h.statements.firstWhere(
          (String line) => line.contains('FROM study_answers'),
        );

        h.clearStatements();
        await repository().loadCardHistoryPage(
          seed.card.id,
          after: first.nextCursor,
        );
        final afterSql = h.statements.firstWhere(
          (String line) => line.contains('FROM study_answers'),
        );

        for (final sql in <String>[firstSql, afterSql]) {
          final plan = await h.db
              .customSelect('EXPLAIN QUERY PLAN ${_statementOf(sql)}')
              .get();
          final detail = plan
              .map((row) => row.read<String>('detail'))
              .join(' | ');

          // The index supplies `card_id` and the leading sort term. SQLite may
          // still block-sort within each equal-`answered_at` group — that is the
          // "RIGHT PART OF ORDER BY" plan and it keeps the early stop — but a
          // plain "USE TEMP B-TREE FOR ORDER BY" would mean the whole history is
          // sorted before the LIMIT is applied, which is the cost keyset paging
          // exists to avoid. The second statement is checked too: its `OR` chain
          // is the one shape that could quietly lose the index.
          expect(detail, contains('idx_study_answers_card'), reason: sql);
          expect(
            detail,
            isNot(contains('USE TEMP B-TREE FOR ORDER BY')),
            reason: sql,
          );
        }
      },
    );
  });
}

/// The SQL out of one interceptor line, with its bound variables inlined.
///
/// The interceptor prints `<micros>us[ SLOW]  <sql>  (<rows>)`, so the
/// statement is what sits between the duration and the trailing row count.
/// `EXPLAIN QUERY PLAN` will not take `?` placeholders unbound, and the plan
/// does not depend on the values, so they become literals. Reading the log
/// rather than re-typing the statement is what keeps this pointed at the query
/// the repository actually ran.
String _statementOf(String logLine) {
  final start = logLine.indexOf('SELECT');
  final end = logLine.lastIndexOf('  (');
  final sql = logLine.substring(start, end == -1 ? logLine.length : end).trim();
  var index = 0;

  return sql.replaceAllMapped(RegExp(r'\?\d*'), (_) {
    index += 1;

    // A literal that satisfies every parameter these two statements bind: the
    // card id is text and the rest are numeric, and SQLite plans identically
    // either way.
    return index == 1 ? "'x'" : '0';
  });
}
