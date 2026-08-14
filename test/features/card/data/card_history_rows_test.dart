import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/data/repositories/card_detail_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_history_event_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_answer_kind_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_outcome_reason_model.dart';

import '../../../database/support/test_database.dart';
import '../../deck/data/support/deck_repository_harness.dart';
import 'support/card_history_fixture.dart';
import 'support/card_text_fixture.dart';

/// What a history row says, what a reset leaves behind, and what reading costs
/// (BR-185, BR-186, BR-182, BR-188).
///
/// Split from `card_history_paging_test.dart` at the seam the guard's size
/// ceiling exposed, and it is a real one: that file is about the *shape* of the
/// read — order, boundaries, cursors — while this one is about the *content* of
/// a row and the fact that reading writes nothing.
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

  group('what a row says (BR-185)', () {
    test('kind, mode, action and the marks come from the row, not from the '
        'schedule delta', () async {
      final seed = await seedCard();
      // The case BR-76 exists for: a scheduled review answered `remembered`
      // with the box unchanged. Anything deriving the kind from the delta would
      // call this a turn that moved nothing.
      await fixture.seedAnswer(
        id: 'row-1',
        cardId: seed.card.id,
        sessionId: seed.session,
        answeredAt: testNow,
        mode: 'recall',
        outcomeReason: 'timeout',
        previousBox: 8,
        nextBox: 8,
      );

      final page = await repository().loadCardHistoryPage(seed.card.id);
      final event = page.events.single;

      expect(event.kind, StudyAnswerKind.scheduled);
      expect(event.mode, StudyMode.recall);
      expect(event.action, StudyAction.remembered);
      expect(event.outcomeReason, StudyOutcomeReason.timeout);
      expect(event.previousBox, 8);
      expect(event.nextBox, 8);
      expect(event.hasScheduleChange, isTrue);
    });

    test('an sm2 row carries ease and interval, an eight_box row carries the '
        'box', () async {
      final seed = await seedCard();
      await fixture.seedAnswer(
        id: 'sm2-row',
        cardId: seed.card.id,
        sessionId: seed.session,
        answeredAt: testNow,
        schedulerType: 'sm2',
        action: 'good',
        previousBox: null,
        nextBox: null,
        previousEaseFactor: 2.5,
        nextEaseFactor: 2.6,
        previousIntervalDays: 1,
        nextIntervalDays: 6,
        nextDueAt: testNow.add(const Duration(days: 6)),
      );

      final event = (await repository().loadCardHistoryPage(
        seed.card.id,
      )).events.single;

      expect(event.schedulerType, SchedulerType.sm2);
      expect(event.previousEaseFactor, 2.5);
      expect(event.nextEaseFactor, 2.6);
      expect(event.previousIntervalDays, 1);
      expect(event.nextIntervalDays, 6);
      expect(event.previousBox, isNull);
      expect(event.nextDueAt, isNotNull);
    });

    test('a learning turn records history and moves no schedule '
        '(BR-144)', () async {
      final seed = await seedCard();
      await fixture.seedAnswer(
        id: 'learning-row',
        cardId: seed.card.id,
        sessionId: seed.session,
        answeredAt: testNow,
        kind: 'learning',
        mode: 'fill',
        usedHint: true,
        previousBox: null,
        nextBox: null,
      );

      final event = (await repository().loadCardHistoryPage(
        seed.card.id,
      )).events.single;

      expect(event.kind, StudyAnswerKind.learning);
      expect(event.usedHint, isTrue);
      expect(event.nextDueAt, isNull);
      expect(event.hasScheduleChange, isFalse);
    });

    test('used_hint stays null where it does not apply, rather than becoming '
        'false (BR-136)', () async {
      final seed = await seedCard();
      await fixture.seedAnswer(
        id: 'no-hint',
        cardId: seed.card.id,
        sessionId: seed.session,
        answeredAt: testNow,
      );

      final event = (await repository().loadCardHistoryPage(
        seed.card.id,
      )).events.single;

      expect(event.usedHint, isNull);
    });
  });

  group('generations and reset (BR-186, BR-43)', () {
    test('a reset keeps every row and its generation', () async {
      final seed = await seedCard();
      await fixture.seedRun(
        cardId: seed.card.id,
        sessionId: seed.session,
        count: 3,
      );

      await h.deckRepository.resetLearningProgress(
        rootDeckId: seed.root,
        schedulerType: SchedulerType.sm2,
      );
      final afterReset = await fixture.seedSession(
        deckId: seed.card.deckId,
        rootDeckId: seed.root,
        schedulerGeneration: 2,
      );
      await fixture.seedAnswer(
        id: 'g2-row',
        cardId: seed.card.id,
        sessionId: afterReset,
        answeredAt: testNow.add(const Duration(days: 1)),
        schedulerType: 'sm2',
        schedulerGeneration: 2,
        action: 'good',
        previousBox: null,
        nextBox: null,
        previousIntervalDays: 0,
        nextIntervalDays: 1,
      );

      final page = await repository().loadCardHistoryPage(seed.card.id);

      expect(page.events, hasLength(4));
      expect(page.events.first.schedulerGeneration, 2);
      // The three old rows survived the reset and still say which cycle and
      // which rules they belonged to — a deck knows only its current
      // generation, so this is the only place that fact lives.
      expect(
        page.events.skip(1).map(
          (CardHistoryEventModel event) => event.schedulerGeneration,
        ),
        everyElement(1),
      );
      expect(
        page.events.skip(1).map(
          (CardHistoryEventModel event) => event.schedulerType,
        ),
        everyElement(SchedulerType.eightBox),
      );
    });
  });

  group('read-only, and gone (BR-182, BR-188)', () {
    test('reading the detail and two pages writes nothing', () async {
      final seed = await seedCard();
      await fixture.seedRun(
        cardId: seed.card.id,
        sessionId: seed.session,
        count: 60,
      );
      final before = await h.rawCard(seed.card.id);
      final stateBefore = await h.rawStates(seed.card.id);
      h.clearStatements();

      await repository().watchCardDetail(seed.card.id).first;
      final first = await repository().loadCardHistoryPage(seed.card.id);
      await repository().loadCardHistoryPage(
        seed.card.id,
        after: first.nextCursor,
      );

      expect(h.countStatements('INSERT'), 0);
      expect(h.countStatements('UPDATE'), 0);
      expect(h.countStatements('DELETE'), 0);
      expect((await h.rawCard(seed.card.id))!.data, before!.data);
      expect((await h.rawStates(seed.card.id)).single.data, stateBefore.single.data);
      expect(await h.countAll('study_answers'), 60);
    });

    test('history of a deleted card is empty, and its rows cascaded '
        'away', () async {
      final seed = await seedCard();
      await fixture.seedRun(
        cardId: seed.card.id,
        sessionId: seed.session,
        count: 3,
      );

      await h.cardRepository.deleteCard(seed.card.id);

      expect(await h.countAll('study_answers'), 0);
      final page = await repository().loadCardHistoryPage(seed.card.id);
      expect(page.events, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('a card with no reviews is an empty page, not a failure '
        '(BR-187)', () async {
      final seed = await seedCard();

      final page = await repository().loadCardHistoryPage(seed.card.id);

      expect(page.events, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });
  });
}
