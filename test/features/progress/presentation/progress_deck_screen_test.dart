import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/presentation/screens/progress_deck_screen.dart';
import 'package:memox/features/progress/presentation/widgets/items/progress_deck_row_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_range_selector_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';

/// Every state Progress by Deck can be in, and the two things a person does on
/// it: switch the window, and open a deck.
void main() {
  final english = AppLocalizationsEn();

  /// A level with two busy decks and one nobody touched.
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
          last30Days: activityMetrics(
            activeCards: 120,
            activeDays: 24,
            learning: 30,
            reviewing: 200,
          ),
        ),
        deckActivity(
          deckId: 'quiet',
          name: 'Tiếng Nhật',
          last7Days: activityMetrics(activeCards: 3, activeDays: 1),
        ),
        deckActivity(deckId: 'idle', name: 'Idle deck'),
      ],
      scopeLast7Days: activityMetrics(
        activeCards: 45,
        activeDays: 6,
        learning: 12,
        reviewing: 60,
      ),
      scopeLast30Days: activityMetrics(
        activeCards: 123,
        activeDays: 24,
        learning: 30,
        reviewing: 200,
      ),
    ),
  );

  group('loading', () {
    testWidgets('a read that has not answered shows a labelled spinner', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository(
          activity: (_) => const Stream<Never>.empty(),
        ),
        screen: const ProgressDeckScreen(),
      );

      expect(find.byType(MxLoadingState), findsOneWidget);
      // The library level keeps its title through loading: it is a constant, so
      // holding it stops the screen looking replaced every time data arrives.
      expect(find.text(english.progressTitle), findsOneWidget);
    });

    testWidgets('a deck level keeps its app bar while the read runs', (
      tester,
    ) async {
      // The first version returned a null title inside a deck, and
      // `MxContentShell` builds no `AppBar` for a null title — so a level the
      // user was already reading lost its chrome and its back button every time
      // the read re-opened, which local midnight and returning from the
      // background both do.
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository(
          activity: (_) => const Stream<Never>.empty(),
        ),
        screen: const ProgressDeckScreen(deckId: 'deck-1'),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(english.progressTitle), findsOneWidget);
    });

    testWidgets('a deck level keeps its app bar when the read fails', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.failing(
          const DatabaseFailure(message: 'read failed'),
        ),
        screen: const ProgressDeckScreen(deckId: 'deck-1'),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(english.progressErrorTitle), findsOneWidget);
    });
  });

  group('a level with activity', () {
    testWidgets('every deck gets a row, including the one with nothing', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: mixedLevel(),
        screen: const ProgressDeckScreen(),
      );

      expect(find.byType(ProgressDeckRowWidget), findsNWidgets(3));
      expect(find.text('Idle deck'), findsOneWidget);
    });

    testWidgets('rows are ordered busiest first, idle last', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: mixedLevel(),
        screen: const ProgressDeckScreen(),
      );

      final rows = tester
          .widgetList<ProgressDeckRowWidget>(find.byType(ProgressDeckRowWidget))
          .map((ProgressDeckRowWidget row) => row.activity.deckId)
          .toList();

      expect(rows, <String>['busy', 'quiet', 'idle']);
    });

    testWidgets('the summary prints the level total, not a fold of the rows', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: mixedLevel(),
        screen: const ProgressDeckScreen(),
      );

      // 6 active days for the level while its busiest deck also has 6: days do
      // not add up, and a screen that folded them would print 7.
      expect(
        find.descendant(
          of: find.byType(ProgressSummaryWidget),
          matching: find.textContaining(
            '6 ${english.progressActiveDaysMetricWord}',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('no all-zero note when something was studied', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: mixedLevel(),
        screen: const ProgressDeckScreen(),
      );

      expect(find.text(english.progressNoActivityTitle), findsNothing);
    });
  });

  group('switching the window', () {
    testWidgets('changes every figure without re-opening the read', (
      tester,
    ) async {
      final repository = mixedLevel();
      await pumpProgressScreen(
        tester,
        repository: repository,
        screen: const ProgressDeckScreen(),
      );

      final readsBefore = repository.levelReadCount;

      await tester.tap(find.text(english.progressRange30Label));
      await tester.pumpAndSettle();

      // Both windows ride on one snapshot (BR-184), so the switch is a field
      // access. A second read here would mean two snapshots and a spinner.
      expect(repository.levelReadCount, readsBefore);
      expect(find.text(english.progressSummaryLast30DaysTitle), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ProgressSummaryWidget),
          matching: find.textContaining(
            '123 ${english.progressActiveCardsMetricWord}',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('re-orders the list to match the window on screen', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.withSnapshot(
          activitySnapshot(
            decks: <DeckActivity>[
              deckActivity(
                deckId: 'sprint',
                name: 'Sprint',
                last7Days: activityMetrics(activeCards: 30),
                last30Days: activityMetrics(activeCards: 31),
              ),
              deckActivity(
                deckId: 'steady',
                name: 'Steady',
                last7Days: activityMetrics(activeCards: 5),
                last30Days: activityMetrics(activeCards: 90),
              ),
            ],
            scopeLast7Days: activityMetrics(activeCards: 35),
            scopeLast30Days: activityMetrics(activeCards: 121),
          ),
        ),
        screen: const ProgressDeckScreen(),
      );

      List<String> order() => tester
          .widgetList<ProgressDeckRowWidget>(find.byType(ProgressDeckRowWidget))
          .map((ProgressDeckRowWidget row) => row.activity.deckId)
          .toList();

      expect(order(), <String>['sprint', 'steady']);

      await tester.tap(find.text(english.progressRange30Label));
      await tester.pumpAndSettle();

      expect(order(), <String>['steady', 'sprint']);
    });

    testWidgets('the selected pill is marked by more than its colour', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: mixedLevel(),
        screen: const ProgressDeckScreen(),
      );

      // A tick beside the selected label, because `chipTheme` turns Material's
      // own checkmark off — leaving fill as the only difference, which a
      // greyscale screenshot and a colour-blind reader both lose.
      expect(
        find.descendant(
          of: find.byType(ProgressRangeSelectorWidget),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });
  });

  group('nothing studied in the window', () {
    testWidgets('says so in words, and still lists every deck', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.withSnapshot(
          activitySnapshot(
            decks: <DeckActivity>[
              deckActivity(deckId: 'a', name: 'Spanish'),
              deckActivity(deckId: 'b', name: 'Tiếng Nhật'),
            ],
          ),
        ),
        screen: const ProgressDeckScreen(),
      );

      expect(find.text(english.progressNoActivityTitle), findsOneWidget);
      // The rows stay: "which decks did I neglect" is exactly the question
      // asked in this state.
      expect(find.byType(ProgressDeckRowWidget), findsNWidgets(2));
      // And it is not an error state.
      expect(find.byType(MxErrorState), findsNothing);
    });
  });
}
