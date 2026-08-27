import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'package:memox/features/card/presentation/widgets/sections/card_trash_action_widget.dart';

import 'support/fake_card_repository.dart';

/// The editor in edit mode (UC-04 A1, A5): prefill from the loaded card, save
/// through `updateCard`, and the danger-zone delete.
void main() {
  /// The editor, mounted under a router.
  ///
  /// **A real `GoRouter`, not a bare `home:`.** Deleting a card navigates to
  /// the deck by name (BR-163: the last card leaves the deck `unset`, which has
  /// no card list to pop back to), so a harness without a router would make the
  /// delete path throw where production works. The stand-in deck screen is a
  /// marker widget — where the app *goes* is this file's business; what the
  /// deck then renders is `test/app/router/`'s.
  Future<GoRouter> pump(
    WidgetTester tester,
    FakeCardRepository repository, {
    String cardId = 'card-1',
  }) async {
    final router = GoRouter(
      initialLocation: '/decks/deck-1/editor',
      routes: <RouteBase>[
        GoRoute(
          path: '/decks/:deckId',
          name: RouteNames.deckDetail,
          builder: (context, state) =>
              const Scaffold(body: Text('deck detail')),
          // Nested, as in production: the editor sits under the deck, so a
          // save can pop back to something and a delete can navigate to it.
          routes: <RouteBase>[
            GoRoute(
              path: 'editor',
              builder: (context, state) =>
                  CardEditorScreen(deckId: 'deck-1', cardId: cardId),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cardRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          theme: buildLightTheme(),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    // Let the prefill future resolve.
    await tester.pumpAndSettle();

    return router;
  }

  testWidgets('edit mode prefills the loaded card and titles itself Edit', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card(
      'card-1',
      front: 'ephemeral',
      back: 'lasting a short time',
    );

    await pump(tester, repository);

    expect(find.text('Edit flashcard'), findsOneWidget);
    expect(find.text('ephemeral'), findsOneWidget);
    expect(find.text('lasting a short time'), findsOneWidget);
    // No save-and-add path in edit mode.
    expect(find.text('Save and add another'), findsNothing);
  });

  testWidgets('saving changes reaches updateCard with the edited text', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1', front: 'old');

    await pump(tester, repository);

    await tester.enterText(find.byType(TextField).first, 'new front');
    // The pump is load-bearing: `enterText` schedules a frame but does not
    // pump one, and `Save changes` only becomes pressable on the frame that
    // sees the form is dirty.
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(repository.updates.single.id, 'card-1');
    expect(repository.updates.single.front, 'new front');
  });

  testWidgets('a failed prefill shows the load-failed state, not the form', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.nextGetFailure = const DatabaseFailure(message: 'gone');

    await pump(tester, repository);

    expect(find.textContaining("couldn't be opened"), findsOneWidget);
    expect(find.text('Save changes'), findsNothing);
  });

  testWidgets('the flag toggle writes the flag and flips its icon', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');

    await pump(tester, repository);

    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pump();

    expect(repository.flagWrites.single, (id: 'card-1', isFlagged: true));
    expect(find.byIcon(Icons.flag), findsOneWidget);
  });

  testWidgets('a failed flag write is visible and leaves the icon unchanged', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');
    repository.nextFlagFailure = const DatabaseFailure(message: 'write failed');

    await pump(tester, repository);
    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pump();

    expect(repository.flagWrites, isEmpty);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    // The message names the flag rather than saying `Please try again.`: it
    // renders in the pinned subheader, at the opposite corner from the app-bar
    // action that caused it, where a generic sentence reads as a page error or
    // as the front field's.
    expect(find.textContaining('flag'), findsWidgets);
    expect(find.text('Please try again.'), findsNothing);
  });

  testWidgets('editing a card with a detail opens the details expanded', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository
        .card('card-1')
        .copyWith(example: 'a seeded example');

    await pump(tester, repository);

    // The detail is visible without tapping the toggle.
    expect(find.text('a seeded example'), findsOneWidget);
  });

  testWidgets('expanding details and saving carries the example through', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');

    await pump(tester, repository);

    // Collapsed by default: the toggle is present, the field is not. The label
    // names the three fields it reveals — `Add details` said nothing about what
    // a tap would open.
    const String toggle = 'Add example, hint & pronunciation';
    expect(find.text(toggle), findsOneWidget);
    await tester.ensureVisible(find.text(toggle));
    await tester.tap(find.text(toggle));
    await tester.pumpAndSettle();

    // The label is external now, so the field is found by the section heading
    // above it rather than by a floating label inside it.
    final Finder exampleField = find.byType(TextField).at(2);
    await tester.ensureVisible(exampleField);
    await tester.enterText(exampleField, 'a new example');
    // `enterText` schedules a frame but does not pump one, and Save only
    // becomes pressable on the frame that sees the form is dirty.
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(repository.updates.single.example, 'a new example');
  });

  testWidgets('the tag section renders the card tags as chips', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');

    await pump(tester, repository);

    repository.emitTags(
      <dynamic>[
        repository.tag('t1', name: 'noun'),
        repository.tag('t2', name: 'people'),
      ].cast(),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Chip, 'noun'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'people'), findsOneWidget);
    // The counter appears once tags exist.
    expect(find.text('2 / 10'), findsOneWidget);
  });

  testWidgets('opening the entry and submitting adds the tag', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');

    await pump(tester, repository);

    // Adding starts at the chip: the entry opens in place rather than sitting
    // under the strip as a permanent form.
    await tester.ensureVisible(find.text('Add tag'));
    await tester.tap(find.text('Add tag'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'verb');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(repository.tagAdds.single, (id: 'card-1', name: 'verb'));
  });

  testWidgets('a failed tag add is visible below the tag field', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');
    repository.nextTagFailure = const DatabaseFailure(message: 'write failed');

    await pump(tester, repository);
    // Adding starts at the chip now: the entry opens in place rather than
    // sitting under the strip as a permanent form.
    await tester.ensureVisible(find.text('Add tag'));
    await tester.tap(find.text('Add tag'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'verb');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(repository.tagAdds, isEmpty);
    expect(find.text('Please try again.'), findsOneWidget);
  });

  testWidgets('a failed tag removal is visible below the tag section', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');
    repository.nextRemoveTagFailure = const DatabaseFailure(
      message: 'write failed',
    );

    await pump(tester, repository);
    repository.emitTags(<dynamic>[repository.tag('t1', name: 'noun')].cast());
    await tester.pumpAndSettle();
    // The editor is a longer page than it was — context rows above the form,
    // a Trash card below it — so the strip has to be brought into view before
    // it can be tapped. Without this the tap silently misses.
    final Finder chipDelete = find.descendant(
      of: find.widgetWithText(Chip, 'noun'),
      matching: find.byIcon(Icons.cancel),
    );
    await tester.ensureVisible(chipDelete);
    await tester.pumpAndSettle();
    await tester.tap(chipDelete);
    await tester.pump();

    expect(repository.tagRemoves, isEmpty);
    expect(find.widgetWithText(Chip, 'noun'), findsOneWidget);
    expect(find.text('Please try again.'), findsOneWidget);
  });

  testWidgets('the Trash card confirms, then moves the card to Trash', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');

    await pump(tester, repository);

    // Two controls now say `Move to Trash` — the editor's card and the
    // confirmation's action — so each is found through the thing that owns it.
    final Finder editorAction = find.descendant(
      of: find.byType(CardTrashActionWidget),
      matching: find.text('Move to Trash'),
    );
    await tester.ensureVisible(editorAction);
    await tester.tap(editorAction);
    await tester.pumpAndSettle();

    // The confirmation is up, and nothing is deleted until it is confirmed.
    // Its title says Trash too: a dialog that said `Delete` would be the one
    // place in this flow claiming the card is gone (BR-256).
    expect(find.text('Move this card to Trash?'), findsOneWidget);
    expect(repository.deletes, isEmpty);

    // "Move", not "Delete": BR-256's "moved, not destroyed" is carried by
    // the title just asserted above, and the button dropped the destination
    // word so it stays one line at 393dp (owner, 2026-08-28). The bare verb
    // still must not read as destruction — which "Move" cannot.
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Move'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.deletes.single, 'card-1');
    // And it leaves through the deck, not by popping to a card list that an
    // `unset` deck no longer has (BR-163). Which screen the deck then shows —
    // list or deck detail — is the router's redirect to decide.
    expect(find.text('deck detail'), findsOneWidget);
  });
}
