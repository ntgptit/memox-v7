import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';

import '../../features/study/data/support/study_harness.dart';

/// `HOST-FLOW` for what a session fixes at the moment it opens — the four rules
/// no host test mentioned before this file: BR-23, BR-24, BR-102 and the
/// ordering half of BR-139.
///
/// Scenarios: IT-STUDY-010, IT-STUDY-011, IT-REVIEW-004, IT-LEARN-011,
/// IT-CONT-006, and the host half of IT-CONT-001.
///
/// **All four rules are about a moment, which is why they need a real
/// database.** They say what must be *true of rows already written* when the
/// deck changes underneath — and a change that lands after the queue was built
/// is exactly the thing an in-memory model cannot be wrong about, because it
/// has no second writer. The bug they guard against is a session that quietly
/// re-reads the deck and serves a card the user never opened the session with.
void main() {
  late StudyHarness h;

  setUp(() => h = StudyHarness());
  tearDown(() => h.close());

  Future<int> queued(String sessionId) async {
    final rows = await h.rows(
      "SELECT COUNT(*) AS n FROM study_queue_items WHERE session_id = '$sessionId'",
    );

    return rows.first.read<int>('n');
  }

  Future<List<String>> queuedCards(String sessionId, String mode) async {
    final rows = await h.rows(
      'SELECT card_id FROM study_queue_items '
      "WHERE session_id = '$sessionId' AND mode = '$mode' AND round = 1 "
      'ORDER BY position',
    );

    return rows.map((r) => r.read<String>('card_id')).toList();
  }

  group('BR-24 · the limit is a ceiling per opening, not a daily quota', () {
    test(
      'IT-STUDY-010 · a session takes at most card_limit distinct cards',
      () async {
        // Twenty-one due cards against the default ceiling of twenty.
        final sessionId = await h.openReview(cardCount: 21);

        final cards = await queuedCards(
          sessionId,
          StudyMode.selfAssess.dbValue,
        );
        expect(cards, hasLength(20));
        expect(
          cards.toSet(),
          hasLength(20),
          reason: 'the ceiling counts *distinct* cards, so no id may repeat',
        );
      },
    );

    test('IT-LEARN-011 · opening a second session is allowed, and re-applies '
        'the ceiling rather than a remaining allowance', () async {
      final first = await h.openReview(cardCount: 21);
      expect(await queued(first), 20);

      // BR-24 is explicit that the number of sessions in a day is unbounded.
      // A quota implementation would hand the second session one card.
      final second = await h.repository.openSession(
        deckId: 'd1',
        kind: StudySessionKind.reviewing,
        stageSequence: const <StudyMode>[StudyMode.selfAssess],
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        now: StudyHarness.now,
      );
      expect(
        await queued(second.id),
        20,
        reason: 'a second opening gets a full ceiling, not what the first left',
      );
    });
  });

  test('BR-23 · IT-REVIEW-004 · when the limit bites, it takes the most '
      'overdue cards', () async {
    // **BR-23 governs which cards are taken, not the order they are served
    // in.** The two look like one rule and are not: BR-117 requires every round
    // to carry its own shuffle, so asserting that `position` follows `due_at`
    // would be asserting the opposite of BR-117. What BR-23 is worth is the
    // selection — a limit that took the *least* overdue cards would leave the
    // oldest debt growing forever, and that is a bug no ordering assertion in
    // the queue would ever see.
    final ids = await h.seedDeck(cardCount: 5);
    for (final (index, id) in ids.indexed) {
      await h.makeDue(id, ago: Duration(days: 5 - index));
    }
    final session = await h.repository.openSession(
      deckId: 'd1',
      kind: StudySessionKind.reviewing,
      stageSequence: const <StudyMode>[StudyMode.selfAssess],
      cardLimit: 3,
      newCardOrder: NewCardOrder.created,
      now: StudyHarness.now,
    );

    final taken = await queuedCards(session.id, StudyMode.selfAssess.dbValue);
    expect(
      taken.toSet(),
      <String>{'c0', 'c1', 'c2'},
      reason:
          'c0 is five days overdue and c4 one, so the ceiling of three '
          'takes c0, c1 and c2',
    );
    expect(
      taken,
      hasLength(3),
      reason: 'and the shuffle of BR-117 may reorder them, but not add one',
    );
  });

  group('BR-102 · the queue is frozen once the session is open', () {
    test('IT-CONT-006 · a card added after opening never joins the running '
        'session', () async {
      final sessionId = await h.openReview(cardCount: 3);
      final before = await queuedCards(sessionId, StudyMode.selfAssess.dbValue);

      await h.db.customStatement(
        'INSERT INTO cards (id, deck_id, front, back, front_folded, '
        'back_folded, created_at, updated_at) '
        "VALUES ('late', 'd1', 'late', 'late', 'late', 'late', 99, 99)",
      );
      await h.db.customStatement(
        'INSERT INTO card_study_states (card_id, scheduler_type, '
        'scheduler_version, scheduler_generation, answer_count, lapse_count, '
        'current_box, learned_at, due_at) '
        "VALUES ('late', 'eight_box', 1, 1, 0, 0, 1, 0, 0)",
      );

      expect(
        await queuedCards(sessionId, StudyMode.selfAssess.dbValue),
        before,
        reason: 'the queue is rows, not a query re-run on every read',
      );
    });

    test('IT-CONT-001 · deleting a queued card cannot leave the queue pointing '
        'at nothing', () async {
      // The counterpart, and the reason the queue holds a foreign key with
      // ON DELETE CASCADE rather than a copy of the card: a frozen queue that
      // could outlive its cards would serve a turn with no content.
      final sessionId = await h.openReview(cardCount: 3);
      expect(await queued(sessionId), 3);

      await h.db.customStatement("DELETE FROM cards WHERE id = 'c1'");

      final remaining = await queuedCards(
        sessionId,
        StudyMode.selfAssess.dbValue,
      );
      expect(remaining, isNot(contains('c1')));
      expect(
        remaining,
        hasLength(2),
        reason: 'the row goes with the card; it does not dangle',
      );
    });
  });
}
