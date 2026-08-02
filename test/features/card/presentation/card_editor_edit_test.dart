import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'support/fake_card_repository.dart';

/// The editor in edit mode (UC-04 A1, A5): prefill from the loaded card, save
/// through `updateCard`, and the danger-zone delete.
void main() {
  Future<void> pump(
    WidgetTester tester,
    FakeCardRepository repository, {
    String cardId = 'card-1',
  }) async {
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
          home: CardEditorScreen(deckId: 'deck-1', cardId: cardId),
        ),
      ),
    );
    // Let the prefill future resolve.
    await tester.pumpAndSettle();
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

    expect(find.byIcon(Icons.outlined_flag), findsOneWidget);

    await tester.tap(find.byIcon(Icons.outlined_flag));
    await tester.pump();

    expect(repository.flagWrites.single, (id: 'card-1', isFlagged: true));
    expect(find.byIcon(Icons.flag), findsOneWidget);
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

  testWidgets('the danger zone confirms, then deletes the card', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');

    await pump(tester, repository);

    await tester.tap(find.text('Delete card'));
    await tester.pumpAndSettle();

    // The confirmation is up, and nothing is deleted until it is confirmed.
    expect(find.text('Delete this card?'), findsOneWidget);
    expect(repository.deletes, isEmpty);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.deletes.single, 'card-1');
  });
}
