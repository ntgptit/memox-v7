import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/progress/presentation/widgets/items/progress_week_bar_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_streak_hero_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_today_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_week_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';

/// The measured half of the Progress wireframe (W5, G1–G12).
///
/// **These assertions exist because the defects they catch are invisible in a
/// screenshot taken at one size.** A section that sizes itself to its own text
/// looks fine on the viewport it was designed on and shifts by four pixels on
/// the next one; a chart whose rows each measure their own label puts the bars
/// on seven different lines only once a label gets longer. Both are read as
/// "something feels off" rather than reported, so they have to be numbers.
void main() {
  final english = AppLocalizationsEn();

  /// A week with a zero day, a busiest day and a three-digit day: the three
  /// shapes that stress the label column, the value column and the bar scale.
  FakeProgressRepository seeded({List<int>? totals, int streakDays = 5}) =>
      FakeProgressRepository(
        initial: progressOverviewFixture(
          totals: totals ?? const <int>[12, 0, 6, 143, 3, 9, 8],
          streakDays: streakDays,
          today: DateTime.utc(2026, 8, 12),
        ),
      );

  /// Every viewport the wireframe requires, and **both locales at the tightest
  /// one** (W6.1).
  ///
  /// Vietnamese is not a formality here: it carries the longest strings on the
  /// screen — the partition note is 106 characters against 79 in English — so
  /// 320dp at a 2.0 text scale in Vietnamese is the single cell most likely to
  /// wrap differently, and it was the one cell the first version of this file
  /// never rendered.
  const List<({String label, Size size, double scale, Locale? locale})>
  viewports = <({String label, Size size, double scale, Locale? locale})>[
    (label: '320 @ 2.0 · en', size: Size(320, 720), scale: 2, locale: null),
    (
      label: '320 @ 2.0 · vi',
      size: Size(320, 720),
      scale: 2,
      locale: Locale('vi'),
    ),
    (label: '390 · en', size: Size(390, 844), scale: 1, locale: null),
    (label: '390 · vi', size: Size(390, 844), scale: 1, locale: Locale('vi')),
    (label: '412 · en', size: Size(412, 915), scale: 1, locale: null),
  ];

  Rect rectOf(WidgetTester tester, Type type) =>
      tester.getRect(find.byType(type));

  List<Rect> barRects(WidgetTester tester) => find
      .byType(ProgressWeekBarWidget)
      .evaluate()
      .map((element) => tester.getRect(find.byWidget(element.widget)))
      .toList();

  for (final viewport in viewports) {
    group('at ${viewport.label}', () {
      Future<void> pump(WidgetTester tester, {bool isDark = false}) =>
          pumpProgressScreen(
            tester,
            repository: seeded(),
            surface: viewport.size,
            textScale: viewport.scale,
            isDark: isDark,
            locale: viewport.locale,
          );

      testWidgets('the three sections share both edges and one width '
          '(G2, G3, G4)', (tester) async {
        // The failure mode is a section wrapped in something that sizes to its
        // content — an `IntrinsicWidth`, a `Wrap`, a `Row` without `Expanded`.
        // The hero has the shortest text of the three, so it is the one that
        // would visibly narrow.
        await pump(tester);

        final hero = rectOf(tester, ProgressStreakHeroWidget);
        final today = rectOf(tester, ProgressTodayWidget);
        final week = rectOf(tester, ProgressWeekWidget);

        expect(today.left, hero.left);
        expect(week.left, hero.left);
        expect(today.right, hero.right);
        expect(week.right, hero.right);
        expect(today.width, hero.width);
        expect(week.width, hero.width);
      });

      testWidgets('the gutter is the shared screen gutter (G1)', (
        tester,
      ) async {
        await pump(tester);

        final hero = rectOf(tester, ProgressStreakHeroWidget);
        // 320 is below `AppBreakpoints.compact`, where the gutter steps down —
        // the same two numbers every other screen uses, resolved by
        // `mxScreenGutter` rather than re-derived here.
        final double gutter = viewport.size.width < 360
            ? AppSpacing.md
            : AppSpacing.lg;

        expect(hero.left, gutter);
        expect(hero.right, viewport.size.width - gutter);
      });

      testWidgets('the vertical rhythm between sections is xl (G6)', (
        tester,
      ) async {
        await pump(tester);

        final hero = rectOf(tester, ProgressStreakHeroWidget);
        final today = rectOf(tester, ProgressTodayWidget);
        final week = rectOf(tester, ProgressWeekWidget);

        expect(today.top - hero.bottom, AppSpacing.xl);
        expect(week.top - today.bottom, AppSpacing.xl);
      });

      testWidgets('the content sits inside the chrome and the safe area '
          '(G11)', (tester) async {
        await pump(tester);

        final appBar = tester.getRect(find.byType(AppBar));
        final hero = rectOf(tester, ProgressStreakHeroWidget);

        expect(hero.top, greaterThanOrEqualTo(appBar.bottom));
        expect(hero.left, greaterThanOrEqualTo(0));
        expect(hero.right, lessThanOrEqualTo(viewport.size.width));
      });

      testWidgets('every bar shares one baseline and one width (G8, G10)', (
        tester,
      ) async {
        // The `Table`'s whole reason for being. With a `Row` per day, the label
        // column would be as wide as that row's own label, so "Today" and "Fri"
        // would start their bars at different x, and the gap grows with the
        // text scale — which is why this is checked at 2.0 and in the locale
        // with the longer words.
        await pump(tester);

        final rects = barRects(tester);
        expect(rects, hasLength(7));
        for (final rect in rects) {
          expect(rect.left, rects.first.left, reason: 'shared baseline');
          expect(rect.width, rects.first.width, reason: 'shared bar width');
        }
      });

      testWidgets('the gap between chart rows is even, at all six seams (G9)', (
        tester,
      ) async {
        await pump(tester);

        final rects = barRects(tester);
        for (int index = 1; index < rects.length; index++) {
          expect(
            rects[index].center.dy - rects[index - 1].center.dy,
            rects[1].center.dy - rects[0].center.dy,
            reason: 'row $index sits on the same pitch as the first pair',
          );
        }
      });

      testWidgets('nothing overflows, in either theme', (tester) async {
        // W6 forbids buying space back by clipping or shrinking type, so an
        // overflow here is a design defect and not a cosmetic one. Both themes,
        // because dark reflows nothing but does swap every colour — and a
        // regression that replaced a token with a sized decoration would show
        // up here first.
        await pump(tester);
        expect(tester.takeException(), isNull);

        await pump(tester, isDark: true);
        expect(tester.takeException(), isNull);
      });
    });
  }

  group('inside a section', () {
    /// The card's own padding and the rhythm between its lines (G5, G7).
    ///
    /// English only, and deliberately: these two measure `MxCard`'s padding and
    /// the `SizedBox` gaps between lines, neither of which depends on the words
    /// in them. The locale axis belongs to the wrap and overflow cases above.
    testWidgets('the card pads its content by lg on every side (G5)', (
      tester,
    ) async {
      await pumpProgressScreen(tester, repository: seeded());

      final card = rectOf(tester, ProgressTodayWidget);
      final label = tester.getRect(
        find.descendant(
          of: find.byType(ProgressTodayWidget),
          matching: find.text(english.progressTodaySectionLabel),
        ),
      );
      final note = tester.getRect(
        find.descendant(
          of: find.byType(ProgressTodayWidget),
          matching: find.text(english.progressTodayPartitionNote),
        ),
      );

      expect(label.left - card.left, AppSpacing.lg);
      expect(label.top - card.top, AppSpacing.lg);
      expect(card.bottom - note.bottom, AppSpacing.lg);
    });

    testWidgets('the hero steps label → headline → support by sm then xs '
        '(G7)', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: seeded(totals: const <int>[1, 1, 1, 1, 1, 1, 4]),
      );

      final label = tester.getRect(
        find.text(english.progressStreakSectionLabel),
      );
      final headline = tester.getRect(
        find.text(english.progressStreakDaysLabel(5)),
      );
      final support = tester.getRect(
        find.text(english.progressStreakTodayLine(4)),
      );

      expect(headline.top - label.bottom, AppSpacing.sm);
      expect(support.top - headline.bottom, AppSpacing.xs);
    });
  });

  group('the extremes the copy has to survive', () {
    testWidgets('a three-digit streak wraps without moving the shared edges', (
      tester,
    ) async {
      // The hero's headline is `displayLarge`; at 320dp with a 2.0 text scale
      // "999 days" cannot fit on one line, and W6 forbids buying the line back
      // by shrinking the type. What must hold is that it *wraps* — the card
      // grows taller and its left and right edges do not move.
      await pumpProgressScreen(
        tester,
        repository: seeded(streakDays: 999),
        surface: const Size(320, 720),
        textScale: 2,
      );

      final hero = rectOf(tester, ProgressStreakHeroWidget);
      final today = rectOf(tester, ProgressTodayWidget);
      final week = rectOf(tester, ProgressWeekWidget);

      expect(hero.left, AppSpacing.md);
      expect(today.left, hero.left);
      expect(week.left, hero.left);
      expect(today.right, hero.right);
      expect(week.right, hero.right);
      expect(find.text(english.progressStreakDaysLabel(999)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a three-digit streak survives Vietnamese at 320 @ 2.0', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: seeded(streakDays: 999),
        surface: const Size(320, 720),
        textScale: 2,
        locale: const Locale('vi'),
      );

      final hero = rectOf(tester, ProgressStreakHeroWidget);
      final week = rectOf(tester, ProgressWeekWidget);

      expect(week.left, hero.left);
      expect(week.right, hero.right);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the busiest day fills the track and a zero day fills none', (
    tester,
  ) async {
    await pumpProgressScreen(
      tester,
      repository: seeded(totals: const <int>[0, 1, 2, 3, 4, 5, 10]),
    );

    final bars = tester
        .widgetList<ProgressWeekBarWidget>(find.byType(ProgressWeekBarWidget))
        .toList();

    expect(bars.first.fraction, 0);
    expect(bars.last.fraction, 1);
  });

  testWidgets('a week with no activity divides by nothing', (tester) async {
    // The busiest day is zero here — a real state for somebody with older
    // history and a quiet fortnight. Every bar is empty and none of them is
    // `NaN`, which is what an unguarded `total / busiest` would produce and
    // what would then throw inside the layout rather than in the arithmetic.
    await pumpProgressScreen(
      tester,
      repository: FakeProgressRepository(
        initial: progressOverviewFixture(
          totals: const <int>[0, 0, 0, 0, 0, 0, 0],
          streakDays: 0,
          today: DateTime.utc(2026, 8, 12),
          hasLifetimeActivity: true,
        ),
      ),
    );

    final bars = tester
        .widgetList<ProgressWeekBarWidget>(find.byType(ProgressWeekBarWidget))
        .toList();

    expect(bars, hasLength(7));
    expect(bars.every((bar) => bar.fraction == 0), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the last section clears the bottom navigation bar (G12)', (
    tester,
  ) async {
    // Mounted through the real shell, because the claim is about the shell: a
    // `Scaffold` with a `bottomNavigationBar` removes the bar's height from its
    // body's `MediaQuery`, so no manual inset is needed — and adding one would
    // reserve the space twice.
    await pumpProgressApp(tester, repository: seeded());
    await tester.dragUntilVisible(
      find.byType(ProgressWeekWidget),
      find.byType(SingleChildScrollView),
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();

    final week = tester.getRect(find.byType(ProgressWeekWidget));
    final bar = tester.getRect(find.byType(NavigationBar));

    expect(week.bottom, lessThanOrEqualTo(bar.top));
  });
}
