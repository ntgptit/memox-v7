import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The breadcrumb on a deck level — when it appears, what it lists, and where a
/// step goes (M4.10d).
///
/// Split from `deck_list_level_test.dart` at the size guard, on a real seam: the
/// path is about the levels *above* this one, while everything left there is
/// about the level itself.
///
/// `MxBreadcrumb`'s own contract — overflow, semantics, the non-tappable step —
/// is in `test/shared/widgets/mx_breadcrumb_test.dart`. What is below is the
/// adapter's decisions: which levels get a path at all, and that the deck the
/// user is standing in is deliberately not in it.
void main() {
  /// A repository serving one deck and the children it should show.
  FakeDeckRepository serving(
    DeckEntity deck, {
    List<DeckSummary> children = const <DeckSummary>[],
    List<DeckPathSegment> ancestors = const <DeckPathSegment>[],
    List<DeckEntity>? allDecks,
    Failure? writeFailure,
  }) => FakeDeckRepository(
    deckList: (_) => Stream<DeckListSnapshot>.value(
      DeckListSnapshot(
        ancestors: ancestors,
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

  group('the path back up', () {
    testWidgets('a deck with ancestors shows them, and only them', (
      tester,
    ) async {
      await pumpLevel(
        tester,
        serving(
          fakeSubDeck(id: 'deck-1', name: 'Hiragana', parentId: 'branch'),
          ancestors: fakePath(<String>['Japanese N5', 'Kana']),
        ),
      );

      expect(find.byType(MxBreadcrumb), findsOneWidget);
      final MxBreadcrumb crumb = tester.widget(find.byType(MxBreadcrumb));
      // The deck the user is *in* is deliberately absent: the app-bar title one
      // line above already says it, and a trailing copy spent a third of the
      // strip repeating the largest text on screen.
      expect(crumb.items.map((MxBreadcrumbItem i) => i.label), <String>[
        'Japanese N5',
        'Kana',
      ]);
      expect(find.text('Hiragana'), findsOneWidget, reason: 'the title only');
      // Every step goes somewhere, which is the point of dropping the last one.
      expect(
        crumb.items.every((MxBreadcrumbItem i) => i.onTap != null),
        isTrue,
      );
    });

    testWidgets('a root deck shows no breadcrumb at all', (tester) async {
      // One level in, the only step above is the deck list, which Back and the
      // Decks tab both already reach in one tap. A crumb there would be a third
      // control doing the same thing.
      await pumpLevel(
        tester,
        serving(fakeRootDeck(id: 'deck-1', name: 'Japanese N5')),
      );

      expect(find.byType(MxBreadcrumb), findsNothing);
    });

    testWidgets('tapping an ancestor navigates to that deck', (tester) async {
      // Through the real router: the crumb calls `goNamed`, which needs a
      // GoRouter above it, and the assertion that matters is the location it
      // lands on rather than that a callback fired.
      final repository = FakeDeckRepository(
        deckList: (String? id) => Stream<DeckListSnapshot>.value(
          DeckListSnapshot(
            parent: fakeSubDeck(
              id: id ?? 'deck-1',
              name: 'Hiragana',
              parentId: 'branch',
            ),
            ancestors: fakePath(<String>['Japanese N5']),
            decks: const <DeckSummary>[],
            nextDueAt: null,
          ),
        ),
      );
      final router = await pumpDeckApp(
        tester,
        repository: repository,
        initialLocation: '/decks/deck-1',
      );

      await tester.tap(find.text('Japanese N5'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/decks/path-0',
      );
    });

    testWidgets('it is shown above an empty level too', (tester) async {
      // Where the level has nothing in it is exactly where "where am I" is
      // hardest to answer from what is on screen.
      await pumpLevel(
        tester,
        serving(
          fakeSubDeck(id: 'deck-1', name: 'Empty', parentId: 'branch'),
          ancestors: fakePath(<String>['Japanese N5', 'Kana']),
        ),
      );

      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(find.byType(MxBreadcrumb), findsOneWidget);
    });

    testWidgets('a full-depth path fits 320x568 at textScaler 2.0', (
      tester,
    ) async {
      // BR-55 caps the tree at ten, so nine ancestors is the worst real case.
      await pumpLevel(
        tester,
        serving(
          fakeSubDeck(id: 'deck-1', name: 'Level ten', parentId: 'branch'),
          ancestors: fakePath(<String>[
            for (var i = 1; i <= 9; i++) 'Level number $i',
          ]),
        ),
        surface: const Size(320, 568),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
