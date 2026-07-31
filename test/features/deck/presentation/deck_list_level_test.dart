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
import 'package:memox/features/deck/presentation/widgets/deck_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// `DeckListScreen` with a parent — the read states inside a deck (UC-06 step 4)
/// and the not-found path (UC-03 E1).
///
/// Same screen as `deck_list_screen_test.dart` pumps, one argument different.
/// The two files are split by the *level* they exercise, not by widget, and that
/// is the whole claim of the unification: everything below is the level-dependent
/// behaviour, and it is a short list.
///
/// The create-action matrix lives in `deck_level_create_test.dart`; the write
/// flows reached from the action menu in `deck_level_actions_test.dart`.
void main() {
  final english = AppLocalizationsEn();

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

  group('read states', () {
    testWidgets('loading is announced to a screen reader', (tester) async {
      await pumpLevel(tester, FakeDeckRepository.pending());

      expect(
        tester
            .widget<MxLoadingState>(find.byType(MxLoadingState))
            .semanticsLabel,
        english.decksLoadingLabel,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a deck deleted elsewhere shows not-found, not an error', (
      tester,
    ) async {
      // UC-03 E1. Nothing the user did was wrong, so this gets a way back rather
      // than a retry button that would fail forever.
      await pumpLevel(tester, FakeDeckRepository.missingDeck());

      expect(find.text(english.deckDetailNotFoundTitle), findsOneWidget);
      expect(find.text(english.deckBackToDecksAction), findsOneWidget);
      expect(find.text(english.retryAction), findsNothing);
    });

    testWidgets('a read failure shows a retryable error with no SQL in it', (
      tester,
    ) async {
      await pumpLevel(
        tester,
        FakeDeckRepository.failing(
          const DatabaseFailure(message: 'SqliteException(11): malformed'),
        ),
      );

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.decksLoadErrorTitle), findsOneWidget);
      expect(find.text(english.retryAction), findsOneWidget);
      expect(find.textContaining('Sqlite'), findsNothing);
    });

    testWidgets('tapping retry actually re-reads the level', (tester) async {
      // The button existing was asserted above; that it *does* something was
      // not. Worth its own case because the wiring is easy to get subtly wrong:
      // this screen used to reach the container through
      // `ProviderScope.containerOf` from inside a `StatelessWidget` that had no
      // `ref`, while the sibling list screen used `ref.invalidate`. That left two
      // idioms doing one job, which is the kind of thing a clone copies at
      // random.
      final repository = FakeDeckRepository.failing(
        const DatabaseFailure(message: 'unavailable'),
      );

      await pumpLevel(tester, repository);
      final int readsBeforeRetry = repository.deckListCallCount;

      await tester.tap(find.text(english.retryAction));
      await tester.pump();

      expect(repository.deckListCallCount, greaterThan(readsBeforeRetry));
    });

    testWidgets('the level is read for the deck the route named', (
      tester,
    ) async {
      // The family argument, end to end. A screen that dropped it would render
      // the root list under the deck's title and nobody would notice from the
      // pixels.
      final repository = serving(fakeRootDeck(id: 'deck-9', name: 'Japanese'));

      await pumpLevel(tester, repository, deckId: 'deck-9');

      expect(repository.deckListParents, <String?>['deck-9']);
    });

    testWidgets('children are listed and the title is the deck name', (
      tester,
    ) async {
      final deck = fakeRootDeck(id: 'deck-1', name: 'Japanese N5');
      final children = <DeckSummary>[
        fakeChildSummary(id: 'c1', name: 'Hiragana', parentId: 'deck-1'),
        fakeChildSummary(id: 'c2', name: 'Katakana', parentId: 'deck-1'),
      ];

      await pumpLevel(tester, serving(deck, children: children));

      expect(find.text('Japanese N5'), findsOneWidget);
      expect(find.byType(DeckTileWidget), findsNWidgets(2));
      expect(find.text('Hiragana'), findsOneWidget);
    });

    testWidgets('a child shows the same three facts a root deck does', (
      tester,
    ) async {
      // The reason the recursive aggregate exists. Before it, a sub-deck row was
      // a name and nothing else — not a design choice, just what the old query
      // returned. If this ever regresses, the two levels have drifted apart
      // again.
      await pumpLevel(
        tester,
        serving(
          fakeRootDeck(id: 'deck-1', name: 'Japanese'),
          children: <DeckSummary>[
            fakeChildSummary(
              id: 'c1',
              name: 'Hiragana',
              parentId: 'deck-1',
              totalCardCount: 42,
              dueCardCount: 7,
            ),
          ],
        ),
      );

      expect(find.text('Hiragana'), findsOneWidget);
      expect(find.textContaining('42'), findsOneWidget);
      expect(find.textContaining('7'), findsOneWidget);
      expect(find.text(english.schedulerEightBoxLabel), findsOneWidget);
    });

    testWidgets('a later emission updates the child list', (tester) async {
      final controller = StreamController<DeckListSnapshot>();
      addTearDown(controller.close);
      final deck = fakeRootDeck(id: 'deck-1', name: 'Japanese');

      await pumpLevel(
        tester,
        FakeDeckRepository(deckList: (_) => controller.stream),
      );

      controller.add(
        DeckListSnapshot(
          ancestors: const <DeckPathSegment>[],
          parent: deck,
          decks: const <DeckSummary>[],
          nextDueAt: null,
        ),
      );
      await tester.pump();
      expect(find.byType(MxEmptyState), findsOneWidget);

      controller.add(
        DeckListSnapshot(
          ancestors: const <DeckPathSegment>[],
          parent: deck,
          decks: <DeckSummary>[
            fakeChildSummary(id: 'c1', name: 'Hiragana', parentId: 'deck-1'),
          ],
          nextDueAt: null,
        ),
      );
      await tester.pump();

      expect(find.byType(DeckTileWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('responsive and accessibility', () {
    const compact = Size(320, 568);

    testWidgets('a long child list fits 320x568 at textScaler 2.0', (
      tester,
    ) async {
      await pumpLevel(
        tester,
        serving(
          fakeRootDeck(id: 'deck-1', name: 'Root'),
          children: <DeckSummary>[
            for (var i = 0; i < 20; i++)
              fakeChildSummary(
                id: 'c$i',
                name: 'Child number $i',
                parentId: 'deck-1',
              ),
          ],
        ),
        surface: compact,
        textScale: 2,
      );

      expect(find.byType(DeckTileWidget), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the unset empty state fits 320x568 at textScaler 2.0', (
      tester,
    ) async {
      await pumpLevel(
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
        await pumpLevel(
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

  group('the path back up', () {
    testWidgets('a deck with ancestors shows them, current step last', (
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
      expect(crumb.items.map((MxBreadcrumbItem i) => i.label), <String>[
        'Japanese N5',
        'Kana',
        'Hiragana',
      ]);
      // The last step is where the user already is, so it goes nowhere.
      expect(crumb.items.last.onTap, isNull);
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
