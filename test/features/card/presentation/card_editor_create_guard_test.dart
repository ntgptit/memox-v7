import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_create_action_bar_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import 'support/card_editor_harness.dart';
import 'support/fake_card_repository.dart';

/// Create's unsaved-work guard (SC-C4-02).
///
/// **The mirror of `card_editor_concept_test.dart`'s "one way out" group, on
/// the mode that did not have one.** Create was the single form route in the
/// app with no `PopScope` and no discard confirm: the ✕ and the Android back
/// gesture both dropped a fully typed card without a word, on a screen that
/// autofocuses its first field — so the user is typing from the first frame.
/// These are edit's assertions with edit's copy swapped for create's, because
/// the claim being pinned is that the two modes ask the *same question*, not
/// that create has some guard of its own.
void main() {
  final english = AppLocalizationsEn();

  FakeCardRepository seed() {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);

    return repository;
  }

  Future<void> pumpCreate(WidgetTester tester) =>
      pumpCardEditor(tester, seed(), cardId: null);

  Future<void> typeFront(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, '감사합니다');
    await tester.pump();
  }

  Finder discardTitle() => find.text(english.cardEditorDiscardTitle);

  testWidgets('a pristine create form leaves with no question asked', (
    tester,
  ) async {
    await pumpCreate(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(discardTitle(), findsNothing);
    expect(find.text('deck detail'), findsOneWidget);
  });

  testWidgets('the ✕ and the system gesture ask the same question', (
    tester,
  ) async {
    await pumpCreate(tester);
    await typeFront(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(discardTitle(), findsOneWidget);
    await tester.tap(find.text(english.cardEditorDiscardCancel));
    await tester.pumpAndSettle();

    await pressSystemBack(tester);
    expect(discardTitle(), findsOneWidget);
    // Create's own sentence: nothing about this card is written yet, so edit's
    // reassurance about tags and the flag would name things that do not exist.
    expect(find.text(english.cardCreateDiscardMessage), findsOneWidget);
    expect(find.text(english.cardEditorDiscardMessage), findsNothing);
  });

  testWidgets('Keep editing leaves the draft exactly as it was', (
    tester,
  ) async {
    await pumpCreate(tester);
    await tester.enterText(find.byType(TextField).first, 'half typed');
    await tester.pump();

    await pressSystemBack(tester);
    await tester.tap(find.text(english.cardEditorDiscardCancel));
    await tester.pumpAndSettle();

    expect(find.text('half typed'), findsOneWidget);
    expect(find.text('deck detail'), findsNothing);
  });

  testWidgets('Discard is the only thing that leaves', (tester) async {
    await pumpCreate(tester);
    await typeFront(tester);

    await pressSystemBack(tester);
    await tester.tap(find.text(english.cardEditorDiscardConfirm));
    await tester.pumpAndSettle();

    expect(find.text('deck detail'), findsOneWidget);
  });

  testWidgets('back twice in a row opens one dialog, not two', (tester) async {
    await pumpCreate(tester);
    await typeFront(tester);

    await pressSystemBackTwice(tester);

    expect(discardTitle(), findsOneWidget);
  });

  testWidgets('typing a word and deleting it lands back on pristine', (
    tester,
  ) async {
    await pumpCreate(tester);
    await typeFront(tester);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();

    // The guard is a snapshot comparison against the empty draft, not a
    // "has been edited" flag — which is why an emptied form is pristine again
    // rather than permanently dirty.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(discardTitle(), findsNothing);
    expect(find.text('deck detail'), findsOneWidget);
  });

  testWidgets('a successful save closes without asking to discard it', (
    tester,
  ) async {
    await pumpCreate(tester);
    await tester.enterText(find.byType(TextField).first, '감사합니다');
    await tester.enterText(find.byType(TextField).at(1), 'thank you');
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(CardCreateActionBarWidget),
        matching: find.widgetWithText(MxActionButton, english.cardEditorSave),
      ),
    );
    await tester.pumpAndSettle();

    // The form is still full of the text that was just written, so the guard
    // would have something to ask about — and must not. The screen leaves
    // through `Navigator.pop`, the deliberate exit `PopScope` does not
    // intercept, rather than through the gesture path.
    expect(discardTitle(), findsNothing);
    expect(find.text('deck detail'), findsOneWidget);
  });

  testWidgets('save-and-add-another leaves the next card pristine', (
    tester,
  ) async {
    await pumpCreate(tester);
    await tester.enterText(find.byType(TextField).first, '감사합니다');
    await tester.enterText(find.byType(TextField).at(1), 'thank you');
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(CardCreateActionBarWidget),
        matching: find.widgetWithText(
          MxActionButton,
          english.cardEditorSaveAndAdd,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The disposition clears the controllers, and cleared *is* the baseline —
    // so the guard costs nothing here rather than asking the user to discard a
    // card they just saved.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(discardTitle(), findsNothing);
    expect(find.text('deck detail'), findsOneWidget);
  });
}
