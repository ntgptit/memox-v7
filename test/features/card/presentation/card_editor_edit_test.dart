import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/failures/tag_validation_failure.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_tag_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

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
    // Save is disabled until the form is dirty, and `enterText` does not build
    // a frame — so the tap below would land on the button as it was before the
    // edit. The pump is what makes it the button the user would be looking at.
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(repository.updates.single.id, 'card-1');
    expect(repository.updates.single.front, 'new front');
  });

  testWidgets('save stays disabled until an edit makes the form dirty', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1', front: 'old');

    await pump(tester, repository);

    FilledButton save() =>
        tester.widget<FilledButton>(find.byType(FilledButton));

    // Opened, untouched: the primary is inert, because pressing it would write
    // the card back exactly as it is.
    expect(save().onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'new front');
    await tester.pump();
    expect(save().onPressed, isNotNull);

    // Typed back to what was loaded: dirty is a comparison, not a flag that
    // latches on the first keystroke.
    await tester.enterText(find.byType(TextField).first, 'old');
    await tester.pump();
    expect(save().onPressed, isNull);
  });

  testWidgets('closing a dirty editor asks before discarding, and stays on '
      'Keep editing', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1', front: 'old');

    await pump(tester, repository);
    await tester.enterText(find.byType(TextField).first, 'new front');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    // Still on the form, still holding what was typed.
    expect(find.text('Edit flashcard'), findsOneWidget);
    expect(find.text('new front'), findsOneWidget);
  });

  testWidgets('discarding leaves the editor', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1', front: 'old');

    await pump(tester, repository);
    await tester.enterText(find.byType(TextField).first, 'new front');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Edit flashcard'), findsNothing);
    expect(repository.updates, isEmpty);
  });

  testWidgets('closing an untouched editor leaves without asking', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');

    await pump(tester, repository);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Edit flashcard'), findsNothing);
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

    expect(find.byIcon(Icons.outlined_flag), findsOneWidget);

    await tester.tap(find.byIcon(Icons.outlined_flag));
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
    await tester.tap(find.byIcon(Icons.outlined_flag));
    await tester.pump();

    expect(repository.flagWrites, isEmpty);
    expect(find.byIcon(Icons.outlined_flag), findsOneWidget);
    expect(find.text('Please try again.'), findsOneWidget);
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
    // names the three fields it opens rather than saying "details" (M99.60).
    const toggle = 'Add example, hint, pronunciation';
    expect(find.text(toggle), findsOneWidget);
    await tester.ensureVisible(find.text(toggle));
    await tester.tap(find.text(toggle));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(TextField, 'Example'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Example'),
      'a new example',
    );
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

  testWidgets('submitting the tag field adds the tag', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');

    await pump(tester, repository);

    await tester.enterText(
      find.widgetWithText(TextField, 'Add tag').first,
      'verb',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(repository.tagAdds.single, (id: 'card-1', name: 'verb'));
  });

  testWidgets('the add button submits the typed tag, and is inert until one '
      'is typed', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');

    await pump(tester, repository);

    IconButton addButton() => tester.widget<IconButton>(
      find.descendant(
        of: find.byType(CardTagSectionWidget),
        matching: find.widgetWithIcon(IconButton, Icons.add),
      ),
    );

    // Nothing typed: the button is there to be seen, not to be pressed.
    expect(addButton().onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'Add tag').first,
      'verb',
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(repository.tagAdds.single, (id: 'card-1', name: 'verb'));
  });

  testWidgets('at ten tags the field is replaced by the limit line', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');

    await pump(tester, repository);
    repository.emitTags(
      <dynamic>[
        for (var i = 0; i < kMaxTagsPerCard; i++)
          repository.tag('t$i', name: 'tag$i'),
      ].cast(),
    );
    await tester.pumpAndSettle();

    // The rule is stated before anything is typed, not as an error afterwards.
    expect(find.widgetWithText(TextField, 'Add tag'), findsNothing);
    expect(find.textContaining('all 10 tags'), findsOneWidget);
  });

  testWidgets('a failed tag add is visible below the tag field', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');
    repository.nextTagFailure = const DatabaseFailure(message: 'write failed');

    await pump(tester, repository);
    await tester.enterText(
      find.widgetWithText(TextField, 'Add tag').first,
      'verb',
    );
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
    await tester.tap(
      find.descendant(
        of: find.widgetWithText(Chip, 'noun'),
        matching: find.byIcon(Icons.cancel),
      ),
    );
    await tester.pump();

    expect(repository.tagRemoves, isEmpty);
    expect(find.widgetWithText(Chip, 'noun'), findsOneWidget);
    expect(find.text('Please try again.'), findsOneWidget);
  });

  testWidgets('the danger zone confirms, then deletes the card', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');

    await pump(tester, repository);

    await tester.ensureVisible(find.text('Delete card'));
    await tester.tap(find.text('Delete card'));
    await tester.pumpAndSettle();

    // The confirmation is up, and nothing is deleted until it is confirmed.
    expect(find.text('Delete this card?'), findsOneWidget);
    expect(repository.deletes, isEmpty);

    // "Move to Trash", not "Delete": the confirm button says where the card
    // goes, because it goes somewhere it can come back from (BR-256).
    await tester.tap(find.text('Move to Trash'));
    await tester.pumpAndSettle();

    expect(repository.deletes.single, 'card-1');
    // And it leaves through the deck, not by popping to a card list that an
    // `unset` deck no longer has (BR-163). Which screen the deck then shows —
    // list or deck detail — is the router's redirect to decide.
    expect(find.text('deck detail'), findsOneWidget);
  });
}
