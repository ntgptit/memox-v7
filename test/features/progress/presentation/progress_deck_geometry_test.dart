import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/presentation/screens/progress_deck_screen.dart';
import 'package:memox/features/progress/presentation/widgets/items/progress_deck_row_widget.dart';
import 'package:memox/features/progress/presentation/widgets/items/progress_metric_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_range_selector_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_level_fixtures.dart';
import 'support/progress_screen_harness.dart';

/// The geometry the wireframe pins, measured after layout.
///
/// **These defects cannot be caught any other way.** Every number involved is a
/// legitimate token — the screen's gutter, the sliver's gutter, the card's own
/// padding — so a literal-hunting guard sees nothing. What goes wrong lives in
/// the *sum* and in the *agreement between two files*: two surfaces that should
/// share an edge, drawn by two widgets that each padded correctly. Only
/// `getRect` after layout can see either.
void main() {
  final english = AppLocalizationsEn();

  group('the screen gutter is one gutter', () {
    testWidgets('selector, summary and rows share both edges', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: level(),
        screen: const ProgressDeckScreen(),
      );

      final selector = tester.getRect(find.byType(ProgressRangeSelectorWidget));
      final summary = tester.getRect(find.byType(ProgressSummaryWidget));
      final row = tester.getRect(find.byType(ProgressDeckRowWidget).first);

      // Two files own these gutters — the screen's own padding and the sliver's
      // — and a mismatch of even 4px reads as the list being inset from the
      // panel above it.
      expect(summary.left, AppSpacing.lg);
      expect(row.left, summary.left);
      expect(selector.left, summary.left);
      expect(row.right, summary.right);
    });

    testWidgets('the range strip steps to the panel by lg, at both widths', (
      tester,
    ) async {
      // **This number has already moved twice with nothing watching it.** The
      // strip and the panel had 16 between them; moving the strip into the
      // scroll view dropped it to 4, which read as the pills sitting on the
      // card, and the fix put it back. §2 says every number here is measured,
      // and this one was only ever prose.
      //
      // 16 at both widths: it is `MxSubheaderBand`'s `xs` below plus the
      // panel's `md` above, and only the band's *top* follows the compact tier.
      for (final double width in <double>[390, 320]) {
        await pumpProgressScreen(
          tester,
          repository: level(),
          screen: const ProgressDeckScreen(),
          surface: Size(width, 852),
        );

        final Rect strip = tester.getRect(
          find.byType(ProgressRangeSelectorWidget),
        );
        final Rect panel = tester.getRect(find.byType(ProgressSummaryWidget));

        expect(
          panel.top - strip.bottom,
          AppSpacing.lg,
          reason: 'at ${width.toInt()}dp',
        );
      }
    });

    testWidgets('the gutter narrows with the screen, like every other screen', (
      tester,
    ) async {
      // `mxScreenGutter` is 12 below the compact breakpoint, not 16. Writing
      // `AppSpacing.lg` here instead would inset this screen 4px further than
      // Library and Study at 320dp - and cost the metric cells the 8px of width
      // they are shortest of.
      await pumpProgressScreen(
        tester,
        repository: level(),
        screen: const ProgressDeckScreen(),
        surface: const Size(320, 640),
      );

      final summary = tester.getRect(find.byType(ProgressSummaryWidget));
      final row = tester.getRect(find.byType(ProgressDeckRowWidget).first);

      expect(summary.left, AppSpacing.md);
      expect(row.left, summary.left);
      expect(row.right, summary.right);
    });

    testWidgets('the range selector does not scroll away', (tester) async {
      // BR-187 puts fifty decks on this list. Two screens down, a selector that
      // had scrolled off would leave nothing on screen saying whether the
      // figures are the week or the month.
      await pumpProgressScreen(
        tester,
        repository: manyDecks(),
        screen: const ProgressDeckScreen(),
      );

      final before = tester.getRect(find.byType(ProgressRangeSelectorWidget));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
      await tester.pumpAndSettle();

      expect(find.byType(ProgressRangeSelectorWidget), findsOneWidget);
      expect(tester.getRect(find.byType(ProgressRangeSelectorWidget)), before);
    });

    testWidgets('the panel and the list are separated by a section gap', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: level(),
        screen: const ProgressDeckScreen(),
      );

      final summary = tester.getRect(find.byType(ProgressSummaryWidget));
      final firstRow = tester.getRect(find.byType(ProgressDeckRowWidget).first);

      // `xl`, not `lg`: this is a break between two sections — the total and
      // the decks that make it up — and a gap the size of the one between two
      // rows would make the panel read as the first row of the list.
      expect(firstRow.top - summary.bottom, AppSpacing.xl);
    });

    testWidgets('rows are separated by the list gap, not the section gap', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: level(),
        screen: const ProgressDeckScreen(),
      );

      final rows = tester
          .widgetList<ProgressDeckRowWidget>(find.byType(ProgressDeckRowWidget))
          .toList();
      expect(rows, hasLength(2));

      final first = tester.getRect(find.byType(ProgressDeckRowWidget).at(0));
      final second = tester.getRect(find.byType(ProgressDeckRowWidget).at(1));

      // `lg`, not `md`: `app_spacing.dart` defines `lg` as the gap between
      // list items and `md` as the step *inside a compact control*, and the
      // deck list separates its own rows by `lg`. The wireframe's §2 row was
      // written against the old value and moved with this one (SC-C2-20).
      expect(second.top - first.bottom, AppSpacing.lg);
    });

    testWidgets('the inset below the last row is lg, not a bottom-bar '
        'clearance', (tester) async {
      // `getRect` cannot pin this one: `Scaffold` already subtracts the
      // navigation bar's height from the body's `MediaQuery`, so no row can
      // hide behind it and a rect-based "is the last row visible" assertion
      // would never go red regardless of what this inset is. What the
      // wireframe (§2) actually pins is the inset value itself, which lives
      // on `SliverPadding.padding.bottom` — the one `SliverPadding` in this
      // screen's tree.
      await pumpProgressScreen(
        tester,
        repository: level(),
        screen: const ProgressDeckScreen(),
      );

      final sliverPadding = tester.widget<SliverPadding>(
        find.byType(SliverPadding),
      );

      expect((sliverPadding.padding as EdgeInsets).bottom, AppSpacing.lg);
    });
  });

  group('a number is never truncated into a different number', () {
    testWidgets('a five-figure count still fits its cell at 320dp and text '
        'scale 2.0', (tester) async {
      // A run of digits has no break opportunity, so a numeral wider than its
      // cell does not wrap - it clips, silently, and `1234` renders as `123`.
      // `getRect` cannot see it: `RenderParagraph` clamps its own size to the
      // constraint it was given. The minimum intrinsic width is the width of
      // the widest unbreakable token, which is exactly what has to fit.
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.withSnapshot(
          activitySnapshot(
            decks: <DeckActivity>[
              deckActivity(
                deckId: 'big',
                name: 'Everything',
                last7Days: activityMetrics(
                  activeCards: 24680,
                  activeDays: 30,
                  learning: 13579,
                  reviewing: 98765,
                ),
              ),
            ],
            scopeLast7Days: activityMetrics(
              activeCards: 24680,
              activeDays: 30,
              learning: 13579,
              reviewing: 98765,
            ),
          ),
        ),
        screen: const ProgressDeckScreen(),
        surface: const Size(320, 640),
        textScale: 2,
      );

      for (final RenderParagraph paragraph
          in tester.renderObjectList<RenderParagraph>(find.byType(RichText))) {
        expect(
          paragraph.getMinIntrinsicWidth(double.infinity),
          lessThanOrEqualTo(paragraph.size.width),
          reason: 'a numeral wider than its cell is clipped, not wrapped',
        );
      }
    });
  });

  group('the metric grid is a grid', () {
    testWidgets('both columns keep their left edge down both rows', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: level(),
        screen: const ProgressDeckScreen(),
      );

      // Inside the busiest row: cards above learning, days above reviewing.
      final cards = tester.getRect(
        metric(english.progressActiveCardsSemanticLabel(42)),
      );
      final days = tester.getRect(
        metric(english.progressActiveDaysSemanticLabel(6)).last,
      );
      final learning = tester.getRect(
        metric(english.progressLearningSemanticLabel(12)).last,
      );
      final reviewing = tester.getRect(
        metric(english.progressReviewingSemanticLabel(60)).last,
      );

      // A `Wrap` or intrinsic sizing lets the second column drift with the
      // first column's word length; `Expanded` halves do not.
      expect(learning.left, cards.left);
      expect(reviewing.left, days.left);
      expect(days.left, greaterThan(cards.left));
    });

    testWidgets('the second row sits below the first, not beside it', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: level(),
        screen: const ProgressDeckScreen(),
      );

      final cards = tester.getRect(
        metric(english.progressActiveCardsSemanticLabel(42)),
      );
      final learning = tester.getRect(
        metric(english.progressLearningSemanticLabel(12)).last,
      );

      expect(learning.top, greaterThanOrEqualTo(cards.bottom));
    });

    testWidgets('the totals panel steps its label → grid by sm, like the '
        'three overview cards (G7)', (tester) async {
      // The fourth card of a family of four. The hero, Today and the week
      // chart are pinned at `sm` in `progress_screen_geometry_test.dart`
      // (:311/:353/:363); this panel was the one still at `md`, and `md` is
      // the *deck row's* step — a name + path title block, two blocks in one
      // card — not a section label's. Nothing measured this panel, which is
      // why the four could disagree on one screen (SC-C2-06).
      await pumpProgressScreen(
        tester,
        repository: level(),
        screen: const ProgressDeckScreen(),
      );

      final Rect label = tester.getRect(
        find.descendant(
          of: find.byType(ProgressSummaryWidget),
          matching: find.text(english.progressSummaryLast7DaysTitle),
        ),
      );
      final Rect grid = tester.getRect(
        find.descendant(
          of: find.byType(ProgressSummaryWidget),
          matching: find.byType(ProgressMetricGridWidget),
        ),
      );

      expect(grid.top - label.bottom, AppSpacing.sm);
    });
  });
}
