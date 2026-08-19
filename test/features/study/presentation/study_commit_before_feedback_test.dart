import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/guess_mode.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/recall_mode.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/widgets/sections/fill_answer_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/guess_question_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/recall_timer_section_widget.dart';

import 'support/study_commit_stub.dart';
import 'support/study_widget_harness.dart';

/// **BR-157, one file, three modes.** Nothing graded is drawn before the write
/// holding it has committed.
///
/// **Why this could not be checked before.** The three modes took a
/// fire-and-forget `void` callback, so there was no moment between the tap and
/// the write for a test to look at — the widget had already painted its verdict
/// by the time anything else ran. With the receipt typed, the three states a
/// write actually has are three states a test can stand in: still open,
/// committed, refused.
///
/// The refused case is the one that matters most and reads the least: a screen
/// showing a verdict the session has no record of is indistinguishable from a
/// correct one until the next read.
void main() {
  StudyCardModel card(String id) => StudyCardModel(
    id: id,
    front: 'front-$id',
    back: 'back-$id',
    example: 'an example with ___ in it',
    hint: null,
    pronunciation: null,
    frontFolded: 'front-$id',
    backFolded: 'back-$id',
  );

  StudyTurnModel turnOf(String id) => StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: 'session-1',
      mode: StudyMode.fill,
      round: 1,
      cardId: id,
      position: 0,
      status: StudyQueueItemStatus.pending,
      availableAt: 0,
      answersInSession: 0,
      remainingMs: null,
      isRevealed: false,
      direction: null,
    ),
    progress: const StudyStageProgressModel(
      round: 1,
      done: 0,
      total: 1,
      completedCardIds: <String>[],
    ),
    card: card(id),
  );

  group('guess draws nothing until the write is in', () {
    final question = const GuessModeHandler().buildQuestion(
      term: card('a'),
      pool: <StudyCardModel>[
        for (final id in <String>['a', 'b', 'c', 'd', 'e']) card(id),
      ],
      random: Random(1),
    )!;

    Future<GuessQuestionSectionWidget> pumpQuestion(
      WidgetTester tester,
      PendingCommit write, {
      List<bool>? shown,
    }) async {
      final widget = GuessQuestionSectionWidget(
        question: question,
        turn: turnOf('a'),
        onChosen: (_) => write.future,
        onFeedbackShown: ({required isCorrect}) async => shown?.add(isCorrect),
      );
      await tester.pumpWidget(wrapForTest(widget, isScrollable: false));

      return widget;
    }

    testWidgets('a chosen option is not marked while its write is open', (
      tester,
    ) async {
      final write = PendingCommit();
      await pumpQuestion(tester, write);

      await tester.tap(find.text(question.options.first.text));
      await tester.pumpAndSettle();

      expect(_hasVerdictIcon(tester), isFalse);
      expect(write.isPending, isTrue);

      write.commit('a');
      await tester.pumpAndSettle();
    });

    testWidgets('the mark appears once the write has committed', (
      tester,
    ) async {
      final write = PendingCommit();
      final shown = <bool>[];
      await pumpQuestion(tester, write, shown: shown);

      await tester.tap(find.text(question.options.first.text));
      await tester.pump();
      write.commit('a');
      await tester.pumpAndSettle();

      expect(_hasVerdictIcon(tester), isTrue);
      expect(
        shown,
        hasLength(1),
        reason: 'the hold starts once, after the mark',
      );
    });

    testWidgets('a refused write leaves the question askable', (tester) async {
      // The alternative is a screen that has stopped responding without saying
      // why: no verdict, and no way to answer either.
      final write = PendingCommit();
      final shown = <bool>[];
      await pumpQuestion(tester, write, shown: shown);

      await tester.tap(find.text(question.options.first.text));
      await tester.pump();
      write.refuse();
      await tester.pumpAndSettle();

      expect(_hasVerdictIcon(tester), isFalse);
      expect(shown, isEmpty, reason: 'nothing was shown, so nothing is held');
    });

    testWidgets('a second tap during the write is not a second answer', (
      tester,
    ) async {
      var writes = 0;
      final write = PendingCommit();
      await tester.pumpWidget(
        wrapForTest(
          GuessQuestionSectionWidget(
            question: question,
            turn: turnOf('a'),
            onChosen: (_) {
              writes += 1;

              return write.future;
            },
          ),
          isScrollable: false,
        ),
      );

      await tester.tap(find.text(question.options.first.text));
      await tester.pump();
      await tester.tap(find.text(question.options.last.text));
      await tester.pump();

      expect(writes, 1);

      write.commit('a');
      await tester.pumpAndSettle();
    });
  });

  group('fill draws nothing until the write is in', () {
    Future<void> pumpField(
      WidgetTester tester,
      PendingCommit write, {
      List<bool>? shown,
    }) => tester.pumpWidget(
      wrapForTest(
        FillAnswerSectionWidget(
          turn: turnOf('c1'),
          onGraded: (_) => write.future,
          onFeedbackShown: ({required isCorrect}) async =>
              shown?.add(isCorrect),
        ),
        isScrollable: false,
      ),
    );

    testWidgets('Check does not grade the field while its write is open', (
      tester,
    ) async {
      final write = PendingCommit();
      await pumpField(tester, write);

      await tester.enterText(find.byType(TextField), 'front-c1');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      // Still asking: the field is there and Check has not become a verdict.
      expect(find.byType(TextField), findsOneWidget);

      write.commit('c1');
      await tester.pumpAndSettle();
    });

    testWidgets('the verdict appears once the write has committed', (
      tester,
    ) async {
      final write = PendingCommit();
      final shown = <bool>[];
      await pumpField(tester, write, shown: shown);

      await tester.enterText(find.byType(TextField), 'front-c1');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();
      write.commit('c1');
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(shown, <bool>[true]);
    });

    testWidgets('a refused write leaves the answer typed and submittable', (
      tester,
    ) async {
      final write = PendingCommit();
      final shown = <bool>[];
      await pumpField(tester, write, shown: shown);

      await tester.enterText(find.byType(TextField), 'front-c1');
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump();
      write.refuse();
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(find.text('Check'), findsOneWidget);
      expect(shown, isEmpty);
      // Nothing cleared and nothing greyed: the turn never happened, so the
      // answer is still the one the learner is waiting on.
      expect(field.controller!.text, 'front-c1');
      expect(field.readOnly, isFalse);
      // And the caret is back, so the retry is a second tap on Check rather
      // than a tap on the card followed by one on Check.
      expect(field.focusNode!.hasFocus, isTrue);
    });

    testWidgets('a locked session cannot be typed into', (tester) async {
      // `isLocked` is the session already busy with somebody else's write.
      await tester.pumpWidget(
        wrapForTest(
          FillAnswerSectionWidget(
            turn: turnOf('c1'),
            isLocked: true,
            onGraded: (_) async => commitOf('c1'),
          ),
          isScrollable: false,
        ),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    });
  });

  group('recall writes nothing for a look (BR-159)', () {
    Future<void> pumpTimer(
      WidgetTester tester,
      PendingCommit write, {
      List<bool>? shown,
      List<String>? order,
    }) => tester.pumpWidget(
      wrapForTest(
        RecallTimerSectionWidget(
          turn: turnOf('c1'),
          onOutcome: (_) {
            order?.add('write');

            return write.future;
          },
          onFeedbackShown: ({required isCorrect}) async {
            order?.add('advance');
            shown?.add(isCorrect);
          },
        ),
        isScrollable: false,
      ),
    );

    testWidgets('revealing the back opens no transaction at all', (
      tester,
    ) async {
      // **The strongest form of "commit before feedback" is having nothing to
      // commit.** Reveal used to write the correct action and reveal on the
      // receipt, which made a glance at the back worth a promotion. What it
      // does now is uncover the card and ask.
      final order = <String>[];
      final write = PendingCommit();
      await pumpTimer(tester, write, order: order);

      await tester.tap(find.text('Show answer'));
      await tester.pump();

      expect(order, isEmpty);
      expect(write.isPending, isTrue);
      expect(find.text('back-c1'), findsOneWidget);
      expect(find.text('Remembered'), findsOneWidget);
    });

    testWidgets('the verdict advances only once its write has committed', (
      tester,
    ) async {
      final order = <String>[];
      final shown = <bool>[];
      final write = PendingCommit();
      await pumpTimer(tester, write, shown: shown, order: order);

      await tester.tap(find.text('Show answer'));
      await tester.pump();
      await tester.tap(find.text('Remembered'));
      await tester.pump();

      expect(order, <String>['write'], reason: 'nothing has moved on yet');

      write.commit('c1');
      await tester.pumpAndSettle();

      expect(order, <String>['write', 'advance']);
      expect(shown, <bool>[true]);
    });

    testWidgets('a refused verdict advances nothing and keeps the choice', (
      tester,
    ) async {
      final shown = <bool>[];
      final write = PendingCommit();
      await pumpTimer(tester, write, shown: shown);

      await tester.tap(find.text('Show answer'));
      await tester.pump();
      await tester.tap(find.text('Forgot'));
      await tester.pump();
      write.refuse();
      await tester.pumpAndSettle();

      expect(shown, isEmpty);
      expect(find.text('back-c1'), findsOneWidget);
      expect(find.text('Forgot'), findsOneWidget);
    });

    testWidgets('a timeout stays covered until its write is in', (
      tester,
    ) async {
      // The one place the back is still held back: the verdict belongs to the
      // clock, and printing it over an open transaction is a claim the session
      // cannot back up.
      final write = PendingCommit();
      await pumpTimer(tester, write);

      await tester.pump(kRecallTurnLimit);
      await tester.pump();

      // The row is what earns the sentence. The control keeps its place so the
      // screen does not resize under the learner, but it has no target.
      expect(find.text('back-c1'), findsNothing);
      expect(find.textContaining("Time's up"), findsNothing);

      write.commit('c1');
      await tester.pumpAndSettle();

      expect(find.text('back-c1'), findsOneWidget);
      expect(find.textContaining("Time's up"), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });
  });
}

/// Whether the question is showing a graded row — the tick or the cross that
/// only a committed answer earns.
bool _hasVerdictIcon(WidgetTester tester) =>
    find.byIcon(Icons.check).evaluate().isNotEmpty ||
    find.byIcon(Icons.close).evaluate().isNotEmpty;
