import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The status-first hero: scope, the two workloads, then the learned line
/// (BR-150).
///
/// **Two numbers, one focal point.** Due and New stay separate figures in a
/// fixed order — that is BR-150 and it does not move — but their weight does:
/// the workload that needs attention first speaks at the hero size and the
/// other supports. Both numbers stay on screen at zero, because
/// absence-means-zero is the convention this panel exists to kill.
void main() {
  final english = AppLocalizationsEn();

  Finder inSummary(Finder matching) => find.descendant(
    of: find.byType(DeckLevelSummaryWidget),
    matching: matching,
  );

  Finder metric(int count, String word) =>
      inSummary(find.textContaining('$count $word', findRichText: true));

  /// The numeral's resolved size — the hierarchy under test, read from the
  /// style role rather than pinned to a pixel.
  double numeralSize(WidgetTester tester, int count, String word) {
    // `findRichText` resolves to the underlying RichText; the numeral is the
    // span whose text is the bare figure, found by walking rather than by
    // index so a wrapping default-style span cannot break the read.
    final rich = tester.widget<RichText>(metric(count, word));
    double? size;
    rich.text.visitChildren((InlineSpan span) {
      if (span is TextSpan && span.text == '$count ') {
        size = span.style?.fontSize;

        return false;
      }

      return true;
    });

    return size!;
  }

  testWidgets('mixed: both metrics lead, learned line follows', (tester) async {
    await pumpDeckScreen(
      tester,
      repository: FakeDeckRepository.withSummaries(<DeckSummary>[
        fakeSummary(
          id: 'd1',
          name: 'Working',
          totalCardCount: 180,
          newCardCount: 14,
          dueCardCount: 12,
          learnedCardCount: 82,
        ),
      ]),
      screen: const DeckListScreen(),
    );

    expect(find.byType(DeckLevelSummaryWidget), findsOneWidget);
    // No backlog: the twelve reviews are today's, and the overdue metric
    // states its zero (BR-162).
    expect(metric(0, english.deckHeroOverdueMetricWord), findsOneWidget);
    expect(metric(12, english.deckHeroDueTodayMetricWord), findsOneWidget);
    expect(metric(14, english.deckHeroNewMetricWord), findsOneWidget);
    // With no overdue backlog, Due today is the focal point: its numeral
    // speaks one typography role above New's. The order never changes — only
    // the emphasis does.
    expect(
      numeralSize(tester, 12, english.deckHeroDueTodayMetricWord),
      greaterThan(numeralSize(tester, 14, english.deckHeroNewMetricWord)),
    );
    // The learned line and its figure ride the shared progress component,
    // announced as one semantics node.
    expect(
      inSummary(
        find.bySemanticsLabel(english.deckLearnedProgressLabel(82, 180)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('new-only: the zero stays on the due side, no completion claim', (
    tester,
  ) async {
    await pumpDeckScreen(
      tester,
      repository: FakeDeckRepository.withSummaries(<DeckSummary>[
        fakeSummary(
          id: 'd1',
          name: 'Fresh',
          totalCardCount: 20,
          newCardCount: 20,
        ),
      ]),
      screen: const DeckListScreen(),
    );

    // The panel opened by itself: new cards are work, so `auto` shows it.
    expect(find.byType(DeckLevelSummaryWidget), findsOneWidget);
    expect(metric(0, english.deckHeroDueTodayMetricWord), findsOneWidget);
    expect(metric(20, english.deckHeroNewMetricWord), findsOneWidget);
    // With nothing due, New is the focal point and the zeroes rest at the
    // supporting size — still on screen, just not the headline.
    expect(
      numeralSize(tester, 20, english.deckHeroNewMetricWord),
      greaterThan(numeralSize(tester, 0, english.deckHeroDueTodayMetricWord)),
    );

    final bar = tester.widget<MxProgressBar>(
      inSummary(find.byType(MxProgressBar)),
    );
    expect(bar.value, 0);
  });

  testWidgets('both sets empty: two zeroes, stated, not a sentence', (
    tester,
  ) async {
    await pumpDeckScreen(
      tester,
      repository: FakeDeckRepository.withSummaries(<DeckSummary>[
        fakeSummary(
          id: 'd1',
          name: 'Done',
          totalCardCount: 8,
          learnedCardCount: 8,
        ),
      ]),
      screen: const DeckListScreen(),
    );

    // Nothing new and nothing due: `auto` keeps the panel away, and the
    // one-line link stands in for it.
    expect(find.byType(DeckLevelSummaryWidget), findsNothing);
    expect(find.text(english.deckSummaryShowAction), findsOneWidget);

    await tester.tap(find.text(english.deckSummaryShowAction));
    await tester.pumpAndSettle();

    expect(metric(0, english.deckHeroOverdueMetricWord), findsOneWidget);
    expect(metric(0, english.deckHeroDueTodayMetricWord), findsOneWidget);
    expect(metric(0, english.deckHeroNewMetricWord), findsOneWidget);
    // The eight learned cards rest until their next review — the fourth set
    // is the only non-zero figure, and it still takes no headline: a resting
    // card asks for nothing.
    expect(metric(8, english.deckHeroScheduledMetricWord), findsOneWidget);
    // Caught up: nothing is shouted. Every figure rests at the same
    // supporting size — a hero with no workload has no headline to give.
    expect(
      numeralSize(tester, 0, english.deckHeroDueTodayMetricWord),
      numeralSize(tester, 0, english.deckHeroNewMetricWord),
    );
    expect(
      numeralSize(tester, 0, english.deckHeroOverdueMetricWord),
      numeralSize(tester, 0, english.deckHeroDueTodayMetricWord),
    );
    expect(
      numeralSize(tester, 8, english.deckHeroScheduledMetricWord),
      numeralSize(tester, 0, english.deckHeroDueTodayMetricWord),
    );
    // 100% learned: the shared bar carries the success moment on its own.
    final bar = tester.widget<MxProgressBar>(
      inSummary(find.byType(MxProgressBar)),
    );
    expect(bar.value, 1);
  });
}
