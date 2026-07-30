import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/deck_deletion_impact_model.dart';
import 'package:memox/features/deck/domain/deck_entity.dart';
import 'package:memox/features/deck/presentation/deck_detail_screen.dart';
import 'package:memox/features/deck/presentation/deck_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The deck detail screen: content-type action matrix (UC-08), the write flows
/// reached from it (UC-03, UC-09), and the not-found path (UC-03 E1).
void main() {
  final english = AppLocalizationsEn();

  /// A repository serving one deck and the children it should show.
  FakeDeckRepository serving(
    DeckEntity deck, {
    List<DeckEntity> children = const <DeckEntity>[],
    List<DeckEntity>? allDecks,
    Failure? writeFailure,
  }) => FakeDeckRepository(
    deckById: (id) async => deck,
    childDecks: (_) => Stream<List<DeckEntity>>.value(children),
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

  group('read states', () {
    testWidgets('loading is announced to a screen reader', (tester) async {
      await pumpDetail(tester, FakeDeckRepository.pending());

      expect(
        tester
            .widget<MxLoadingState>(find.byType(MxLoadingState))
            .semanticsLabel,
        english.deckDetailLoadingLabel,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a deck deleted elsewhere shows not-found, not an error', (
      tester,
    ) async {
      // UC-03 E1. Nothing the user did was wrong, so this gets a way back rather
      // than a retry button that would fail forever.
      await pumpDetail(
        tester,
        FakeDeckRepository.failing(
          const NotFoundFailure(message: 'That deck no longer exists.'),
        ),
      );

      expect(find.text(english.deckDetailNotFoundTitle), findsOneWidget);
      expect(find.text(english.deckBackToDecksAction), findsOneWidget);
      expect(find.text(english.retryAction), findsNothing);
    });

    testWidgets('a read failure shows a retryable error with no SQL in it', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        FakeDeckRepository.failing(
          const DatabaseFailure(message: 'SqliteException(11): malformed'),
        ),
      );

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.deckDetailLoadErrorTitle), findsOneWidget);
      expect(find.text(english.retryAction), findsOneWidget);
      expect(find.textContaining('Sqlite'), findsNothing);
    });

    testWidgets('children are listed and the title is the deck name', (
      tester,
    ) async {
      final deck = fakeRootDeck(id: 'deck-1', name: 'Japanese N5');
      final children = <DeckEntity>[
        fakeSubDeck(id: 'c1', name: 'Hiragana', parentId: 'deck-1'),
        fakeSubDeck(id: 'c2', name: 'Katakana', parentId: 'deck-1'),
      ];

      await pumpDetail(tester, serving(deck, children: children));

      expect(find.text('Japanese N5'), findsOneWidget);
      expect(find.byType(DeckChildTileWidget), findsNWidgets(2));
      expect(find.text('Hiragana'), findsOneWidget);
    });

    testWidgets('a later emission updates the child list', (tester) async {
      final controller = StreamController<List<DeckEntity>>();
      addTearDown(controller.close);
      final deck = fakeRootDeck(id: 'deck-1', name: 'Japanese');

      await pumpDetail(
        tester,
        FakeDeckRepository(
          deckById: (_) async => deck,
          childDecks: (_) => controller.stream,
        ),
      );

      controller.add(const <DeckEntity>[]);
      await tester.pump();
      expect(find.byType(MxEmptyState), findsOneWidget);

      controller.add(<DeckEntity>[
        fakeSubDeck(id: 'c1', name: 'Hiragana', parentId: 'deck-1'),
      ]);
      await tester.pump();

      expect(find.byType(DeckChildTileWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the create action matrix (UC-08)', () {
    testWidgets('a root deck offers only Create deck (BR-59)', (tester) async {
      await pumpDetail(
        tester,
        serving(fakeRootDeck(id: 'deck-1', name: 'Root')),
      );

      expect(
        find.bySemanticsLabel(RegExp(english.deckCreateSubDeckAction)),
        findsWidgets,
      );
      // No card affordance at all on a root: BR-58 makes a root hold decks only,
      // and BR-59 says the Create button therefore has one option.
      expect(find.text(english.deckCreateCardUnavailableMessage), findsNothing);
    });

    testWidgets('an unset sub-deck shows both choices (BR-61)', (tester) async {
      // The card one is disabled with the reason rather than hidden. Hiding it
      // would teach the user this deck can only hold decks, which is not true
      // until they add one.
      await pumpDetail(
        tester,
        serving(fakeSubDeck(id: 'deck-1', name: 'Unset', parentId: 'root')),
      );

      expect(find.text(english.deckDetailEmptyUnsetTitle), findsOneWidget);
      expect(find.text(english.deckCreateSubDeckAction), findsOneWidget);
      expect(
        find.text(english.deckCreateCardUnavailableMessage),
        findsOneWidget,
      );
    });

    testWidgets('a deck-type sub-deck offers only Create deck (BR-66)', (
      tester,
    ) async {
      await pumpDetail(
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
      expect(find.text(english.deckCreateCardUnavailableMessage), findsNothing);
    });

    testWidgets('a card-type deck offers no deck creation at all (BR-63)', (
      tester,
    ) async {
      // Not an empty deck list — no deck list. A card deck cannot hold decks, so
      // there is nothing to add and nothing to show.
      await pumpDetail(
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
      expect(find.text(english.deckDetailEmptyCardMessage), findsOneWidget);
      expect(find.text(english.deckCreateSubDeckAction), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(english.deckCreateSubDeckAction)),
        findsNothing,
      );
    });
  });

  group('create a sub-deck (UC-08)', () {
    testWidgets('sends the name under this deck, with no scheduler section', (
      tester,
    ) async {
      // A sub-deck inherits its root's scheduler and must leave the columns null
      // (BR-06), so the form must not offer the choice.
      final repository = serving(
        fakeSubDeck(id: 'deck-1', name: 'Unset', parentId: 'root'),
      );
      await pumpDetail(tester, repository);

      await tester.tap(find.text(english.deckCreateSubDeckAction));
      await tester.pumpAndSettle();
      expect(find.text(english.schedulerSectionLabel), findsNothing);

      await tester.enterText(find.byType(TextField), 'Hiragana');
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
      await pumpDetail(tester, repository);

      await tester.tap(find.text(english.deckCreateSubDeckAction));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Deeper');
      await tester.tap(find.text(english.deckFormSubmitAction));
      await tester.pumpAndSettle();

      expect(find.text(english.deckConflictMessage), findsOneWidget);
      // Form still open, input intact.
      expect(find.text('Deeper'), findsOneWidget);
    });
  });

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
        ..deletionImpact = const DeckDeletionImpactStub(
          descendantDeckCount: 3,
          cardCount: 42,
        ).value;
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

  group('responsive and accessibility', () {
    const compact = Size(320, 568);

    testWidgets('a long child list fits 320x568 at textScaler 2.0', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        serving(
          fakeRootDeck(id: 'deck-1', name: 'Root'),
          children: <DeckEntity>[
            for (var i = 0; i < 20; i++)
              fakeSubDeck(
                id: 'c$i',
                name: 'Child number $i',
                parentId: 'deck-1',
              ),
          ],
        ),
        surface: compact,
        textScale: 2,
      );

      expect(find.byType(DeckChildTileWidget), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the unset empty state fits 320x568 at textScaler 2.0', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        serving(fakeSubDeck(id: 'deck-1', name: 'Unset', parentId: 'root')),
        surface: compact,
        textScale: 2,
      );

      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every content type builds under the dark theme', (
      tester,
    ) async {
      for (final contentType in DeckContentType.values) {
        if (contentType == DeckContentType.unknown) continue;
        await pumpDetail(
          tester,
          serving(
            fakeSubDeck(
              id: 'deck-1',
              name: 'Deck',
              parentId: 'root',
              contentType: contentType,
            ),
          ),
          isDark: true,
        );

        expect(tester.takeException(), isNull);
      }
    });
  });
}

/// A tiny holder so the impact fixture reads as data at the call site.
class DeckDeletionImpactStub {
  const DeckDeletionImpactStub({
    required this.descendantDeckCount,
    required this.cardCount,
  });

  final int descendantDeckCount;
  final int cardCount;

  DeckDeletionImpact get value => DeckDeletionImpact(
    descendantDeckCount: descendantDeckCount,
    cardCount: cardCount,
  );
}
