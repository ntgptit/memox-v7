import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// What `DeckListScreen` offers to create inside a deck, and what happens when
/// the form is submitted (UC-08).
///
/// Split from `deck_list_level_test.dart`, which keeps the read states and the
/// responsive checks. The matrix is the part most likely to regress silently:
/// the content type decides which affordances exist (BR-59, BR-61, BR-63,
/// BR-66), and a wrong branch renders a perfectly plausible screen.
void main() {
  final english = AppLocalizationsEn();

  /// A repository serving one deck and the children it should show.
  FakeDeckRepository serving(
    DeckEntity deck, {
    List<DeckSummary> children = const <DeckSummary>[],
    List<DeckEntity>? allDecks,
    Failure? writeFailure,
  }) => FakeDeckRepository(
    deckList: (_) => Stream<DeckListSnapshot>.value(
      DeckListSnapshot(
        ancestors: const <DeckPathSegment>[],
        parent: deck,
        decks: children,
        nextDueAt: null,
      ),
    ),
    allDecks: () =>
        Stream<List<DeckEntity>>.value(allDecks ?? <DeckEntity>[deck]),
    writeFailure: writeFailure,
  );

  Future<void> pumpLevel(
    WidgetTester tester,
    FakeDeckRepository repository, {
    String deckId = 'deck-1',
    Size surface = const Size(393, 852),
    double textScale = 1,
    bool isDark = false,
  }) => pumpDeckScreen(
    tester,
    repository: repository,
    screen: DeckListScreen(parentDeckId: deckId),
    surface: surface,
    textScale: textScale,
    isDark: isDark,
  );

  group('the create action matrix (UC-08)', () {
    testWidgets('a root deck offers only Create deck (BR-59)', (tester) async {
      await pumpLevel(
        tester,
        serving(fakeRootDeck(id: 'deck-1', name: 'Root')),
      );

      expect(
        find.bySemanticsLabel(RegExp(english.deckCreateSubDeckAction)),
        findsWidgets,
      );
      // No card affordance at all on a root: BR-58 makes a root hold decks only,
      // and BR-59 says the Create button therefore has one option — so neither
      // the chooser nor a card action appears.
      expect(find.text(english.deckCreateChildAction), findsNothing);
      expect(find.text(english.deckCreateCardAction), findsNothing);
    });

    testWidgets(
      'an unset sub-deck offers both kinds, neither disabled (BR-61)',
      (tester) async {
        // Both are real, enabled actions: BR-62 lets the first child of either
        // kind settle the deck's content_type, and `createCard` applies that in
        // the same transaction. Offering only a sub-deck left an unset deck with
        // no way to ever hold a card — the card screen opens only once the type
        // is already `card`, and only a card can set it.
        await pumpLevel(
          tester,
          serving(fakeSubDeck(id: 'deck-1', name: 'Unset', parentId: 'root')),
        );

        expect(find.text(english.deckDetailEmptyUnsetTitle), findsOneWidget);

        await tester.tap(find.text(english.deckCreateChildAction));
        await tester.pumpAndSettle();

        expect(find.text(english.deckCreateSubDeckAction), findsOneWidget);
        expect(find.text(english.deckCreateCardAction), findsOneWidget);
      },
    );

    testWidgets('a deck-type sub-deck offers only Create deck (BR-66)', (
      tester,
    ) async {
      await pumpLevel(
        tester,
        serving(
          fakeSubDeck(
            id: 'deck-1',
            name: 'Holds decks',
            parentId: 'root',
            contentType: DeckContentType.deck,
          ),
        ),
      );

      expect(find.text(english.deckDetailEmptyDeckTitle), findsOneWidget);
      // BR-66: the type is settled, so Create names the one action it still
      // has — no chooser, and no card option anywhere on the level.
      expect(find.text(english.deckCreateSubDeckAction), findsOneWidget);
      expect(find.text(english.deckCreateChildAction), findsNothing);
      expect(find.text(english.deckCreateCardAction), findsNothing);
    });

    testWidgets('a card-type deck offers no deck creation at all (BR-63)', (
      tester,
    ) async {
      // Not an empty deck list — no deck list. A card deck cannot hold decks, so
      // there is nothing to add and nothing to show.
      await pumpLevel(
        tester,
        serving(
          fakeSubDeck(
            id: 'deck-1',
            name: 'Holds cards',
            parentId: 'root',
            contentType: DeckContentType.card,
          ),
        ),
      );

      expect(find.text(english.deckDetailEmptyCardTitle), findsOneWidget);
      // The card-type deck now offers a way into its cards (M4.11); what it
      // still must not offer is deck creation (BR-63).
      expect(find.text(english.deckDetailOpenCardsAction), findsOneWidget);
      expect(find.text(english.deckCreateSubDeckAction), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(english.deckCreateSubDeckAction)),
        findsNothing,
      );
    });
  });

  group('create a sub-deck (UC-08)', () {
    /// On an `unset` deck the Create action asks which kind first (BR-61), so
    /// reaching the sub-deck form is two taps rather than one.
    Future<void> openSubDeckForm(WidgetTester tester) async {
      await tester.tap(find.text(english.deckCreateChildAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckCreateSubDeckAction));
      await tester.pumpAndSettle();
    }

    testWidgets('sends the name under this deck, with no scheduler section', (
      tester,
    ) async {
      // A sub-deck inherits its root's scheduler and must leave the columns null
      // (BR-06), so the form must not offer the choice.
      final repository = serving(
        fakeSubDeck(id: 'deck-1', name: 'Unset', parentId: 'root'),
      );
      await pumpLevel(tester, repository);

      await openSubDeckForm(tester);
      expect(find.text(english.schedulerSectionLabel), findsNothing);

      await tester.enterText(deckFormField, 'Hiragana');
      await tester.tap(find.text(english.deckFormSubmitAction));
      await tester.pumpAndSettle();

      expect(repository.createdSubDecks.single.name, 'Hiragana');
      expect(repository.createdSubDecks.single.parentDeckId, 'deck-1');
    });

    testWidgets('a depth refusal is shown, not swallowed (BR-55)', (
      tester,
    ) async {
      final repository = serving(
        fakeSubDeck(id: 'deck-1', name: 'Deep', parentId: 'root'),
        writeFailure: const ConflictFailure(message: 'too deep'),
      );
      await pumpLevel(tester, repository);

      await openSubDeckForm(tester);
      await tester.enterText(deckFormField, 'Deeper');
      await tester.tap(find.text(english.deckFormSubmitAction));
      await tester.pumpAndSettle();

      expect(find.text(english.deckConflictMessage), findsOneWidget);
      // Form still open, input intact.
      expect(find.text('Deeper'), findsOneWidget);
    });
  });
}
