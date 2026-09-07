@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_summary_model.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_blocked_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_summary_section_widget.dart';

import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';

import '../features/study/domain/support/fake_study_repository.dart';
import '../support/study_render.dart';
import '../visual_audit/study_audit_harness.dart';

/// The three faces `StudySessionScreen` renders that had **no picture anywhere**
/// — not a golden, not a catalogue scenario (EV-02,
/// `docs/reviews/impeccable-uiux-audit.md` §2).
///
/// `study_modes_demo_test.dart` photographs the five *asking* stages. Every
/// branch after them was invisible: the summary a session ends on, the blocked
/// face a stage refuses into, and the error face an unopenable session lands on.
/// Their primitives are pinned by `test/shared/widgets/goldens/empty_state_*`
/// and `error_state_*` — that fixes their **appearance** and says nothing about
/// their **composition**, which is what these faces are.
///
/// **The summary gets two renders, and the pair is the point.**
/// `StudySummarySectionWidget` exists to keep *"a session that stopped is not a
/// session that finished"* — the heading comes from
/// `StudySessionSummaryModel.hasCompleted`, and an early end says what happened
/// before it says how much got done. One golden could not show that; two can
/// only disagree if the distinction is real.
///
/// **Mounted through the production screen, not through the section widget.**
/// A body-only render is what put a hint over an answered board for four
/// releases (EV-01), and the composition here is exactly what is under review:
/// which face the screen picks, and what chrome it keeps when it does.
void main() {
  /// A small reviewing deck in the shape BR-08 allows — a Korean term on the
  /// front, a two-language meaning on the back.
  ///
  /// It is never the subject of these renders: three of the four faces replace
  /// the card entirely. It exists so the session has something to open on, and
  /// so the blocked face is refusing a real turn rather than an empty one.
  List<StudyCardModel> summaryDeck() => <StudyCardModel>[
    const StudyCardModel(
      id: 'c1',
      front: '사과',
      back: 'quả táo',
      example: null,
      hint: null,
      pronunciation: null,
      frontFolded: '사과',
      backFolded: 'quả táo',
    ),
    const StudyCardModel(
      id: 'c2',
      front: '바다',
      back: 'biển',
      example: null,
      hint: null,
      pronunciation: null,
      frontFolded: '바다',
      backFolded: 'biển',
    ),
  ];

  StudyTurnModel summaryTurn({StudyMode mode = StudyMode.selfAssess}) =>
      StudyTurnModel(
        item: StudyQueueItemEntity(
          sessionId: 'session-1',
          mode: mode,
          round: 1,
          cardId: 'c1',
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
          done: 12,
          total: 15,
          completedCardIds: <String>[],
          roundCardIds: <String>['c1', 'c2'],
        ),
        card: summaryDeck().first,
      );

  for (final (label, brightness) in <(String, Brightness)>[
    ('light', Brightness.light),
    ('dark', Brightness.dark),
  ]) {
    testWidgets('study summary — completed — $label', (tester) async {
      final repository = FakeStudyRepository(stageExhausted: false)
        ..cards = summaryDeck()
        ..nextTurn_ = summaryTurn()
        ..summary_ = const StudySessionSummaryModel(
          kind: StudySessionKind.reviewing,
          status: StudySessionStatus.completed,
          endReason: null,
          finishedCards: 12,
          answeredCards: 12,
          wrongTurns: 3,
          totalTurns: 15,
        );

      await pumpReview(
        tester,
        ReviewApp(
          brightness: brightness,
          home: studyScreenWith(
            repository,
            const StudySessionScreen(
              deckId: 'deck-1',
              kind: StudySessionKind.reviewing,
              reviewMode: StudyMode.match,
            ),
          ),
        ),
      );

      // The user's own route to the epilogue: the ✕ ends the session (BR-82)
      // and hands over the summary. Reaching it any other way would photograph
      // a state the screen can hold but nobody arrives at.
      await tester.tap(find.byTooltip('Close session'));
      await tester.pumpAndSettle();

      // **The golden cannot be the only witness** — the lesson
      // `study_modes_demo_test.dart` records after a fixture opened the wrong
      // session kind and the picture looked just as green. These are what a
      // wrong face cannot satisfy.
      expect(find.byType(StudySummarySectionWidget), findsOneWidget);
      expect(find.text('Session finished'), findsOneWidget);
      expect(find.text('Session stopped'), findsNothing);

      await matchesReviewGolden('goldens/study_summary_completed_$label.png');
    });

    testWidgets('study summary — stopped — $label', (tester) async {
      final repository = FakeStudyRepository(stageExhausted: false)
        ..cards = summaryDeck()
        ..nextTurn_ = summaryTurn()
        // Same counts as the completed render on purpose: the two faces differ
        // by `status`, and holding the numbers still is what proves the heading
        // is reading the status rather than the tally.
        ..summary_ = const StudySessionSummaryModel(
          kind: StudySessionKind.reviewing,
          status: StudySessionStatus.abandoned,
          endReason: StudySessionEndReason.userExit,
          finishedCards: 12,
          answeredCards: 12,
          wrongTurns: 3,
          totalTurns: 15,
        );

      await pumpReview(
        tester,
        ReviewApp(
          brightness: brightness,
          home: studyScreenWith(
            repository,
            const StudySessionScreen(
              deckId: 'deck-1',
              kind: StudySessionKind.reviewing,
              reviewMode: StudyMode.match,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Close session'));
      await tester.pumpAndSettle();

      expect(find.byType(StudySummarySectionWidget), findsOneWidget);
      expect(find.text('Session stopped'), findsOneWidget);
      expect(find.text('Session finished'), findsNothing);

      await matchesReviewGolden('goldens/study_summary_stopped_$label.png');
    });

    testWidgets('study session blocked — $label', (tester) async {
      // `studyModeView` returns null when a binary-graded stage has no action
      // to write, and the screen routes that to the blocked face rather than to
      // a board that cannot be answered. It used to render `SizedBox.shrink()`
      // — nothing to read, nothing to tap, force-quitting the only way out —
      // so what this picture is for is that the refusal *says so* and offers to
      // leave (BR-82).
      // One card, so `match` has no pair to deal and the stage has nothing it
      // can offer — which is the condition, not a contrivance: a board needs
      // two sides and a one-card round cannot make one.
      final repository = FakeStudyRepository(stageExhausted: false)
        ..cards = <StudyCardModel>[summaryDeck().first]
        ..nextTurn_ = summaryTurn(mode: StudyMode.match);

      await pumpReview(
        tester,
        ReviewApp(
          brightness: brightness,
          home: studyScreenWith(
            repository,
            const StudySessionScreen(
              deckId: 'deck-1',
              kind: StudySessionKind.reviewing,
              reviewMode: StudyMode.match,
            ),
          ),
        ),
      );

      expect(find.byType(StudyBlockedSectionWidget), findsOneWidget);
      expect(find.text('This card cannot be shown here'), findsOneWidget);
      expect(find.text('Leave session'), findsOneWidget);

      await matchesReviewGolden('goldens/study_session_blocked_$label.png');
    });

    testWidgets('study session error — $label', (tester) async {
      // The session cannot be opened at all, so there is no turn to fall back
      // on — the one case the full-body error face is for. A failure *with* a
      // card behind it deliberately does not land here.
      final repository = FakeStudyRepository(openSessionFails: true);

      await pumpReview(
        tester,
        ReviewApp(
          brightness: brightness,
          home: studyScreenWith(
            repository,
            const StudySessionScreen(
              deckId: 'deck-1',
              kind: StudySessionKind.reviewing,
              reviewMode: StudyMode.selfAssess,
            ),
          ),
        ),
      );

      expect(find.text("Couldn't open this session"), findsOneWidget);
      // The way out rather than a retry: `start()` runs once from `initState`,
      // so re-reading is not on offer and the honest action is the pop.
      expect(find.text('Back to deck'), findsOneWidget);

      await matchesReviewGolden('goldens/study_session_error_$label.png');
    });
  }
}
