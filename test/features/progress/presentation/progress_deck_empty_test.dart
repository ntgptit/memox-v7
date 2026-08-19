import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';
import 'package:memox/features/progress/presentation/screens/progress_deck_screen.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_range_selector_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';

/// The states with nothing to list, and the two ways a read can fail.
///
/// Split from `progress_deck_screen_test.dart` at the source-size ceiling. The
/// seam is the one the screen itself draws: that file covers a level that
/// *loaded and has rows*, this one covers every level that does not.
void main() {
  final english = AppLocalizationsEn();

  /// A level with two busy decks and one nobody touched — the state the unit
  /// caption has to appear in.
  FakeProgressRepository mixedLevel() => FakeProgressRepository.withSnapshot(
    activitySnapshot(
      decks: <DeckActivity>[
        deckActivity(
          deckId: 'busy',
          name: 'Spanish',
          last7Days: activityMetrics(
            activeCards: 42,
            activeDays: 6,
            learning: 12,
            reviewing: 60,
          ),
        ),
        deckActivity(deckId: 'idle', name: 'Idle deck'),
      ],
      scopeLast7Days: activityMetrics(
        activeCards: 45,
        activeDays: 6,
        learning: 12,
        reviewing: 60,
      ),
    ),
  );

  group('nothing to list', () {
    testWidgets('no decks at all shows the library empty state alone', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        // Stated, not inherited: the fake's default level is the composed one
        // with a deck in it, because that is the screen a user opens. A test
        // whose whole subject is the no-decks face has to ask for it.
        repository: FakeProgressRepository(
          activity: (String? deckId) =>
              Stream<DeckActivitySnapshot>.value(emptyActivitySnapshot()),
        ),
        screen: const ProgressDeckScreen(),
      );

      expect(find.text(english.progressEmptyDecksTitle), findsOneWidget);
      // No window control and no panel of four zeroes: with no decks there is
      // no window in which anything could have happened.
      expect(find.byType(ProgressRangeSelectorWidget), findsNothing);
      expect(find.byType(ProgressSummaryWidget), findsNothing);
    });

    testWidgets('the unit of the bottom row is stated once, in the panel', (
      tester,
    ) async {
      // The grid holds two units: cards and days above, card-days below. Without
      // this line `12` and `60` beside `45` read as arithmetic that does not add
      // up — and it is a caption rather than four longer words because a word
      // long enough to carry the unit is clipped in a 320dp cell at scale 2.0.
      await pumpProgressScreen(
        tester,
        repository: mixedLevel(),
        screen: const ProgressDeckScreen(),
      );

      expect(find.text(english.progressCardDayUnitNote), findsOneWidget);
    });

    testWidgets('a deck with no sub-decks keeps its own figures', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.withSnapshot(
          activitySnapshot(
            decks: const <DeckActivity>[],
            scopeDeckId: 'leaf',
            scopeName: 'Verbs',
            scopeLast7Days: activityMetrics(activeCards: 9, activeDays: 3),
          ),
        ),
        screen: const ProgressDeckScreen(deckId: 'leaf'),
      );

      expect(find.text(english.progressEmptySubDecksTitle), findsOneWidget);
      expect(find.byType(ProgressSummaryWidget), findsOneWidget);
      expect(find.text('Verbs'), findsOneWidget);
    });
  });

  group('failure', () {
    testWidgets('a failed read offers a retry that re-opens it', (
      tester,
    ) async {
      var attempts = 0;
      final repository = FakeProgressRepository(
        activity: (_) {
          attempts++;

          return attempts == 1
              ? Stream<Never>.error(
                  const DatabaseFailure(message: 'read failed'),
                )
              : Stream.value(activitySnapshot(decks: <DeckActivity>[]));
        },
      );

      await pumpProgressScreen(
        tester,
        repository: repository,
        screen: const ProgressDeckScreen(),
      );

      expect(find.text(english.progressErrorTitle), findsOneWidget);
      // The diagnostic never reaches the screen: it is unlocalized and written
      // for a log.
      expect(find.textContaining('read failed'), findsNothing);

      await tester.tap(find.text(english.progressErrorRetryAction));
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.byType(MxErrorState), findsNothing);
    });

    testWidgets('a deck that is gone offers the way back, not a retry', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.failing(
          const NotFoundFailure(message: 'gone'),
        ),
        screen: const ProgressDeckScreen(deckId: 'ghost'),
      );

      expect(find.text(english.progressDeckMissingTitle), findsOneWidget);
      expect(find.text(english.progressDeckMissingBackAction), findsOneWidget);
      // Retry would re-read and fail the same way, every time.
      expect(find.text(english.progressErrorRetryAction), findsNothing);
      expect(find.byType(MxEmptyState), findsOneWidget);
    });
  });
}
