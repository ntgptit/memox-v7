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
/// The create-action matrix lives in `deck_level_create_test.dart`, the write
/// flows in `deck_level_actions_test.dart`, and the breadcrumb in
/// `deck_path_test.dart`.
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

      // **In the app bar specifically.** The name is on screen twice now — the
      // title, and the breadcrumb's own last step — so a bare `findsOneWidget`
      // would fail for a reason that has nothing to do with the title, and a
      // `findsNWidgets(2)` would pass if the title vanished and the crumb grew a
      // second copy.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Japanese N5'),
        ),
        findsOneWidget,
      );
      expect(find.byType(DeckTileWidget), findsNWidgets(2));
      expect(find.text('Hiragana'), findsOneWidget);
    });

    testWidgets('Study appears only where something is due, and answers', (
      tester,
    ) async {
      // **The button is real before the feature is.** There is no review session
      // until M5, so it says so rather than swallowing the tap — the project
      // refuses enabled-looking controls that go nowhere, and a reply is what
      // separates this from one. The layout under review is then the real one.
      await pumpLevel(
        tester,
        serving(
          fakeRootDeck(id: 'deck-1', name: 'Japanese'),
          children: <DeckSummary>[
            fakeChildSummary(
              id: 'c1',
              name: 'Due',
              parentId: 'deck-1',
              totalCardCount: 40,
              dueCardCount: 5,
            ),
            fakeChildSummary(
              id: 'c2',
              name: 'Caught up',
              parentId: 'deck-1',
              totalCardCount: 40,
              learnedCardCount: 40,
            ),
          ],
        ),
      );

      // One deck has cards due; the other offers the figure in its place.
      expect(find.text(english.deckStudyAction), findsOneWidget);
      expect(find.text(english.deckLearnedPercentLabel(100)), findsOneWidget);

      await tester.tap(find.text(english.deckStudyAction));
      await tester.pumpAndSettle();

      expect(find.text(english.deckStudyComingSoonMessage), findsOneWidget);
    });

    testWidgets('a child shows the same four facts a root deck does', (
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
              learnedCardCount: 21,
            ),
          ],
        ),
      );

      expect(find.text('Hiragana'), findsOneWidget);
      expect(
        // `textContaining`, because the meta line is a `Text.rich` of spans
        // and `find.text` only matches a plain `Text`.
        find.textContaining(english.deckCardCountLabel(42)),
        findsOneWidget,
        reason: 'the card count',
      );
      expect(
        find.textContaining(english.deckDueCountLabel(7)),
        findsOneWidget,
        reason: 'the due count',
      );
      expect(
        find.textContaining(english.schedulerEightBoxShortLabel),
        findsOneWidget,
        reason: 'the resolved scheduler',
      );
      // **The fourth fact, added with BR-88.** Asserted by its formatted label
      // rather than by looking for the digits: `find.textContaining('42')` used
      // to be enough and stopped being so the moment a second line on the same
      // card mentioned the same total, which is exactly the ambiguity a bare
      // substring match hides.
      //
      // **Painted once, announced twice.** The level summary above the list
      // still writes the figure out; the card stopped, because a header saying
      // `21 of 42 learned` above a track of the same length is the same fact
      // twice and it cost 24px on every row. The card's copy moved into
      // `Semantics`, so a screen reader still hears both — which is what the
      // second expectation checks.
      expect(
        find.text(english.deckLearnedProgressLabel(21, 42)),
        findsOneWidget,
        reason: 'painted once, by the level summary',
      );
      // On the card's own node, not as a separate one: `MxCard` announces the
      // whole card as one button, so everything inside it merges into that
      // label. That was already true of the header when it was painted — what
      // changed is only that the words are no longer also drawn.
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byType(DeckTileWidget)).label,
        contains(english.deckLearnedProgressLabel(21, 42)),
        reason: 'the card announces what it stopped painting',
      );
      handle.dispose();
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
    const compact = Size(360, 640);

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
}
