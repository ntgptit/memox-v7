import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_streak_hero_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_today_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_week_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';

/// What happens to the Progress screen **after** it has rendered (UC-12 A3, A4),
/// plus the semantics tree and the locale/theme matrix.
///
/// Split from `progress_screen_test.dart`, which keeps the five static faces.
/// The seam is time: every test here pumps a state and then makes something
/// happen to it — an answer lands, midnight passes, a reader walks the tree —
/// while that file pumps a state and reads it. The split was forced by the
/// guard's 400-line ceiling and is the right shape anyway.
void main() {
  final english = AppLocalizationsEn();
  final vietnamese = AppLocalizationsVi();

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

  group('live refresh (S-f)', () {
    testWidgets('updates the numbers in place without falling back to the '
        'spinner', (tester) async {
      // `MxAsyncView` sets `skipLoadingOnRefresh`, and P8 makes that a rule
      // rather than an inherited default: a screen that flashed a spinner every
      // time an answer landed would be motion in place of information.
      final repository = seeded(totals: const <int>[1, 1, 1, 1, 1, 1, 3]);
      await pumpProgressScreen(tester, repository: repository);
      expect(find.text(english.progressTodayCardsLabel(3)), findsOneWidget);

      repository.emit(
        progressOverviewFixture(
          totals: const <int>[1, 1, 1, 1, 1, 1, 4],
          streakDays: 7,
          today: DateTime.utc(2026, 8, 12),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(MxLoadingState), findsNothing);
      expect(find.text(english.progressTodayCardsLabel(4)), findsOneWidget);
    });
  });

  group('midnight rollover (S-g)', () {
    testWidgets('crossing local midnight re-reads without flashing the '
        'spinner', (tester) async {
      // **Asserted at the screen, not only at the controller.** A rollover is a
      // *dependency* change — `progressNowProvider` moves — and `MxAsyncView`
      // sets `skipLoadingOnReload: false`, so this is the one path where the
      // screen could legitimately drop back to a spinner over data it already
      // has. P8 forbids that, and only a widget-level test can see it: the
      // controller test measures re-subscription, which happens either way.
      DateTime now = DateTime.utc(2026, 8, 12, 23, 59);
      final repository = FakeProgressRepository(
        initial: progressOverviewFixture(
          totals: const <int>[1, 1, 1, 1, 1, 1, 5],
          streakDays: 7,
          today: DateTime.utc(2026, 8, 12),
        ).copyWith(nextLocalMidnight: DateTime.utc(2026, 8, 13)),
      );
      await pumpProgressScreen(
        tester,
        repository: repository,
        clock: () => now,
      );
      expect(find.text(english.progressTodayCardsLabel(5)), findsOneWidget);

      // The day turns. The repository answers the re-opened read with the new
      // window, exactly as SQLite would.
      now = DateTime.utc(2026, 8, 13, 0, 0, 1);
      repository.emit(
        progressOverviewFixture(
          totals: const <int>[1, 1, 1, 1, 1, 5, 0],
          streakDays: 7,
          today: DateTime.utc(2026, 8, 13),
        ).copyWith(nextLocalMidnight: DateTime.utc(2026, 8, 14)),
      );
      // Checked frame by frame, not only at rest. A spinner that appears for
      // one frame and is gone by the time the test settles is still a flash the
      // user sees, and asserting only the final state would miss exactly that.
      await tester.pump(const Duration(minutes: 2));
      expect(
        find.byType(MxLoadingState),
        findsNothing,
        reason: 'rebuild frame',
      );
      await tester.pump();
      expect(find.byType(MxLoadingState), findsNothing, reason: 'next frame');
      await tester.pump();

      expect(find.byType(MxLoadingState), findsNothing);
      expect(find.text(english.progressTodayCardsLabel(0)), findsOneWidget);
      expect(find.text(english.progressStreakHeldLine), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('the hero is one node, streak and today together', (
      tester,
    ) async {
      // Three fragments — "7", "days", "6 cards today" — is what a reader hears
      // without this, and a figure that arrives apart from its unit has lost
      // what it measures.
      final handle = tester.ensureSemantics();
      await pumpProgressScreen(
        tester,
        repository: seeded(totals: const <int>[1, 1, 1, 1, 1, 1, 6], streak: 7),
      );

      expect(
        find.bySemanticsLabel(english.progressStreakSemantics(7, 6)),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('each chart row is one node naming its day and count', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpProgressScreen(
        tester,
        repository: seeded(totals: const <int>[3, 0, 0, 2, 7, 4, 6]),
      );

      expect(
        find.bySemanticsLabel(
          english.progressWeekDaySemantics(english.progressWeekTodayLabel, 6),
        ),
        findsOneWidget,
      );
      // A zero day still announces itself; colour and bar length are decoration
      // and are excluded, so this sentence is the whole row for a reader.
      expect(
        find.bySemanticsLabel(
          english.progressWeekDaySemantics(
            english.progressWeekdayShortLabel('5'),
            0,
          ),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('meets the tap-target guideline on the empty face', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpProgressScreen(
        tester,
        repository: seeded(
          totals: const <int>[0, 0, 0, 0, 0, 0, 0],
          streak: 0,
          hasLifetimeActivity: false,
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('locales and themes', () {
    testWidgets('Vietnamese renders every section without overflow', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: seeded(),
        locale: const Locale('vi'),
      );

      expect(find.text(vietnamese.progressStreakSectionLabel), findsOneWidget);
      // Scoped to the section, because Vietnamese spells the Today heading and
      // the chart's last row label the same — "Hôm nay" — and an unscoped
      // finder would report two and read as a duplicate-render bug.
      expect(
        find.descendant(
          of: find.byType(ProgressTodayWidget),
          matching: find.text(vietnamese.progressTodaySectionLabel),
        ),
        findsOneWidget,
      );
      expect(find.text(vietnamese.progressWeekSectionLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark renders the same three sections', (tester) async {
      await pumpProgressScreen(tester, repository: seeded(), isDark: true);

      expect(find.byType(ProgressStreakHeroWidget), findsOneWidget);
      expect(find.byType(ProgressTodayWidget), findsOneWidget);
      expect(find.byType(ProgressWeekWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
