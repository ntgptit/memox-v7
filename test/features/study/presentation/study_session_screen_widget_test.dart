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
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
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
          backFolded: 'apple',
        ),
      );

  Future<FakeStudyRepository> pumpSession(
    WidgetTester tester, {
    required StudyMode mode,
    required StudySessionKind kind,
    SchedulerType schedulerType = SchedulerType.sm2,
  }) async {
    // `sm2`, so `self_assess` is a review mode the algorithm actually offers
    // (BR-146). Asking an `eight_box` deck for it is refused, and the screen
    // would then be its error state rather than a session.
    final repository = FakeStudyRepository(
      schedulerType: schedulerType,
      stageExhausted: false,
    )..nextTurn_ = turnOf(mode);

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
}
