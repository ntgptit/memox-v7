import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_state_distribution_model.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/controllers/card_list_window_controller.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/widgets/items/card_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import 'support/fake_card_repository.dart';

/// The card list screen through its four states, and the load-more window
/// (UC-04 W1, W1b).
void main() {
  Future<void> pump(WidgetTester tester, FakeCardRepository repository) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cardRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CardListScreen(deckId: 'deck-1'),
        ),
      ),
    );
  }

  testWidgets('a spinner shows before the first emission', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);

    await pump(tester, repository);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('an empty deck shows the empty state with an add action', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(<dynamic>[].cast());
    repository.emitCount(0);
    await tester.pump();

    expect(find.text('No cards yet'), findsOneWidget);
    expect(find.text('Add card'), findsOneWidget);
  });

  testWidgets('a loaded deck lists its cards and the showing line', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(
      <dynamic>[
        repository.listItem('c1', front: 'ephemeral'),
        repository.listItem('c2', front: 'ubiquitous'),
      ].cast(),
    );
    repository.emitCount(214);
    await tester.pump();

    expect(find.text('ephemeral'), findsOneWidget);
    expect(find.text('ubiquitous'), findsOneWidget);
    // The count is the deck's total, not the window's length.
    expect(find.text('Showing 2 of 214'), findsOneWidget);
  });

  testWidgets(
    'a search that matches nothing names the term, with no filter action',
    (tester) async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      await pump(tester, repository);

      repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
      repository.emitCount(1);
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'zzz-no-match');
      // The search re-subscribes the list; the fake's stream stays open, so
      // the new frame has to be pushed by hand rather than awaited.
      repository.emitItems(<dynamic>[].cast());
      repository.emitCount(0);
      await tester.pump();

      expect(find.text('No cards match “zzz-no-match”'), findsOneWidget);
      expect(
        find.text('Try a different word, or clear the search.'),
        findsOneWidget,
      );
      // Unlike the tag-filtered face, a search dead end has nowhere to route
      // a click to — the search field itself is the way out.
      expect(find.text('Add card'), findsNothing);
    },
  );

  testWidgets(
    'a state pill that matches nothing says so, with no filter action (D3)',
    (tester) async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      repository.filterCounts[CardListFilter.isNew] = 0;
      await pump(tester, repository);

      repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
      repository.emitCount(1);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(MxPillButton, 'New'));
      // Switching filter re-subscribes the list — that resubscribe needs its
      // own pump before the stream has a live listener again, or an event
      // pushed straight after the tap is broadcast to no one.
      await tester.pump();
      repository.emitItems(<dynamic>[].cast());
      await tester.pump();

      expect(find.text('No cards match'), findsOneWidget);
      expect(find.text('Try another filter, or add a card.'), findsOneWidget);
      // A state pill always has `All` beside it, so this face carries no
      // action of its own — only the tag-filtered face does (UC-18 A7).
      expect(find.text('Clear tag filter'), findsNothing);
    },
  );

  testWidgets(
    'a flagged card shows the flag indicator, an unflagged one does not',
    (tester) async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      await pump(tester, repository);

      repository.emitItems(
        <dynamic>[
          repository.listItem('c1', front: 'marked', isFlagged: true),
          repository.listItem('c2', front: 'plain'),
        ].cast(),
      );
      repository.emitCount(2);
      await tester.pump();

      // One flag icon **among the rows** — the Flagged filter pill above them
      // carries the same glyph now, so an unscoped finder counts two and the
      // assertion stops being about the row at all.
      expect(
        find.descendant(
          of: find.byType(CardTileWidget),
          matching: find.byIcon(Icons.flag),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('each row shows its state label (D5, BR-90/91/88)', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(
      <dynamic>[
        repository.listItem('c1', front: 'fresh'),
        repository.listItem('c2', front: 'done', state: CardState.mastered),
      ].cast(),
    );
    repository.emitCount(2);
    await tester.pump();

    // Uppercased on the row, like the reference and the deck list's labels.
    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('MASTERED'), findsOneWidget);
  });

  testWidgets('the header shows the deck name and its breadcrumb (W1)', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.deckContextToShow = const DeckContextModel(
      deckName: 'Phrasal verbs',
      ancestors: <DeckBreadcrumbSegment>[
        DeckBreadcrumbSegment(id: 'english', name: 'English'),
      ],
    );
    await pump(tester, repository);

    repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
    repository.emitCount(1);
    await tester.pumpAndSettle();

    // The app-bar title is the deck's name, not the generic label.
    expect(find.widgetWithText(AppBar, 'Phrasal verbs'), findsOneWidget);
    // The breadcrumb names the ancestor and the root step above it — the
    // root reads "All decks" since the Library redesign dropped the
    // technical word (owner mockup, 2026-08-20).
    expect(find.text('English'), findsOneWidget);
    expect(find.text('All decks'), findsOneWidget);
  });

  testWidgets('the progress panel shows the mastered percentage (D5)', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.distributionToShow = const CardStateDistributionModel(
      total: 100,
      isNew: 10,
      beginning: 8,
      reviewing: 20,
      mastered: 62,
    );
    await pump(tester, repository);

    repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
    repository.emitCount(100);
    await tester.pumpAndSettle();

    expect(find.text('62%'), findsOneWidget);
    expect(find.text('62 of 100 mastered'), findsOneWidget);
    // The legend names each band with its count.
    expect(find.text('Reviewing 20'), findsOneWidget);
  });

  testWidgets('selecting a pill re-reads the list with that filter (D3)', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.filterCounts[CardListFilter.isNew] = 4;
    await pump(tester, repository);

    repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
    repository.emitCount(10);
    await tester.pumpAndSettle();

    // The visible label carries no count — the row stopped fitting once every
    // pill took an icon, so the number moved to the semantic label. That it is
    // still announced is asserted just below.
    expect(find.widgetWithText(MxPillButton, 'New'), findsOneWidget);
    expect(
      tester
          .widget<MxPillButton>(find.widgetWithText(MxPillButton, 'New'))
          .semanticLabel,
      'New, 4 cards',
    );
    await tester.tap(find.widgetWithText(MxPillButton, 'New'));
    // A plain pump, not settle: switching filter re-subscribes the list, which
    // spins until the fake re-emits, and pumpAndSettle would wait on the spinner.
    await tester.pump();

    expect(repository.requestedFilters, contains(CardListFilter.isNew));
  });

  testWidgets('a row shows its tag names as chips (BR-93)', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(
      <dynamic>[
        repository.listItem(
          'c1',
          front: 'tagged',
          tagNames: <String>['noun', 'people'],
        ),
      ].cast(),
    );
    repository.emitCount(1);
    await tester.pump();

    expect(find.text('noun'), findsOneWidget);
    expect(find.text('people'), findsOneWidget);
  });

  testWidgets('a card whose due date has passed shows the now badge', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(
      <dynamic>[
        repository.listItem(
          'c1',
          state: CardState.beginning,
          // Well behind any clock the screen could read — the row is comparing
          // against the composition root's `now`, not a value this test owns.
          dueAt: DateTime.utc(2020),
        ),
      ].cast(),
    );
    repository.emitCount(1);
    await tester.pump();

    expect(find.text('now'), findsOneWidget);
  });

  testWidgets('a card that has never been scheduled shows no due badge', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    // No `dueAt`: BR-22 would hand this card to a session, but nothing has
    // scheduled it, so "when is it next due" has no answer to draw. The row says
    // `NEW` instead — and used to say `now` beside that, which read as a card
    // the learner had never opened having come back around.
    repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
    repository.emitCount(1);
    await tester.pump();

    expect(find.text('now'), findsNothing);
    expect(find.text('NEW'), findsOneWidget);
  });

  testWidgets('the tail offers load-more while rows remain', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
    repository.emitCount(120);
    await tester.pump();

    expect(find.text('Load 50 more'), findsOneWidget);
  });

  testWidgets('the tail says all shown when the window covers the deck', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
    repository.emitCount(1);
    await tester.pump();

    expect(find.text('Load 50 more'), findsNothing);
    expect(find.textContaining('shown'), findsOneWidget);
  });

  testWidgets('tapping load-more grows the requested window', (tester) async {
    // The behaviour C2 rests on: the window re-reads at a larger limit, and the
    // repository is asked for that larger limit.
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
    repository.emitCount(120);
    await tester.pump();

    await tester.tap(find.text('Load 50 more'));
    await tester.pump();

    // First subscription at the initial window, second at one step larger.
    expect(repository.requestedLimits, <int>[
      kCardWindowSize,
      kCardWindowSize * 2,
    ]);
  });

  testWidgets('a read failure offers a retry that re-subscribes both reads', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitError(StateError('boom'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.textContaining("couldn't be loaded"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Measured as a delta, not as a total. The screen already subscribes to the
    // deck total twice — once for the showing line, once for the All pill — so
    // an absolute count asserts how many reads the screen happens to have rather
    // than what retry did, and breaks on the next read that gets added.
    final countSubscriptionsBefore = repository.cardCountWatchCount;

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(repository.requestedLimits, <int>[kCardWindowSize, kCardWindowSize]);
    expect(
      repository.cardCountWatchCount,
      countSubscriptionsBefore + 1,
      reason: 'retry re-subscribed the total beside the list',
    );
  });
}
