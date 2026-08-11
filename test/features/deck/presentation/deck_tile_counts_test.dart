import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_study_button_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/deck_fixtures.dart';
import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The tile's two numbers and its one verb, across the four workloads a deck
/// can hold (BR-150, BR-142).
///
/// **The defect this file pins:** the Study button used to follow `hasDueCards`
/// alone, so a brand-new deck — twenty cards, all unlearned, the first deck a
/// real user ever makes — offered no way to study at all, and the tile's only
/// number was a due count that said nothing about the twenty.
void main() {
  final english = AppLocalizationsEn();

  Future<void> pump(WidgetTester tester, DeckSummary summary) => pumpDeckScreen(
    tester,
    repository: FakeDeckRepository.withSummaries(<DeckSummary>[summary]),
    screen: const DeckListScreen(),
  );

  group('new-only (20 new, 0 due)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Fresh deck',
      totalCardCount: 20,
      newCardCount: 20,
    );

    testWidgets('shows the new count and no due chip', (tester) async {
      await pump(tester, summary);

      expect(find.text(english.deckNewCountLabel(20)), findsOneWidget);
      expect(find.textContaining('due now'), findsNothing);
      // Not the resting text either: twenty cards are waiting.
      expect(find.text(english.deckNoDueLabel), findsNothing);
    });

    testWidgets('offers Study', (tester) async {
      await pump(tester, summary);

      expect(find.byType(DeckStudyButtonWidget), findsOneWidget);
    });
  });

  group('due-only (0 new, 5 due)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Seasoned deck',
      totalCardCount: 9,
      dueCardCount: 5,
    );

    testWidgets('shows the due chip and no new chip', (tester) async {
      await pump(tester, summary);

      expect(find.text(english.deckDueNowLabel(5)), findsOneWidget);
      expect(find.textContaining(' new'), findsNothing);
    });

    testWidgets('offers Study', (tester) async {
      await pump(tester, summary);

      expect(find.byType(DeckStudyButtonWidget), findsOneWidget);
    });
  });

  group('mixed (12 new, 4 due)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Working deck',
      totalCardCount: 30,
      newCardCount: 12,
      dueCardCount: 4,
    );

    testWidgets('shows both counts, separately (BR-150)', (tester) async {
      await pump(tester, summary);

      expect(find.text(english.deckDueNowLabel(4)), findsOneWidget);
      expect(find.text(english.deckNewCountLabel(12)), findsOneWidget);
      // Never one merged figure.
      expect(find.textContaining('16'), findsNothing);
    });

    testWidgets('offers Study', (tester) async {
      await pump(tester, summary);

      expect(find.byType(DeckStudyButtonWidget), findsOneWidget);
    });
  });

  group('nothing waiting (0 new, 0 due, 8 cards)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Done for today',
      totalCardCount: 8,
      learnedCardCount: 8,
    );

    testWidgets('offers no Study control at all', (tester) async {
      // Not disabled — absent. BR-29 makes "nothing due" good news, and a
      // greyed control says you cannot do the thing when the truth is there is
      // nothing to do.
      await pump(tester, summary);

      expect(find.byType(DeckStudyButtonWidget), findsNothing);
    });

    testWidgets('rests on "nothing due", not "no cards"', (tester) async {
      await pump(tester, summary);

      expect(find.text(english.deckNoDueLabel), findsOneWidget);
      expect(find.text(english.deckNoCardsLabel), findsNothing);
    });
  });

  group('at text scale 2.0 on a compact width', () {
    testWidgets('two chips and the Study pill neither overflow nor vanish', (
      tester,
    ) async {
      // The mixed row is the widest thing the tile can hold: two chips, the
      // pill, the meta line. 320 logical pixels at double text is the floor
      // the repo tests everything against.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(
            id: 'd1',
            name: 'A deck with a deliberately long name that wraps',
            totalCardCount: 30,
            newCardCount: 12,
            dueCardCount: 4,
          ),
        ]),
        screen: const DeckListScreen(),
        surface: const Size(320, 852),
        textScale: 2,
      );

      expect(find.byType(DeckStudyButtonWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('empty deck (0 cards)', () {
    final summary = fakeSummary(id: 'd1', name: 'Brand new');

    testWidgets('says "no cards yet" — a different fact from caught up', (
      tester,
    ) async {
      await pump(tester, summary);

      expect(find.text(english.deckNoCardsLabel), findsOneWidget);
      expect(find.text(english.deckNoDueLabel), findsNothing);
      expect(find.byType(DeckStudyButtonWidget), findsNothing);
    });
  });
}
