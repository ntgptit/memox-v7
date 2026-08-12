import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_impact_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The write flows reached from a deck's action menu: rename, delete with its
/// impact, and reset content type (UC-03, UC-09).
///
/// Split from `deck_list_level_test.dart`, which keeps the read states, and from
/// `deck_move_picker_test.dart`, which owns move.
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
        nextOverdueTickAt: null,
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
          children: <DeckSummary>[
            fakeChildSummary(id: 'c1', name: 'Child', parentId: 'deck-1'),
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
      await tester.enterText(deckFormField, 'New name');
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
      await tester.enterText(deckFormField, '   ');
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

    testWidgets('deleting a sub-deck lands on its parent, not the root', (
      tester,
    ) async {
      // Where the deck was is where its siblings are, and that is what the user
      // was browsing. Landing at the root reads as though more than the one
      // deck had gone — which is how this was reported.
      final repository = serving(
        fakeSubDeck(id: 'child', name: 'Hiragana', parentId: 'parent'),
      );
      final router = await pumpDeckApp(
        tester,
        repository: repository,
        initialLocation: '/decks/child',
      );

      await openActions(tester);
      await tester.tap(find.text(english.deckDeleteAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckDeleteConfirmAction));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/decks/parent',
      );
    });

    testWidgets('deleting a root deck lands on the root list', (tester) async {
      // A root has no level above it, so the list is the honest destination —
      // `RoutePaths.decks` is '/', the shell's first branch.
      final repository = serving(fakeRootDeck(id: 'deck-1', name: 'Japanese'));
      final router = await pumpDeckApp(
        tester,
        repository: repository,
        initialLocation: '/decks/deck-1',
      );

      await openActions(tester);
      await tester.tap(find.text(english.deckDeleteAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.deckDeleteConfirmAction));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/');
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
}
