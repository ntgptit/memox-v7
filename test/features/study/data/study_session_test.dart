import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/domain/failures/study_refusal_failure.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';

import 'support/study_harness.dart';

/// Opening a session, what it counts beforehand, and how it ends.
///
/// The queue engine itself is in `study_queue_test.dart`; these are the two ends
/// of a session's life.
void main() {
  late StudyHarness h;

  setUp(() => h = StudyHarness());
  tearDown(() => h.close());

  group('opening a session', () {
    test('a learning session takes only unlearned cards (BR-142)', () async {
      final ids = await h.seedDeck(cardCount: 3);
      await h.makeDue(ids.first);

      final session = await h.repository.openSession(
        deckId: 'd1',
        kind: StudySessionKind.learning,
        stageSequence: <StudyMode>[StudyMode.browse, StudyMode.match],
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        now: StudyHarness.now,
      );

      final cards = await h.rows(
        "SELECT DISTINCT card_id FROM study_queue_items "
        "WHERE session_id = '${session.id}' ORDER BY card_id",
      );

      expect(cards.map((r) => r.read<String>('card_id')), <String>['c1', 'c2']);
    });

    test('it takes what is there, and does not pad to the limit', () async {
      // The rule this project changed course for: eight due cards make an
      // eight-card session, not a twenty-card one topped up with new material.
      final ids = await h.seedDeck(cardCount: 5);
      for (final id in ids.take(2)) {
        await h.makeDue(id);
      }

      final session = await h.repository.openSession(
        deckId: 'd1',
        kind: StudySessionKind.reviewing,
        stageSequence: <StudyMode>[StudyMode.selfAssess],
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        now: StudyHarness.now,
      );

      final cards = await h.rows(
        "SELECT DISTINCT card_id FROM study_queue_items "
        "WHERE session_id = '${session.id}'",
      );

      expect(cards, hasLength(2));
    });

    test('a review session with nothing due writes no row at all', () async {
      // BR-145 with BR-101: refusing is not the same as opening an empty
      // session and closing it. A row written and abandoned still counts as a
      // session in the history.
      await h.seedDeck(cardCount: 2);

      await expectLater(
        h.repository.openSession(
          deckId: 'd1',
          kind: StudySessionKind.reviewing,
          stageSequence: <StudyMode>[StudyMode.selfAssess],
          cardLimit: 20,
          newCardOrder: NewCardOrder.created,
          now: StudyHarness.now,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.reason,
            'reason',
            StudyRefusalReason.nothingDueToReview,
          ),
        ),
      );

      expect(await h.rows('SELECT id FROM study_sessions'), isEmpty);
    });

    test(
      'each stage gets its own order over the same cards (BR-113)',
      () async {
        await h.seedDeck(cardCount: 8);

        final session = await h.repository.openSession(
          deckId: 'd1',
          kind: StudySessionKind.learning,
          stageSequence: <StudyMode>[StudyMode.match, StudyMode.guess],
          cardLimit: 20,
          newCardOrder: NewCardOrder.created,
          now: StudyHarness.now,
        );

        Future<List<String>> order(String mode) async {
          final result = await h.rows(
            "SELECT card_id FROM study_queue_items WHERE session_id = "
            "'${session.id}' AND mode = '$mode' ORDER BY position",
          );

          return result.map((r) => r.read<String>('card_id')).toList();
        }

        final match = await order('match');
        final guess = await order('guess');

        expect(match.toSet(), guess.toSet());
        expect(match, isNot(guess));
      },
    );
  });

  group('the entry summary', () {
    test('the two counts are disjoint, and fill counts separately', () async {
      // BR-154 in its raw form. The repository reports facts — how many cards
      // `fill` can take is that mode's policy and belongs to its handler
      // (AD-18) — but the fact it reports has to be the one that makes the
      // difference visible: `example` is optional, so most decks have fewer
      // fillable cards than due ones.
      final ids = await h.seedDeck(cardCount: 6);
      for (final id in ids.take(4)) {
        await h.makeDue(id);
      }
      await h.db.customStatement(
        "UPDATE cards SET example = 'e' WHERE id IN ('c0', 'c1')",
      );

      final summary = await h.repository
          .watchStudyEntry('d1', now: StudyHarness.now)
          .first;

      expect(summary.newCount, 2);
      expect(summary.dueCount, 4);
      expect(summary.fillableCount, 2);
      // Four distinct meanings is one short of what a five-option question
      // needs (BR-121) — the number the resolver will read to skip the stage.
      expect(summary.distinctMeanings, 4);
    });

    test('the two sets never overlap', () async {
      // Since v5 they are disjoint by shape rather than by one predicate
      // subtracting the other, which is what BR-150's two-number badge needs to
      // be able to add up.
      final ids = await h.seedDeck(cardCount: 5);
      await h.makeDue(ids.first);

      final summary = await h.repository
          .watchStudyEntry('d1', now: StudyHarness.now)
          .first;

      expect(summary.newCount + summary.dueCount, 5);
      expect(summary.dueCount, 1);
    });
  });

  group('ending a session', () {
    test('an illegal outcome pair is refused (BR-79 … BR-85)', () async {
      final ids = await h.seedDeck(cardCount: 1);
      await h.makeDue(ids.single);
      final session = await h.repository.openSession(
        deckId: 'd1',
        kind: StudySessionKind.reviewing,
        stageSequence: <StudyMode>[StudyMode.selfAssess],
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        now: StudyHarness.now,
      );

      await expectLater(
        h.repository.endSession(
          sessionId: session.id,
          status: StudySessionStatus.completed,
          reason: StudySessionEndReason.userExit,
          endedAt: StudyHarness.now,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('turns already written survive every ending (BR-86)', () async {
      final ids = await h.seedDeck(cardCount: 2);
      for (final id in ids) {
        await h.makeDue(id);
      }
      final session = await h.repository.openSession(
        deckId: 'd1',
        kind: StudySessionKind.reviewing,
        stageSequence: <StudyMode>[StudyMode.selfAssess],
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        now: StudyHarness.now,
      );
      final card = (await h.repository.nextTurn(session.id))!.cardId;
      await h.repository.submitAnswer(
        sessionId: session.id,
        cardId: card,
        mode: StudyMode.selfAssess,
        action: StudyAction.remembered,
        now: StudyHarness.now,
        nextDueAt: StudyHarness.now.add(const Duration(days: 2)),
        nextBox: 2,
      );

      await h.repository.endSession(
        sessionId: session.id,
        status: StudySessionStatus.abandoned,
        reason: StudySessionEndReason.userExit,
        endedAt: StudyHarness.now,
      );

      expect(await h.rows('SELECT id FROM study_answers'), hasLength(1));
    });

    test(
      'a session from an earlier day closes as interrupted (BR-103)',
      () async {
        final ids = await h.seedDeck(cardCount: 1);
        await h.makeDue(ids.single);
        final session = await h.repository.openSession(
          deckId: 'd1',
          kind: StudySessionKind.reviewing,
          stageSequence: <StudyMode>[StudyMode.selfAssess],
          cardLimit: 20,
          newCardOrder: NewCardOrder.created,
          now: StudyHarness.now,
        );

        final closed = await h.repository.abandonStaleSessions(
          dayStart: StudyHarness.now.add(const Duration(days: 1)),
        );

        final row = (await h.rows(
          "SELECT status, end_reason FROM study_sessions WHERE id = "
          "'${session.id}'",
        )).single;

        expect(closed, 1);
        expect(row.read<String>('status'), 'abandoned');
        // Not `user_exit`: the user did not leave, the app did.
        expect(row.read<String>('end_reason'), 'interrupted');
      },
    );
  });

  group('serving order', () {
    test('a completed card is not served again', () async {
      final ids = await h.seedDeck(cardCount: 2);
      for (final id in ids) {
        await h.makeDue(id);
      }
      final session = await h.repository.openSession(
        deckId: 'd1',
        kind: StudySessionKind.reviewing,
        stageSequence: <StudyMode>[StudyMode.selfAssess],
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        now: StudyHarness.now,
      );

      final first = (await h.repository.nextTurn(session.id))!;
      await h.repository.submitAnswer(
        sessionId: session.id,
        cardId: first.cardId,
        mode: StudyMode.selfAssess,
        action: StudyAction.remembered,
        now: StudyHarness.now,
      );

      final second = (await h.repository.nextTurn(session.id))!;
      expect(second.cardId, isNot(first.cardId));
      expect(second.item.status, StudyQueueItemStatus.pending);
    });
  });
}
