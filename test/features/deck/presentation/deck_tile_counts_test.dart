import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_study_button_widget.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_progress_bar.dart';

import 'support/deck_fixtures.dart';
import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The tile's state matrix: two workload numbers, one gauge, one verb
/// (BR-150, BR-142, BR-29).
///
/// **Both numbers are always on the line, zero included.** An absent metric is
/// a convention — "no chip means none due" — and a convention is exactly what
/// a glanceable line must not require. Each state below asserts presence *and*
/// wording, because the words are the accessible signal and colour only
/// supports them.
void main() {
  final english = AppLocalizationsEn();

  String due(int count) => '$count ${english.deckDueMetricWord}';
  String fresh(int count) => '$count ${english.deckNewMetricWord}';

  /// Scoped to the tile: the summary panel above the list states the same
  /// metrics in the same words, and an unscoped finder counts both.
  Finder onTile(Finder matching) =>
      find.descendant(of: find.byType(DeckTileWidget), matching: matching);

  Future<void> pump(WidgetTester tester, DeckSummary summary) => pumpDeckScreen(
    tester,
    repository: FakeDeckRepository.withSummaries(<DeckSummary>[summary]),
    screen: const DeckListScreen(),
  );

  group('mixed (7 Due, 14 New, 37%)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Nouns',
      totalCardCount: 60,
      newCardCount: 14,
      dueCardCount: 7,
      learnedCardCount: 22,
    );

    testWidgets('both metrics, Study, and a gauge below 100%', (tester) async {
      await pump(tester, summary);

      expect(onTile(find.text(due(7))), findsOneWidget);
      expect(onTile(find.text(fresh(14))), findsOneWidget);
      expect(find.byType(DeckStudyButtonWidget), findsOneWidget);

      final bar = tester.widget<MxProgressBar>(
        find.descendant(
          of: find.byType(DeckTileWidget),
          matching: find.byType(MxProgressBar),
        ),
      );
      expect(bar.value, lessThan(1));
      expect(
        onTile(find.text(english.deckLearnedPercentLabel(37))),
        findsOneWidget,
      );
    });

    testWidgets('the due chip carries the clock, and no NEW micro-label '
        'survives', (tester) async {
      await pump(tester, summary);

      expect(onTile(find.byIcon(Icons.schedule)), findsOneWidget);
      // The old chip drew a tiny "NEW" glyph and then said "14 new" beside it —
      // the same word twice at two sizes. The metric is the only carrier now.
      expect(find.byIcon(Icons.fiber_new_outlined), findsNothing);
    });

    testWidgets('the gauge is inset with the card content, not flush at the '
        'edge', (tester) async {
      await pump(tester, summary);

      final card = tester.getRect(find.byType(DeckTileWidget));
      final bar = tester.getRect(
        find.descendant(
          of: find.byType(DeckTileWidget),
          matching: find.byType(MxProgressBar),
        ),
      );

      // Flush at the edge it read as a decorated border; inside the surface it
      // reads as a measurement. The inset is the card's own content padding.
      expect(bar.left - card.left, greaterThan(0));
      expect(card.right - bar.right, greaterThan(0));
      expect(card.bottom - bar.bottom, greaterThan(0));
    });
  });

  group('new-only (0 Due, 14 New)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Fresh deck',
      totalCardCount: 20,
      newCardCount: 14,
    );

    testWidgets('states the zero, keeps Study, and claims no success', (
      tester,
    ) async {
      await pump(tester, summary);

      expect(onTile(find.text(due(0))), findsOneWidget);
      expect(onTile(find.text(fresh(14))), findsOneWidget);
      expect(find.byType(DeckStudyButtonWidget), findsOneWidget);
      // Nothing due today is not "done": no success ink anywhere on the tile.
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });
  });

  group('due-only (5 Due, 0 New)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Seasoned deck',
      totalCardCount: 9,
      dueCardCount: 5,
      learnedCardCount: 4,
    );

    testWidgets('states the zero on the new side and keeps Study', (
      tester,
    ) async {
      await pump(tester, summary);

      expect(onTile(find.text(due(5))), findsOneWidget);
      expect(onTile(find.text(fresh(0))), findsOneWidget);
      expect(find.byType(DeckStudyButtonWidget), findsOneWidget);
    });
  });

  group('nothing studyable (0 Due, 0 New, 50%)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Half way',
      totalCardCount: 8,
      learnedCardCount: 4,
    );

    testWidgets('both zeroes stay on the line and Study is absent, not '
        'disabled', (tester) async {
      await pump(tester, summary);

      expect(onTile(find.text(due(0))), findsOneWidget);
      expect(onTile(find.text(fresh(0))), findsOneWidget);
      expect(find.byType(DeckStudyButtonWidget), findsNothing);
    });

    testWidgets('and does not claim completion for an idle day (BR-29)', (
      tester,
    ) async {
      await pump(tester, summary);

      // 50% learned with nothing pending is neutral: no success check, and the
      // percentage stays in the quiet variant — success is earned at 100%.
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(
        onTile(find.text(english.deckLearnedPercentLabel(50))),
        findsOneWidget,
      );
    });
  });

  group('completed (0 Due, 0 New, 100%)', () {
    final summary = fakeSummary(
      id: 'd1',
      name: 'Verbs',
      totalCardCount: 60,
      learnedCardCount: 60,
    );

    testWidgets('success lives on the check and the full gauge only', (
      tester,
    ) async {
      await pump(tester, summary);

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(onTile(find.text(due(0))), findsOneWidget);
      expect(onTile(find.text(fresh(0))), findsOneWidget);
      expect(
        onTile(find.text(english.deckLearnedPercentLabel(100))),
        findsOneWidget,
      );
      expect(find.byType(DeckStudyButtonWidget), findsNothing);

      final bar = tester.widget<MxProgressBar>(
        find.descendant(
          of: find.byType(DeckTileWidget),
          matching: find.byType(MxProgressBar),
        ),
      );
      expect(bar.value, 1);
    });

    testWidgets('sits at the same height as a studyable neighbour', (
      tester,
    ) async {
      // The completed card has no Study pill, and without a floor on the
      // action row it sat 24px shorter — a column that steps at the exact
      // moment a deck is finished. The floor keeps one rhythm.
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(
            id: 'd1',
            name: 'Nouns',
            totalCardCount: 60,
            newCardCount: 14,
            dueCardCount: 7,
            learnedCardCount: 22,
          ),
          fakeSummary(
            id: 'd2',
            name: 'Verbs',
            totalCardCount: 60,
            learnedCardCount: 60,
          ),
        ]),
        screen: const DeckListScreen(),
      );

      final tiles = find
          .byType(DeckTileWidget)
          .evaluate()
          .map((element) => element.size!.height)
          .toList();
      expect(tiles, hasLength(2));
      expect(tiles.first, tiles.last);
    });
  });

  group('empty deck (0 cards)', () {
    final summary = fakeSummary(id: 'd1', name: 'Brand new');

    testWidgets('says No cards, draws no gauge, offers no Study', (
      tester,
    ) async {
      await pump(tester, summary);

      expect(find.text(english.deckNoCardsLabel), findsOneWidget);
      // A gauge needs a denominator; an empty deck has none, so there is no
      // bar to draw rather than a 0% one.
      expect(
        find.descendant(
          of: find.byType(DeckTileWidget),
          matching: find.byType(MxProgressBar),
        ),
        findsNothing,
      );
      expect(find.byType(DeckStudyButtonWidget), findsNothing);
      // And no workload zeroes: "no cards" is a different fact from "nothing
      // pending", and printing 0/0 here would collapse the two.
      expect(onTile(find.text(due(0))), findsNothing);
    });
  });

  group('at text scale 2.0 on a compact width', () {
    testWidgets('the whole anatomy survives 320px at double text', (
      tester,
    ) async {
      await pumpDeckScreen(
        tester,
        repository: FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(
            id: 'd1',
            name: 'A deck with a deliberately long name that wraps',
            totalCardCount: 60,
            newCardCount: 14,
            dueCardCount: 7,
            learnedCardCount: 22,
          ),
        ]),
        screen: const DeckListScreen(),
        surface: const Size(320, 852),
        textScale: 2,
      );

      expect(onTile(find.text(due(7))), findsOneWidget);
      expect(onTile(find.text(fresh(14))), findsOneWidget);
      expect(find.byType(DeckStudyButtonWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
