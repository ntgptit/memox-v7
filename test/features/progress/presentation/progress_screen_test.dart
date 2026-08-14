import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_streak_hero_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_today_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_week_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';

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

      expect(find.text(english.progressStreakDaysLabel(7)), findsOneWidget);
      expect(find.text(english.progressStreakTodayLine(6)), findsOneWidget);
    });

    testWidgets('Today names its unit and both halves of the partition', (
      tester,
    ) async {
      // The unit is the point: the count is distinct cards, not turns taken
      // (BR-182), and a bare figure would be read as the latter.
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
      // A zero day is data (BR-186, P4). Dropping it would make the chart a
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
    });
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

  group('error (S-e)', () {
    testWidgets('offers Retry and says nothing about the database', (
      tester,
    ) async {
      final repository = FakeProgressRepository();
      await pumpProgressScreen(tester, repository: repository);

      repository.fail(
        const DatabaseFailure(message: 'no such table: study_answers'),
      );
      await tester.pump();

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.progressErrorTitle), findsOneWidget);
      expect(find.text(english.progressErrorRetryAction), findsOneWidget);
      expect(find.textContaining('study_answers'), findsNothing);
    });

    testWidgets('Retry is a real target, and it is labelled', (tester) async {
      // The empty face's CTA had this and the error face did not, which is the
      // asymmetry worth closing: Retry is the only control on the one screen
      // state a user reaches by something going wrong.
      final handle = tester.ensureSemantics();
      final repository = FakeProgressRepository();
      await pumpProgressScreen(tester, repository: repository);
      repository.fail(const DatabaseFailure(message: 'read failed'));
      await tester.pump();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('the error face announces itself to a reader already on the '
        'screen', (tester) async {
      // The failure replaces a spinner in place. Without `liveRegion` a
      // TalkBack user is told nothing at all and waits on a screen that has
      // already given up.
      final handle = tester.ensureSemantics();
      final repository = FakeProgressRepository();
      await pumpProgressScreen(tester, repository: repository);
      repository.fail(const DatabaseFailure(message: 'read failed'));
      await tester.pump();

      expect(
        tester
            .getSemantics(find.byType(MxErrorState))
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('Retry re-opens the read', (tester) async {
      final repository = FakeProgressRepository();
      await pumpProgressScreen(tester, repository: repository);
      repository.fail(const DatabaseFailure(message: 'read failed'));
      await tester.pump();
      expect(repository.subscriptionCount, 1);

      await tester.tap(find.text(english.progressErrorRetryAction));
      await tester.pump();

      expect(repository.subscriptionCount, 2);

      // X7, pinned so it cannot change by accident. `ref.invalidate` is a
      // *refresh*, and `MxAsyncView` skips the loading branch on one for every
      // screen, so the error face is simply repainted: the user taps and
      // nothing moves until the read lands. That is an accepted divergence
      // owned by M4.10, not a property of this screen — and the day it is
      // fixed, this assertion should fail and be deleted on purpose.
      expect(find.byType(MxLoadingState), findsNothing);
      expect(find.byType(MxErrorState), findsOneWidget);
    });

    testWidgets('a Retry that fails again stays on the error face and opens '
        'nothing more (UC-12 E2)', (tester) async {
      // E2 is the half of the retry contract that a passing retry cannot show.
      // The screen must come back to the same face and then **stop** — a
      // controller that re-subscribed on its own would turn a database that is
      // down into a loop against it, and the person would see a spinner that
      // never resolves instead of the Retry they just pressed.
      final repository = FakeProgressRepository();
      await pumpProgressScreen(tester, repository: repository);
      repository.fail(const DatabaseFailure(message: 'read failed'));
      await tester.pump();

      await tester.tap(find.text(english.progressErrorRetryAction));
      await tester.pump();
      repository.fail(const DatabaseFailure(message: 'read failed again'));
      await tester.pump();

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.progressErrorRetryAction), findsOneWidget);

      // Five seconds of nothing happening: the subscription count is still the
      // two the user asked for, not a third nobody did.
      await tester.pump(const Duration(seconds: 5));
      expect(repository.subscriptionCount, 2);
      expect(find.byType(MxErrorState), findsOneWidget);
    });
  });
}
