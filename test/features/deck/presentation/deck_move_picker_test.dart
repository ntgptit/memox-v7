import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The move-target picker, reached from a deck's action menu (UC-09).
///
/// Split from `deck_level_actions_test.dart` when that file crossed the size
/// guard. A real seam rather than a cut at a line number: the picker is the one
/// action with a screen of its own, and what it asserts — which targets are
/// offered, and why the refused ones say so — has nothing in common with rename,
/// delete and reset.
void main() {
  final english = AppLocalizationsEn();

  /// A repository serving one deck and the children it should show.
  FakeDeckRepository serving(
    DeckEntity deck, {
    List<DeckSummary> children = const <DeckSummary>[],
    List<DeckEntity>? allDecks,
    Failure? writeFailure,
  }) => FakeDeckRepository(
    // One builder for the pair, because the contract returns the pair. A deck and
    // a child list from different snapshots is no longer expressible here.
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
    screen: DeckListScreen(parentDeckId: deckId),
    surface: surface,
    textScale: textScale,
    isDark: isDark,
  );

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
