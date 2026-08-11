import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';

import 'support/deck_fixtures.dart';
import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The metric-first summary: two numbers, then the learned line (BR-150).
///
/// **The sentence is gone on purpose.** "12 cards due in this deck today, and
/// 14 new to learn" wrapped at large scales and buried the two figures a
/// reader scans for. The panel now opens with `12 Due · 14 New` in the same
/// order and roles as every tile — and both numbers stay on screen at zero,
/// because absence-means-zero is the convention this panel exists to kill.
void main() {
  final english = AppLocalizationsEn();

  Finder inSummary(Finder matching) => find.descendant(
    of: find.byType(DeckLevelSummaryWidget),
    matching: matching,
  );

  Finder metric(int count, String word) =>
      inSummary(find.textContaining('$count $word', findRichText: true));

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
    expect(metric(12, english.deckDueMetricWord), findsOneWidget);
    expect(metric(14, english.deckNewMetricWord), findsOneWidget);
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
    expect(metric(0, english.deckDueMetricWord), findsOneWidget);
    expect(metric(20, english.deckNewMetricWord), findsOneWidget);

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

    expect(metric(0, english.deckDueMetricWord), findsOneWidget);
    expect(metric(0, english.deckNewMetricWord), findsOneWidget);
    // 100% learned: the shared bar carries the success moment on its own.
    final bar = tester.widget<MxProgressBar>(
      inSummary(find.byType(MxProgressBar)),
    );
    expect(bar.value, 1);
  });
}
