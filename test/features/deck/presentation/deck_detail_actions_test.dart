import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_impact_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_detail_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_detail_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The write flows reached from a deck's action menu: rename, delete with its
/// impact, reset content type and move (UC-03, UC-09).
///
/// Split from `deck_detail_screen_test.dart`, which keeps the read states and
/// the create-action matrix.
void main() {
  final english = AppLocalizationsEn();

  /// A repository serving one deck and the children it should show.
  FakeDeckRepository serving(
    DeckEntity deck, {
    List<DeckEntity> children = const <DeckEntity>[],
    List<DeckEntity>? allDecks,
    Failure? writeFailure,
  }) => FakeDeckRepository(
    // One builder for the pair, because the contract returns the pair. A deck and
    // a child list from different snapshots is no longer expressible here.
    deckDetail: (_) =>
        Stream<DeckDetail>.value(DeckDetail(deck: deck, childDecks: children)),
    allDecks: () =>
        Stream<List<DeckEntity>>.value(allDecks ?? <DeckEntity>[deck]),
    writeFailure: writeFailure,
  );

  Future<void> pumpDetail(
    WidgetTester tester,
    FakeDeckRepository repository, {
    String deckId = 'deck-1',
    Size surface = const Size(393, 852),
    double textScale = 1,
    bool isDark = false,
  }) => pumpDeckScreen(
    tester,
    repository: repository,
    screen: DeckDetailScreen(deckId: deckId),
    surface: surface,
    textScale: textScale,
    isDark: isDark,
  );

  group('the action menu', () {
    Future<void> openActions(WidgetTester tester) async {
      await tester.tap(
        find.bySemanticsLabel(RegExp(english.deckActionsSemanticLabel)).last,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a root offers rename and delete but not move (UC-09 A2)', (
      tester,
    ) async {
      // Moving a root would put scheduler columns on a non-root (BR-06).
      await pumpDetail(
        tester,
        serving(fakeRootDeck(id: 'deck-1', name: 'Root')),
      );

      await openActions(tester);

      expect(find.text(english.deckRenameAction), findsOneWidget);
      expect(find.text(english.deckDeleteAction), findsOneWidget);
      expect(find.text(english.deckMoveAction), findsNothing);
      // A root's content type is invariant (BR-58).
      expect(find.text(english.deckResetContentTypeAction), findsNothing);
    });

    testWidgets('an empty typed sub-deck offers reset (BR-68)', (tester) async {
      await pumpDetail(
        tester,
        serving(
          fakeSubDeck(
            id: 'deck-1',
            name: 'Empty',
            parentId: 'root',
            contentType: DeckContentType.deck,
          ),
        ),
      );

      await openActions(tester);

      expect(find.text(english.deckResetContentTypeAction), findsOneWidget);
      expect(find.text(english.deckMoveAction), findsOneWidget);
    });

    testWidgets('a sub-deck with children does not offer reset', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        serving(
          fakeSubDeck(
            id: 'deck-1',
            name: 'Has children',
            parentId: 'root',
            contentType: DeckContentType.deck,
          ),
          children: <DeckEntity>[
            fakeSubDeck(id: 'c1', name: 'Child', parentId: 'deck-1'),
          ],
        ),
      );

      await openActions(tester);

      expect(find.text(english.deckResetContentTypeAction), findsNothing);
    });

    testWidgets('rename sends the new name and closes', (tester) async {
      final repository = serving(fakeRootDeck(id: 'deck-1', name: 'Old name'));
      await pumpDetail(tester, repository);

      await openActions(tester);
      await tester.tap(find.text(english.deckRenameAction));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'New name');
      await tester.tap(find.text(english.deckRenameSubmitAction));
      await tester.pumpAndSettle();

      expect(repository.renames.single.deckId, 'deck-1');
      expect(repository.renames.single.name, 'New name');
      expect(find.text(english.deckRenameSubmitAction), findsNothing);
    });

    testWidgets('rename refuses an empty name inline', (tester) async {
      final repository = serving(fakeRootDeck(id: 'deck-1', name: 'Old name'));
      await pumpDetail(tester, repository);

      await openActions(tester);
      await tester.tap(find.text(english.deckRenameAction));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text(english.deckRenameSubmitAction));
      await tester.pumpAndSettle();

      expect(find.text(english.deckNameEmptyError), findsOneWidget);
      expect(repository.renames, isEmpty);
    });

    testWidgets('delete names the deck and states the impact (BR-04)', (
      tester,
    ) async {
      final repository = serving(fakeRootDeck(id: 'deck-1', name: 'Japanese'))
        ..deletionImpact = const DeckDeletionImpact(
          descendantDeckCount: 3,
          cardCount: 42,
        );
      await pumpDetail(tester, repository);

      await openActions(tester);
      await tester.tap(find.text(english.deckDeleteAction));
      await tester.pumpAndSettle();

      expect(
        find.text(english.deckDeleteConfirmTitle('Japanese')),
        findsOneWidget,
      );
      expect(find.text(english.deckDeleteImpactMessage(3, 42)), findsOneWidget);
    });

    testWidgets('confirming the delete sends exactly one delete', (
      tester,
    ) async {
      // Through the real router: a successful delete navigates back to the list,
      // and `goNamed` needs a GoRouter above it. Pumping the screen alone would
      // fail on the navigation rather than on the delete.
      final repository = serving(fakeRootDeck(id: 'deck-1', name: 'Japanese'));
      await pumpDeckApp(
        tester,
        repository: repository,
        initialLocation: '/decks/deck-1',
      );

      await openActions(tester);
      await tester.tap(find.text(english.deckDeleteAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckDeleteConfirmAction));
      await tester.pumpAndSettle();

      expect(repository.deletes, <String>['deck-1']);
    });

    testWidgets('cancelling the delete does nothing (UC-03 A4)', (
      tester,
    ) async {
      final repository = serving(fakeRootDeck(id: 'deck-1', name: 'Japanese'));
      await pumpDetail(tester, repository);

      await openActions(tester);
      await tester.tap(find.text(english.deckDeleteAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.commonCancelAction));
      await tester.pumpAndSettle();

      expect(repository.deletes, isEmpty);
    });

    testWidgets('reset asks first and then sends it (BR-68)', (tester) async {
      final repository = serving(
        fakeSubDeck(
          id: 'deck-1',
          name: 'Empty',
          parentId: 'root',
          contentType: DeckContentType.deck,
        ),
      );
      await pumpDetail(tester, repository);

      await openActions(tester);
      await tester.tap(find.text(english.deckResetContentTypeAction));
      await tester.pumpAndSettle();
      expect(find.text(english.deckResetContentTypeMessage), findsOneWidget);

      await tester.tap(find.text(english.deckResetContentTypeConfirmAction));
      await tester.pumpAndSettle();

      expect(repository.resets, <String>['deck-1']);
    });

    testWidgets('a reset refused by the repository shows a conflict', (
      tester,
    ) async {
      // The tree can change between the dialog opening and the confirm landing,
      // so the repository decides and this is how its refusal reads.
      final repository = serving(
        fakeSubDeck(
          id: 'deck-1',
          name: 'Not really empty',
          parentId: 'root',
          contentType: DeckContentType.deck,
        ),
        writeFailure: const ConflictFailure(message: 'still has cards'),
      );
      await pumpDetail(tester, repository);

      await openActions(tester);
      await tester.tap(find.text(english.deckResetContentTypeAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckResetContentTypeConfirmAction));
      await tester.pumpAndSettle();

      expect(find.text(english.deckConflictMessage), findsOneWidget);
    });
  });

  group('move (UC-09)', () {
    testWidgets('the picker lists targets and names why one is refused', (
      tester,
    ) async {
      final root = fakeRootDeck(id: 'root', name: 'Root');
      final source = fakeSubDeck(
        id: 'deck-1',
        name: 'Source',
        parentId: 'root',
        rootId: 'root',
      );
      final sibling = fakeSubDeck(
        id: 'sibling',
        name: 'Sibling',
        parentId: 'root',
        rootId: 'root',
        contentType: DeckContentType.deck,
      );
      final cardDeck = fakeSubDeck(
        id: 'cards',
        name: 'Card deck',
        parentId: 'root',
        rootId: 'root',
        contentType: DeckContentType.card,
      );
      final repository = serving(
        source,
        allDecks: <DeckEntity>[root, source, sibling, cardDeck],
      );

      await pumpDetail(tester, repository);
      await tester.tap(
        find.bySemanticsLabel(RegExp(english.deckActionsSemanticLabel)).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckMoveAction));
      await tester.pumpAndSettle();

      expect(find.text(english.deckMoveTitle), findsOneWidget);
      expect(find.text('Sibling'), findsOneWidget);
      // Rejected rows stay visible with the reason — hiding them leaves the user
      // hunting for a deck that is right there.
      expect(find.text(english.deckMoveRejectHoldsCards), findsOneWidget);
      expect(find.text(english.deckMoveRejectItself), findsOneWidget);
      expect(find.text(english.deckMoveRejectAlreadyParent), findsOneWidget);
    });

    testWidgets('an ineligible target cannot be tapped', (tester) async {
      final root = fakeRootDeck(id: 'root', name: 'Root');
      final source = fakeSubDeck(
        id: 'deck-1',
        name: 'Source',
        parentId: 'root',
        rootId: 'root',
      );
      final cardDeck = fakeSubDeck(
        id: 'cards',
        name: 'Card deck',
        parentId: 'root',
        rootId: 'root',
        contentType: DeckContentType.card,
      );
      // One eligible sibling, so the picker renders its list. With every target
      // refused it correctly shows the empty state instead, and there would be no
      // row to tap — which is the behaviour the sibling keeps out of the way.
      final sibling = fakeSubDeck(
        id: 'sibling',
        name: 'Sibling',
        parentId: 'root',
        rootId: 'root',
        contentType: DeckContentType.deck,
      );
      final repository = serving(
        source,
        allDecks: <DeckEntity>[root, source, cardDeck, sibling],
      );

      await pumpDetail(tester, repository);
      await tester.tap(
        find.bySemanticsLabel(RegExp(english.deckActionsSemanticLabel)).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckMoveAction));
      await tester.pumpAndSettle();

      // Asserted by behaviour rather than by inspecting the widget: what matters
      // is that a tap on a refused target writes nothing, whichever way the row
      // is disabled.
      await tester.tap(find.text('Card deck'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(repository.moves, isEmpty);
      // And the eligible one still works, so the disabling is targeted rather
      // than the whole list being inert.
      await tester.tap(find.text('Sibling'));
      await tester.pumpAndSettle();
      expect(repository.moves.single.target, 'sibling');
    });

    testWidgets('choosing an eligible target submits the move', (tester) async {
      final root = fakeRootDeck(id: 'root', name: 'Root');
      final source = fakeSubDeck(
        id: 'deck-1',
        name: 'Source',
        parentId: 'root',
        rootId: 'root',
      );
      final sibling = fakeSubDeck(
        id: 'sibling',
        name: 'Sibling',
        parentId: 'root',
        rootId: 'root',
        contentType: DeckContentType.deck,
      );
      final repository = serving(
        source,
        allDecks: <DeckEntity>[root, source, sibling],
      );

      await pumpDetail(tester, repository);
      await tester.tap(
        find.bySemanticsLabel(RegExp(english.deckActionsSemanticLabel)).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckMoveAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sibling'));
      await tester.pumpAndSettle();

      expect(repository.moves.single.deckId, 'deck-1');
      expect(repository.moves.single.target, 'sibling');
    });
  });
}
