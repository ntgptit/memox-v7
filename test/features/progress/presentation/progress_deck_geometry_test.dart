import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/progress_path_segment_model.dart';
import 'package:memox/features/progress/presentation/screens/progress_deck_screen.dart';
import 'package:memox/features/progress/presentation/widgets/items/progress_deck_row_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_range_selector_widget.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import 'support/fake_progress_repository.dart';
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

  FakeProgressRepository level() => FakeProgressRepository.withSnapshot(
    activitySnapshot(
      decks: <DeckActivity>[
        deckActivity(
          deckId: 'busy',
          name: 'Spanish',
          path: const <ProgressPathSegment>[
            ProgressPathSegment(id: 'r', name: 'Library'),
          ],
          last7Days: activityMetrics(
            activeCards: 42,
            activeDays: 6,
            learning: 12,
            reviewing: 60,
          ),
        ),
        deckActivity(
          deckId: 'quiet',
          name: 'Japanese',
          last7Days: activityMetrics(activeCards: 3, activeDays: 1),
        ),
      ],
      scopeLast7Days: activityMetrics(
        activeCards: 45,
        activeDays: 6,
        learning: 12,
        reviewing: 60,
      ),
    ),
  );

  /// Enough decks that the list genuinely scrolls.
  FakeProgressRepository manyDecks() => FakeProgressRepository.withSnapshot(
    activitySnapshot(
      decks: <DeckActivity>[
        for (var i = 0; i < 20; i++)
          deckActivity(
            deckId: 'deck-$i',
            name: 'Deck $i',
            last7Days: activityMetrics(activeCards: 20 - i, activeDays: 3),
          ),
      ],
      scopeLast7Days: activityMetrics(activeCards: 210, activeDays: 7),
    ),
  );

  Finder metric(String label) => find.bySemanticsLabel(label);

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

      expect(second.top - first.bottom, AppSpacing.md);
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
  });

  group('a row is a target and a place', () {
    testWidgets('every row clears the touch-target floor', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: level(),
        screen: const ProgressDeckScreen(),
      );

      for (var i = 0; i < 2; i++) {
        expect(
          tester.getRect(find.byType(ProgressDeckRowWidget).at(i)).height,
          greaterThanOrEqualTo(AppSpacing.minimumTouchTarget),
        );
      }
    });

    testWidgets('the trailing affordance stays inside the row', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: level(),
        screen: const ProgressDeckScreen(),
      );

      final row = tester.getRect(find.byType(ProgressDeckRowWidget).first);
      final chevron = tester.getRect(
        find
            .descendant(
              of: find.byType(ProgressDeckRowWidget).first,
              matching: find.byIcon(Icons.chevron_right),
            )
            .first,
      );

      expect(chevron.right, lessThanOrEqualTo(row.right));
      expect(chevron.left, greaterThan(row.left));
    });

    testWidgets('a long path wraps instead of pushing the metrics out', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.withSnapshot(
          activitySnapshot(
            decks: <DeckActivity>[
              deckActivity(
                deckId: 'deep',
                name: 'Động từ bất quy tắc nhóm hai',
                path: const <ProgressPathSegment>[
                  ProgressPathSegment(id: 'a', name: 'Tiếng Nhật tổng hợp'),
                  ProgressPathSegment(
                    id: 'b',
                    name: 'Ngữ pháp trình độ trung cấp',
                  ),
                  ProgressPathSegment(id: 'c', name: 'Bài 12 — thể khả năng'),
                ],
                last7Days: activityMetrics(activeCards: 7, activeDays: 3),
              ),
            ],
            scopeLast7Days: activityMetrics(activeCards: 7, activeDays: 3),
          ),
        ),
        screen: const ProgressDeckScreen(),
        surface: const Size(320, 640),
      );

      final row = tester.getRect(find.byType(ProgressDeckRowWidget));
      final cards = tester.getRect(
        metric(english.progressActiveCardsSemanticLabel(7)).last,
      );

      expect(cards.left, greaterThanOrEqualTo(row.left));
      expect(cards.right, lessThanOrEqualTo(row.right));
      expect(tester.takeException(), isNull);
    });
  });

  group('the bottom of the list', () {
    testWidgets('the last row keeps its breathing space above the bar', (
      tester,
    ) async {
      // **Not "the row clears the bar"** - that assertion cannot fail.
      // `Scaffold` subtracts the navigation bar's height from the body's
      // `MediaQuery`, so no row can render behind it however the padding is
      // written. What is worth pinning is the inset itself: a list that ends
      // flush against the bar reads as cut off mid-way.
      //
      // It also has to be measured at the *end* of a scroll that really
      // happens - a fixture short enough to fit the viewport makes the drag a
      // no-op and the measurement meaningless.
      await pumpProgressApp(tester, repository: manyDecks());

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).last)
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();

      expect(position.maxScrollExtent, greaterThan(0));

      final lastRow = tester.getRect(find.byType(ProgressDeckRowWidget).last);
      final viewport = tester.getRect(find.byType(CustomScrollView));
      final bar = tester.getRect(find.byType(MxNavigationBar));

      expect(viewport.bottom - lastRow.bottom, AppSpacing.xxl);
      expect(lastRow.bottom, lessThanOrEqualTo(bar.top));
    });
  });
}
