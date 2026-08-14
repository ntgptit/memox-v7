import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/progress/presentation/widgets/items/progress_week_bar_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_streak_hero_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_today_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_week_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';

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

  /// The seven weekday labels, in chart order.
  ///
  /// The chart's `Table` lays its cells out row by row and the bar cell holds no
  /// `Text`, so the section's texts are `[section label, day 0 label, day 0
  /// value, day 1 label, …]` — the labels are the odd indices from 1. The length
  /// is asserted rather than assumed: if the section grows an eighth text this
  /// picks the wrong widgets and would keep measuring something, which is the
  /// one way a geometry test fails without failing.
  List<Rect> dayLabelRects(WidgetTester tester) {
    final texts = find
        .descendant(
          of: find.byType(ProgressWeekWidget),
          matching: find.byType(Text),
        )
        .evaluate()
        .toList();
    expect(
      texts,
      hasLength(15),
      reason: '1 section label + 7 × (label, value)',
    );

    return <Rect>[
      for (int index = 1; index < texts.length; index += 2)
        tester.getRect(find.byWidget(texts[index].widget)),
    ];
  }

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
        // The floor the equalities below cannot express. Column 1 is a
        // `FlexColumnWidth` between two `IntrinsicColumnWidth`s, so if the label
        // and the value ever eat the card the bars shrink — all seven equally,
        // so every assertion here still holds while the chart has quietly
        // stopped being a chart. `RenderTable` reports no overflow for it and
        // `MxCard` clips, so nothing else would say a word.
        //
        // A quarter of the card's content, not `> 0`: a 0.5dp bar passes
        // "greater than zero" and communicates nothing, and the point of the
        // floor is that the bar still reads as a measure. This suite's fixture
        // has a busiest day of 143, which measures 81.1dp against a content
        // width of 264 at `320 @ 2.0 · vi`. That is not a guarantee for every
        // input: the floor stops holding somewhere past 999 cards in a day, and
        // X7 records where, with the measurement and an assertion of its own.
        final double content =
            rectOf(tester, ProgressWeekWidget).width - 2 * AppSpacing.lg;
        for (final rect in rects) {
          expect(rect.left, rects.first.left, reason: 'shared baseline');
          expect(rect.width, rects.first.width, reason: 'shared bar width');
          expect(
            rect.width,
            greaterThan(content / 4),
            reason: 'bar column squeezed below a quarter of the card',
          );
          // G10a. Read off the token rather than compared to 6: the point of
          // `ProgressWeekBarWidget.trackHeight` borrowing the enum is that the
          // two cannot drift, and an assertion against a literal would be the
          // third copy of the number.
          expect(
            rect.height,
            MxProgressBarSize.sm.trackHeight,
            reason: 'G10a · bar height comes from MxProgressBarSize.sm',
          );
        }
      });

      testWidgets('the gap between chart rows is one sm, at all six seams '
          '(G9)', (tester) async {
        await pump(tester);

        // **Measured on the label column, not on the bars.** The row gap is a
        // `bottom` padding on every cell, and `TableCellVerticalAlignment.middle`
        // centres each cell in a row whose height is set by the tallest one —
        // the label. So the bars are 6dp objects floating in a ~20dp row and the
        // distance between two of them is not `sm` and was never meant to be;
        // the distance between two rows is, and the label cell is where that is
        // visible. Asserting it on the bars would have pinned an accident.
        final labels = dayLabelRects(tester);
        for (int index = 1; index < labels.length; index++) {
          expect(
            labels[index].top - labels[index - 1].bottom,
            AppSpacing.sm,
            reason: 'seam $index carries exactly one sm',
          );
        }

        // Kept alongside: equal pitch is the property that survives a change of
        // text scale, and it is what a reader sees as "even".
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

    testWidgets('Today steps label → total by sm and its breakdown rows by xs '
        '(G7)', (tester) async {
      // The other two thirds of G7. The hero test above covers `label → content
      // = sm` once and `xs` once, and both of those are the hero's own
      // `SizedBox`es; the row that G7 actually names — "giữa các dòng phân rã"
      // — is the Learning/Reviewing pair in this section, and nothing measured
      // it. Two sections repeating one number is exactly the shape that drifts
      // when somebody edits one of them.
      await pumpProgressScreen(
        tester,
        repository: seeded(totals: const <int>[1, 1, 1, 1, 1, 1, 4]),
      );

      final label = tester.getRect(
        find.descendant(
          of: find.byType(ProgressTodayWidget),
          matching: find.text(english.progressTodaySectionLabel),
        ),
      );
      final total = tester.getRect(
        find.text(english.progressTodayCardsLabel(4)),
      );
      // The **rows**, not the labels inside them. A row is a `Row` of a wrapping
      // label and a `titleMedium` figure, so the taller of the two sets its
      // height and the label sits centred inside it — measuring label-to-label
      // reads 8 where the gap is 4, and half of that is the figure's line box.
      // `MergeSemantics` is the row's own widget and the only handle on it from
      // out here, the class being private.
      final rows = find
          .descendant(
            of: find.byType(ProgressTodayWidget),
            matching: find.byType(MergeSemantics),
          )
          .evaluate()
          .map((element) => tester.getRect(find.byWidget(element.widget)))
          .toList();
      expect(rows, hasLength(2));

      expect(total.top - label.bottom, AppSpacing.sm);
      expect(rows[1].top - rows[0].bottom, AppSpacing.xs);
    });

    testWidgets('the chart steps label → first row by sm (G7)', (tester) async {
      await pumpProgressScreen(tester, repository: seeded());

      final label = tester.getRect(find.text(english.progressWeekSectionLabel));
      final firstRow = dayLabelRects(tester).first;

      expect(firstRow.top - label.bottom, AppSpacing.sm);
    });
  });
}
