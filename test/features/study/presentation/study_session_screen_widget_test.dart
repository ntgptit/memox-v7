import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_direction_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_summary_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_blocked_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_session_frame_section_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_swipe_deck_widget.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../domain/support/fake_study_repository.dart';

/// The session screen as the user reaches it, not as its parts.
///
/// **The lesson M5.7 wrote down, applied.** A widget with a test of its own can
/// still be code nothing renders: the frame passing its own tests says nothing
/// about whether a session screen puts it on screen. This file is the path from
/// the screen to the chrome, and it is what makes the frame's tests mean
/// something.
void main() {
  final now = DateTime.utc(2026, 8, 7, 2);

  StudyTurnModel turnOf(StudyMode mode, {int done = 2, int total = 5}) =>
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
        progress: StudyStageProgressModel(
          round: 1,
          done: done,
          total: total,
          completedCardIds: <String>[],
        ),
        card: const StudyCardModel(
          id: 'c1',
          front: '사과',
          back: 'apple',
          example: null,
          hint: null,
          pronunciation: null,
          frontFolded: '사과',
          backFolded: 'apple',
        ),
      );

  Future<FakeStudyRepository> pumpSession(
    WidgetTester tester, {
    required StudyMode mode,
    required StudySessionKind kind,
    SchedulerType schedulerType = SchedulerType.sm2,

    /// Makes the epilogue read throw, which is how the summary provider comes
    /// back with `null` and the finished screen falls back to its empty state.
    bool summaryFails = false,
  }) async {
    // BR-208: an `sm2` self-assess review is refused without a recall direction,
    // so the screen would render its error state rather than a session. Korean
    // first is what every review did before BR-203, which keeps every assertion
    // below about the chrome rather than about the direction.
    final direction =
        schedulerType == SchedulerType.sm2 &&
            kind == StudySessionKind.reviewing &&
            mode == StudyMode.selfAssess
        ? StudySessionDirection.koreanToMeaning
        : null;

    // `sm2`, so `self_assess` is a review mode the algorithm actually offers
    // (BR-146). Asking an `eight_box` deck for it is refused, and the screen
    // would then be its error state rather than a session.
    final repository =
        (summaryFails
              ? _FailingSummary(
                  schedulerType: schedulerType,
                  stageExhausted: false,
                )
              : FakeStudyRepository(
                  schedulerType: schedulerType,
                  stageExhausted: false,
                ))
          ..nextTurn_ = turnOf(mode);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studyRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => now),
          utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: StudySessionScreen(
            deckId: 'deck-1',
            kind: kind,
            reviewMode: kind == StudySessionKind.reviewing ? mode : null,
            direction: direction,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return repository;
  }

  testWidgets('the running session wears the frame', (tester) async {
    await pumpSession(
      tester,
      mode: StudyMode.selfAssess,
      kind: StudySessionKind.reviewing,
    );

    // The deck name comes from the same read as the session (AD-13), so it is
    // on screen without a second query.
    expect(find.textContaining('CARDS DUE'), findsOneWidget);
    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.text('Flip the card, then say how it went'), findsOneWidget);
    expect(find.text('사과'), findsOneWidget);
  });

  testWidgets('the card stays on screen while the next turn is fetched', (
    tester,
  ) async {
    // **The layout shift `browse` showed on every step.** Advancing replaced
    // the whole body with a spinner, so each swipe threw the card away, drew a
    // loading state and drew the next card — two full relayouts between two
    // cards that differ by one string. The turn is still in state for the whole
    // of that write-then-fetch, so it has to stay on screen.
    final repository = await pumpSession(
      tester,
      mode: StudyMode.browse,
      kind: StudySessionKind.learning,
    );

    expect(find.text('사과'), findsOneWidget);

    final gate = Completer<void>();
    repository.nextTurnGate = gate;

    await tester.drag(
      find.byType(StudySwipeDeckWidget),
      const Offset(-(kStudySwipeThreshold + 20), 0),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byType(MxLoadingState),
      findsNothing,
      reason: 'a turn is still in state, so there is nothing to wait for',
    );
    expect(find.text('사과'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('a session that could not be left keeps its card and says so', (
    tester,
  ) async {
    // **The failure used to erase the screen.** `error != null` swapped the
    // whole body for "Nothing to review yet" — a message about an empty deck,
    // drawn over a card the user could still answer. A recoverable failure has
    // to leave something to recover *to*.
    final repository = await pumpSession(
      tester,
      mode: StudyMode.selfAssess,
      kind: StudySessionKind.reviewing,
    );
    repository.endSessionFails = true;

    await tester.tap(find.byTooltip('Close session'));
    await tester.pumpAndSettle();

    expect(find.byType(MxErrorState), findsNothing);
    expect(
      find.text('Nothing to review yet. Come back when a card is due.'),
      findsNothing,
    );
    expect(find.byType(StudySessionFrameSectionWidget), findsOneWidget);
    expect(find.text('사과'), findsOneWidget);

    // Told, and offered the one action that makes sense. Dismissing it leaves
    // the user studying, which is the other honest option.
    expect(
      find.text('Could not leave the session. Your answers are saved.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('retrying from the bar leaves once the write succeeds', (
    tester,
  ) async {
    final repository = await pumpSession(
      tester,
      mode: StudyMode.selfAssess,
      kind: StudySessionKind.reviewing,
    );
    repository.endSessionFails = true;

    await tester.tap(find.byTooltip('Close session'));
    await tester.pumpAndSettle();

    repository.endSessionFails = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.ended, hasLength(1));
  });

  testWidgets('no mode is unmounted to fetch its replacement', (tester) async {
    // **This test used to assert the opposite, and the opposite was the bug.**
    // Advancing replaced the whole body with a spinner for every mode but
    // `browse` — so the answer a person had just given was drawn into a widget
    // already on its way out, and the verdict each mode had gone to some
    // trouble to show was never on screen long enough to read. `browse` was
    // exempted first; the exemption was right and its scope was wrong.
    final repository = await pumpSession(
      tester,
      mode: StudyMode.fill,
      kind: StudySessionKind.reviewing,
      schedulerType: SchedulerType.eightBox,
    );

    final gate = Completer<void>();
    repository.nextTurnGate = gate;

    final container = ProviderScope.containerOf(
      tester.element(find.byType(StudySessionScreen)),
    );
    final controller = container.read(
      studySessionControllerProvider('deck-1').notifier,
    );
    unawaited(
      controller
          .submitAnswer(StudyAction.remembered)
          .then((_) => controller.advance()),
    );

    // Plain pumps, never `pumpAndSettle`: the fetch is held open by the gate,
    // so settling waits for something with no intention of finishing.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.byType(MxLoadingState), findsNothing);
    expect(find.byType(StudySessionFrameSectionWidget), findsOneWidget);
    // The card itself, not just its chrome: the body is what used to be
    // replaced, and a frame around a blocked state would satisfy the line
    // above while showing the user nothing to act on.
    expect(find.byType(StudyBlockedSectionWidget), findsNothing);

    gate.complete();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  });

  testWidgets('closing ends the session rather than popping the route', (
    tester,
  ) async {
    // BR-82. Popping would leave the row `in_progress`, and the next launch
    // would offer to resume a session the user believes they closed (BR-103).
    final repository = await pumpSession(
      tester,
      mode: StudyMode.selfAssess,
      kind: StudySessionKind.reviewing,
    );

    await tester.tap(find.byTooltip('Close session'));
    await tester.pumpAndSettle();

    expect(repository.ended, hasLength(1));
    expect(repository.ended.single.status, StudySessionStatus.abandoned);
    expect(repository.ended.single.reason, StudySessionEndReason.userExit);
  });

  testWidgets('a finished session shows no frame', (tester) async {
    // The summary is the whole screen: a top bar with a ✕ that ends a session
    // already ended, and a hint telling the user to flip a card that is gone,
    // would both be lying.
    final repository = await pumpSession(
      tester,
      mode: StudyMode.selfAssess,
      kind: StudySessionKind.reviewing,
    );

    await tester.tap(find.byTooltip('Close session'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Close session'), findsNothing);
    expect(find.text('Flip the card, then say how it went'), findsNothing);
    expect(repository.ended, hasLength(1));
  });

  testWidgets('a finished session with no counts still offers the way out', (
    tester,
  ) async {
    // **The one branch that had removed every control.** The screen wears
    // `MxShellChrome.none`, and finishing drops the frame and its ✕ with it —
    // so when the epilogue read failed the user was left with one centred
    // sentence and nothing to press. The summary beside it has always drawn
    // `Back to deck`; the fallback says less than it, not nothing.
    await pumpSession(
      tester,
      mode: StudyMode.selfAssess,
      kind: StudySessionKind.reviewing,
      summaryFails: true,
    );

    await tester.tap(find.byTooltip('Close session'));
    await tester.pumpAndSettle();

    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.text('Back to deck'), findsOneWidget);
    expect(
      tester.widget<MxActionButton>(find.byType(MxActionButton)).onPressed,
      isNotNull,
      reason: 'a label with no callback renders a button that does nothing',
    );

    // The negative half, and the reason this test exists rather than a
    // `findsOneWidget` on the label: the button is only the *only* control
    // while these two stay absent, and it is their absence that made the
    // missing button unnoticeable in the first place.
    expect(find.byType(AppBar), findsNothing);
    expect(find.byTooltip('Close session'), findsNothing);
  });
}

/// Refuses to summarise, the way a failed epilogue read reaches the screen:
/// `studySessionSummaryProvider` swallows it and returns null (BR-85 has
/// already ended the session, so there is nothing to retry).
final class _FailingSummary extends FakeStudyRepository {
  _FailingSummary({
    required super.schedulerType,
    required super.stageExhausted,
  });

  @override
  Future<StudySessionSummaryModel> sessionSummary({
    required String sessionId,
    required List<StudyAction> wrongActions,
  }) async => throw StateError('the summary could not be read');
}
