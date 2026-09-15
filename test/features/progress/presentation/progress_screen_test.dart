import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/extensions/app_ink.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_streak_hero_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_today_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_week_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';
import 'package:memox/shared/widgets/mx_metric_well.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';
import 'package:memox/core/theme/extensions/app_well_fill.dart';

/// The five faces of the Progress screen (UC-12, wireframe S-a…S-e).
///
/// **Which face is on screen and what it says** — nothing else. Behaviour that
/// needs time to pass (live refresh, the midnight rollover), the semantics tree
/// and the locale/theme matrix live in `progress_screen_updates_test.dart`;
/// geometry lives in `progress_screen_geometry_test.dart`. Three files rather
/// than one because the first version reached the guard's 400-line ceiling, and
/// the seam was already there: these tests each pump one state and read it,
/// while the other file pumps a state and then makes something happen to it.
void main() {
  final english = AppLocalizationsEn();

  FakeProgressRepository seeded({
    List<int> totals = const <int>[3, 5, 0, 2, 7, 4, 6],
    List<int>? learning,
    int streak = 6,
    bool? hasLifetimeActivity,
  }) => FakeProgressRepository(
    initial: progressOverviewFixture(
      totals: totals,
      learning: learning,
      streakDays: streak,
      today: DateTime.utc(2026, 8, 12),
      hasLifetimeActivity: hasLifetimeActivity,
    ),
    // **A level with a deck in it, because `/progress` is one screen now.**
    // Without this the fake answers the level read with no decks, the level
    // renders its own empty state under the overview, and a test asserting
    // "this is not the empty face" fails on an empty state that belongs to the
    // other half of the screen. A library with study history and no decks is
    // not a state a user can reach.
    activity: (String? deckId) => Stream<DeckActivitySnapshot>.value(
      activitySnapshot(
        decks: <DeckActivity>[
          deckActivity(deckId: 'deck-1', name: 'Everyday verbs'),
        ],
      ),
    ),
  );

  group('loading (S-a)', () {
    testWidgets('shows the shared loading state, announced to a reader', (
      tester,
    ) async {
      await pumpProgressScreen(tester, repository: FakeProgressRepository());

      expect(
        tester
            .widget<MxLoadingState>(find.byType(MxLoadingState))
            .semanticsLabel,
        english.progressLoadingLabel,
      );
      // The title stays put while the body swaps, so the screen does not appear
      // to be replaced every time the data changes.
      expect(find.text(english.progressTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('loaded (S-b)', () {
    testWidgets('shows all three sections, in order', (tester) async {
      await pumpProgressScreen(tester, repository: seeded());

      expect(find.byType(ProgressStreakHeroWidget), findsOneWidget);
      expect(find.byType(ProgressTodayWidget), findsOneWidget);
      expect(find.byType(ProgressWeekWidget), findsOneWidget);
      expect(find.byType(MxEmptyState), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the hero states the streak and today together', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: seeded(totals: const <int>[1, 1, 1, 1, 1, 1, 6], streak: 7),
      );

      // **Scoped to the hero, because the composed screen renders "7 days"
      // twice.** The streak headline says it, and so does the range selector's
      // 7-day pill — which is pinned *above* the three sections, not below
      // them: two different meanings, one string, 24dp apart. An
      // unscoped finder reports two and reads as a duplicate-render bug, which
      // is not what is wrong. What *is* wrong is on screen for the user and is
      // recorded as a divergence rather than fixed here: changing either piece
      // of copy is the owner's call.
      expect(
        find.descendant(
          of: find.byType(ProgressStreakHeroWidget),
          matching: find.text(english.progressStreakDaysLabel(7)),
        ),
        findsOneWidget,
      );
      expect(find.text(english.progressStreakTodayLine(6)), findsOneWidget);
    });

    testWidgets('Today names its unit and both halves of the partition', (
      tester,
    ) async {
      // The unit is the point: the count is distinct cards, not turns taken
      // (BR-192), and a bare figure would be read as the latter.
      await pumpProgressScreen(
        tester,
        repository: seeded(
          totals: const <int>[0, 0, 0, 0, 0, 0, 9],
          learning: const <int>[0, 0, 0, 0, 0, 0, 4],
        ),
      );

      expect(find.text(english.progressTodayCardsLabel(9)), findsOneWidget);
      expect(find.text(english.progressTodayLearningLabel), findsOneWidget);
      expect(find.text(english.progressTodayReviewingLabel), findsOneWidget);
      expect(find.text('4'), findsWidgets);
      expect(find.text('5'), findsWidgets);
    });

    testWidgets('the chart shows seven rows, zeros included, today last', (
      tester,
    ) async {
      // A zero day is data (BR-196, P4). Dropping it would make the chart a
      // five-day week that reads as quiet rather than as broken.
      await pumpProgressScreen(
        tester,
        repository: seeded(totals: const <int>[3, 0, 0, 2, 7, 0, 6]),
      );

      final chart = find.byType(ProgressWeekWidget);
      expect(
        find.descendant(of: chart, matching: find.text('0')),
        findsNWidgets(3),
      );
      expect(
        find.descendant(
          of: chart,
          matching: find.text(english.progressWeekTodayLabel),
        ),
        findsOneWidget,
      );
      // 12 August 2026 is a Wednesday, so the window opens on the Thursday
      // before it.
      expect(
        find.descendant(
          of: chart,
          matching: find.text(english.progressWeekdayShortLabel('4')),
        ),
        findsOneWidget,
      );
    });
  });

  group('today zero with the streak held (S-c)', () {
    testWidgets('keeps the streak figure and explains it', (tester) async {
      // The face that needs its own sentence: "6 days" beside a Today of zero
      // reads as a contradiction until the copy says the streak is being held.
      await pumpProgressScreen(
        tester,
        repository: seeded(totals: const <int>[2, 2, 2, 2, 2, 2, 0]),
      );

      expect(find.text(english.progressStreakDaysLabel(6)), findsOneWidget);
      expect(find.text(english.progressStreakHeldLine), findsOneWidget);
      expect(find.text(english.progressTodayCardsLabel(0)), findsOneWidget);
    });

    testWidgets('a zero streak reads as an invitation, not a loss', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: seeded(totals: const <int>[4, 0, 0, 0, 0, 0, 0], streak: 0),
      );

      expect(find.text(english.progressStreakZeroLine), findsOneWidget);
      expect(find.text(english.progressStreakHeldLine), findsNothing);

      // The well's own claim (progress_streak_hero_widget.dart doc comment):
      // zero is neutral, not a dimmed copy of the active accent. Nothing
      // else in the suite reads MxMetricWell's colours, so a flipped or
      // hard-coded ternary here would pass every other test in the app.
      final zeroWell = tester.widget<MxMetricWell>(
        find.descendant(
          of: find.byType(ProgressStreakHeroWidget),
          matching: find.byType(MxMetricWell),
        ),
      );
      expect(zeroWell.fill, AppWellFill.muted);
      // `tint` is an `AppInk` since M100.5, so the assertion names the token
      // rather than a colour it happened to resolve to.
      expect(zeroWell.tint, AppInk.quiet);
    });

    testWidgets(
      'an active streak wears the streak vocabulary, not the zero pair',
      (tester) async {
        await pumpProgressScreen(
          tester,
          repository: seeded(
            totals: const <int>[4, 1, 0, 0, 0, 0, 0],
            streak: 3,
          ),
        );

        final activeWell = tester.widget<MxMetricWell>(
          find.descendant(
            of: find.byType(ProgressStreakHeroWidget),
            matching: find.byType(MxMetricWell),
          ),
        );
        expect(activeWell.fill, AppWellFill.streak);
        expect(activeWell.tint, AppInk.onDueContainer);
      },
    );
  });

  group('lifetime empty (S-d)', () {
    testWidgets('replaces the whole screen rather than showing three zeros', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: seeded(
          totals: const <int>[0, 0, 0, 0, 0, 0, 0],
          streak: 0,
          hasLifetimeActivity: false,
        ),
      );

      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(find.text(english.progressEmptyTitle), findsOneWidget);
      expect(find.byType(ProgressWeekWidget), findsNothing);
    });

    testWidgets('a quiet week with older history is NOT the empty face', (
      tester,
    ) async {
      // The distinction the window cannot make on its own: somebody who studied
      // for a month and then stopped has an empty chart and a full history, and
      // showing them a first-run invitation would be wrong about who they are.
      await pumpProgressScreen(
        tester,
        repository: seeded(
          totals: const <int>[0, 0, 0, 0, 0, 0, 0],
          streak: 0,
          hasLifetimeActivity: true,
        ),
      );

      expect(find.byType(MxEmptyState), findsNothing);
      expect(find.byType(ProgressWeekWidget), findsOneWidget);
    });

    testWidgets('its action really opens the Study branch', (tester) async {
      // Tapped for real through the production router. A callback assertion
      // would pass for a button that navigates nowhere, which is the exact
      // failure P7 is about.
      final router = await pumpProgressApp(
        tester,
        repository: seeded(
          totals: const <int>[0, 0, 0, 0, 0, 0, 0],
          streak: 0,
          hasLifetimeActivity: false,
        ),
      );

      await tester.tap(find.text(english.progressEmptyAction));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        RoutePaths.study,
      );
    });
  });

  group('the two state faces are inset once, not twice', () {
    // The screen used to hand `MxContentShell` no `padding`, so both faces took
    // the screen gutter *and* their own `EdgeInsets.all(AppSpacing.xl)` — 40dp
    // a side at 393, 36 at 320. The deck level below already passed
    // `EdgeInsets.zero`, so the same component rendered at two widths one retry
    // apart. These read the number rather than the intent: 16dp of silent inset
    // is exactly what a screenshot fails to report.
    const List<Size> surfaces = <Size>[Size(393, 852), Size(320, 640)];

    Rect copyColumnOf(WidgetTester tester, Type face) => tester.getRect(
      find
          .descendant(of: find.byType(face), matching: find.byType(Column))
          .first,
    );

    for (final Size surface in surfaces) {
      testWidgets('the empty face keeps its own xl at $surface', (
        tester,
      ) async {
        await pumpProgressScreen(
          tester,
          repository: seeded(
            totals: const <int>[0, 0, 0, 0, 0, 0, 0],
            streak: 0,
            hasLifetimeActivity: false,
          ),
          surface: surface,
        );

        // Full-bleed box: the face owns the whole content width, so the `xl` it
        // pads itself with is the only inset there is.
        final Rect empty = tester.getRect(find.byType(MxEmptyState));
        expect(empty.left, 0);
        expect(empty.right, surface.width);
        expect(copyColumnOf(tester, MxEmptyState).left, AppSpacing.xl);
      });

      testWidgets('the error face keeps its own xl at $surface', (
        tester,
      ) async {
        // Pumped from a repository that has emitted nothing: an error *after* a
        // value is a refresh failure, which keeps the last snapshot on screen.
        final repository = FakeProgressRepository();
        await pumpProgressScreen(
          tester,
          repository: repository,
          surface: surface,
        );
        repository.fail(const DatabaseFailure(message: 'read failed'));
        await tester.pump();

        final Rect error = tester.getRect(find.byType(MxErrorState));
        expect(error.left, 0);
        expect(error.right, surface.width);
      });
    }

    testWidgets('the error copy starts at its own xl on the narrow tier', (
      tester,
    ) async {
      // Asserted at 320 only: above it the error column is narrower than the
      // viewport and its own `Center` picks the left edge, so the number there
      // would measure centring rather than padding.
      final repository = FakeProgressRepository();
      await pumpProgressScreen(
        tester,
        repository: repository,
        surface: const Size(320, 640),
      );
      repository.fail(const DatabaseFailure(message: 'read failed'));
      await tester.pump();

      expect(copyColumnOf(tester, MxErrorState).left, AppSpacing.xl);
    });
  });
}
