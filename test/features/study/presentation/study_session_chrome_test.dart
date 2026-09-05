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
import 'package:memox/features/study/domain/models/study_direction_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../domain/support/fake_study_repository.dart';

/// The session screen as the user reaches it, not as its parts.
///
/// **The lesson M5.7 wrote down, applied.** A widget with a test of its own can
/// still be code nothing renders: the frame passing its own tests says nothing
/// about whether a session screen puts it on screen. This file is the path from
/// the screen to the chrome, and it is what makes the frame's tests mean
/// something.
import 'package:memox/shared/widgets/mx_session_top_bar.dart';

/// A20.1 P1-15, corrective pass — the study session is custom chrome. Pushed
/// through a real route it must not grow an inferred Material bar or a Back
/// arrow above its own top bar (BR-82: leaving a session goes through the ✕).
void main() {
  final now = DateTime.utc(2026, 8, 7, 2);

  StudyTurnModel turnOf(StudyMode mode) => StudyTurnModel(
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
      done: 2,
      total: 5,
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

  testWidgets('a pushed session keeps its own bar and gains no Material one', (
    tester,
  ) async {
    // `sm2` with a recall direction: the one combination a self-assess
    // review is accepted with (BR-208), so the screen renders a session.
    final repository = FakeStudyRepository(
      schedulerType: SchedulerType.sm2,
      stageExhausted: false,
    )..nextTurn_ = turnOf(StudyMode.selfAssess);

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
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const StudySessionScreen(
                      deckId: 'deck-1',
                      kind: StudySessionKind.reviewing,
                      reviewMode: StudyMode.selfAssess,
                      direction: StudySessionDirection.koreanToMeaning,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(StudySessionScreen), findsOneWidget);
    expect(find.byType(MxSessionTopBar), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BackButton), findsNothing);
  });
}
