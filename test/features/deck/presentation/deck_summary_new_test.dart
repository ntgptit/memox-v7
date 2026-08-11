import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/deck_fixtures.dart';
import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// What the level's headline claims, against what the level actually holds
/// (BR-150).
///
/// **"Caught up" is earned by both sets being empty.** The headline used to
/// follow the due count alone, so a library of nothing but unlearned cards
/// opened on a green "All caught up" — true of reviews, false of the day.
void main() {
  final english = AppLocalizationsEn();

  Finder inSummary(Finder matching) => find.descendant(
    of: find.byType(DeckLevelSummaryWidget),
    matching: matching,
  );

  testWidgets('new-only: the headline is the new count, not caught up', (
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
    expect(
      inSummary(
        find.textContaining(
          english.deckSummaryNewToLearn(20),
          findRichText: true,
        ),
      ),
      findsOneWidget,
    );
    expect(
      inSummary(
        find.textContaining(english.deckSummaryCaughtUp, findRichText: true),
      ),
      findsNothing,
    );
  });

  testWidgets('mixed: due leads the headline and new rides beside it', (
    tester,
  ) async {
    await pumpDeckScreen(
      tester,
      repository: FakeDeckRepository.withSummaries(<DeckSummary>[
        fakeSummary(
          id: 'd1',
          name: 'Working',
          totalCardCount: 30,
          newCardCount: 12,
          dueCardCount: 4,
        ),
      ]),
      screen: const DeckListScreen(),
    );

    expect(
      inSummary(
        find.textContaining(
          english.deckSummaryNewBesideDue(12),
          findRichText: true,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('both sets empty: caught up, at last honestly', (tester) async {
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

    expect(
      inSummary(
        find.textContaining(english.deckSummaryCaughtUp, findRichText: true),
      ),
      findsOneWidget,
    );
  });
}
