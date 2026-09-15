import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The hero with new cards in play (BR-150, owner mockup 2026-08-20): one
/// numeral leads — what is due, or the new cards when nothing is.
///
/// **New and Scheduled used to sit beneath it in a quiet context row, and
/// since 2026-09-10 they do not sit anywhere.** They spent one release inline
/// and one behind a chevron; neither placement earned them, because `new` is a
/// chip on every deck row below and `scheduled` counts the cards this screen is
/// specifically not about. What these tests assert now is that the numeral is
/// the same fold over the same snapshot, and that the context row did not come
/// back.
void main() {
  final english = AppLocalizationsEn();

  Finder inSummary(Finder matching) => find.descendant(
    of: find.byType(DeckLevelSummaryWidget),
    matching: matching,
  );

  /// The hero numeral's resolved size — the hierarchy under test, read from
  /// the rendered style role rather than pinned to a pixel.
  double sizeOfText(WidgetTester tester, String text) =>
      tester.widget<Text>(inSummary(find.text(text)).first).style!.fontSize!;

  testWidgets('mixed: the due numeral leads, context rests below', (
    tester,
  ) async {
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
    expect(inSummary(find.text('12')), findsWidgets);
    expect(
      inSummary(find.text(english.deckSummaryCardsDueWord)),
      findsOneWidget,
    );
    // No backlog: no breakdown subline (its zero would repeat the numeral).
    expect(
      inSummary(
        find.textContaining(
          english.deckSummaryOverduePart(0),
          findRichText: true,
        ),
      ),
      findsNothing,
    );
    // **The context row is not here, at rest or otherwise.** It read `14 new ·
    // 154 scheduled` under a numeral of the same snapshot; both figures are on
    // the deck rows or beyond today's horizon.
    expect(inSummary(find.text('14')), findsNothing);
    expect(inSummary(find.text('154')), findsNothing);
    expect(
      inSummary(find.text(english.deckHeroNewMetricWord.toLowerCase())),
      findsNothing,
    );
    // The hero numeral still outranks everything the panel draws.
    expect(
      sizeOfText(tester, '12'),
      greaterThan(sizeOfText(tester, english.deckSummaryCardsDueWord)),
    );
    // The learned line and its figure ride the shared progress component,
    // announced as one semantics node — at rest, so both readers get it.
    expect(
      inSummary(
        find.bySemanticsLabel(english.deckLearnedProgressLabel(82, 180)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('new-only: the new cards take the hero (BR-150)', (tester) async {
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
    expect(inSummary(find.text('20')), findsWidgets);
    // Nothing due, so no "cards due" headline to mislead with.
    expect(inSummary(find.text(english.deckSummaryCardsDueWord)), findsNothing);

    // The hero word instead, capitalised, because here it is the unit the
    // numeral counts rather than a context-row label.
    expect(inSummary(find.text(english.deckHeroNewMetricWord)), findsOneWidget);

    final bar = tester.widget<MxProgressBar>(
      inSummary(find.byType(MxProgressBar)),
    );
    expect(bar.value, 0);
  });

  testWidgets('both sets empty: the panel stays away entirely', (tester) async {
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

    // Nothing new and nothing due. The panel used to wait behind a one-line
    // link; the link went with the dismiss button it existed to undo (owner
    // decision, 2026-08-25), so a caught-up level simply gets its list. The
    // deck card's own bar still carries the finished progress, which is the
    // one figure the panel would have added.
    expect(find.byType(DeckLevelSummaryWidget), findsNothing);

    final bar = tester.widget<MxProgressBar>(find.byType(MxProgressBar).first);
    expect(bar.value, 1);
  });
}
