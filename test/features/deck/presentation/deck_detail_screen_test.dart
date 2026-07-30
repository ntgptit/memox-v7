import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/presentation/screens/deck_detail_screen.dart';
import 'package:memox/features/deck/presentation/widgets/deck_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// The deck detail screen's read states and its content-type action matrix
/// (UC-06 step 4, UC-08), plus the not-found path (UC-03 E1).
///
/// The write flows reached from the action menu live in
/// `deck_detail_actions_test.dart`.
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

    testWidgets('tapping retry actually re-reads the deck', (tester) async {
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

      await pumpDetail(tester, repository);
      final int readsBeforeRetry = repository.childDecksCalls.length;

      await tester.tap(find.text(english.retryAction));
      await tester.pump();

      expect(repository.childDecksCalls.length, greaterThan(readsBeforeRetry));
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
