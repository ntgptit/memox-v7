import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

import 'support/it_harness.dart';
import 'support/it_robot.dart';

/// IT scenarios for the card lifecycle — `05-card-lifecycle.md`.
///
/// IT-CARD-009 is absent on purpose: it needs the `S-PROGRESS` fixture, which is
/// still unimplemented, so it stays `FIXTURE-BLOCKED` in the catalog rather than
/// being faked here.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ItHarness> start(WidgetTester tester) async {
    final harness = await ItHarness.open(tester);
    addTearDown(harness.dispose);
    await harness.launchApp();

    return harness;
  }

  /// `SETUP-CARD-EMPTY-TYPED`: a card deck that currently holds no cards.
  ///
  /// Built by creating a card and deleting it, because that is the only way a
  /// deck becomes card-typed *and* empty — emptying never resets the type
  /// (BR-67), which is exactly what makes this state reachable.
  Future<ItRobot> emptyCardDeck(ItHarness harness, WidgetTester tester) async {
    final robot = ItRobot(tester, harness);
    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.createSubDeck('Academic words');
    await robot.openDeck('Academic words');
    await robot.createCard('seed', 'hạt giống');
    await robot.deleteOpenCard('seed');

    return robot;
  }

  /// `SETUP-CARD-PLAIN`: the same deck holding C-001…C-003, no tags, no flags.
  Future<ItRobot> threeCards(ItHarness harness, WidgetTester tester) async {
    final robot = ItRobot(tester, harness);
    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.createSubDeck('Academic words');
    await robot.openDeck('Academic words');
    await robot.createCard('abandon', 'từ bỏ');
    await robot.createCard('benevolent', 'nhân từ');
    await robot.createCard('concise', 'ngắn gọn');

    return robot;
  }

  // SETUP-CARD-EMPTY-TYPED · CLEAN-RESET · UC-04 A3
  testWidgets('IT-CARD-001 an empty card deck offers the first card', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await emptyCardDeck(harness, tester);

    // Step 1: the deck names itself and shows the card empty state.
    expect(find.text('No cards yet'), findsWidgets);
    expect(find.textContaining('Academic words'), findsWidgets);

    // Step 2: the empty state's action opens the editor.
    await robot.tapText(ItText.cardListEmptyAction);
    expect(
      find.text('New flashcard'),
      findsWidgets,
      reason: 'the add action did not open the editor; ${robot.visibleText}',
    );
  });

  // SETUP-CARD-EMPTY-TYPED · CLEAN-RESET · UC-04, BR-07, BR-09
  testWidgets('IT-CARD-002 a card needs both sides and survives restart', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await emptyCardDeck(harness, tester);

    // Steps 1 and 2: both sides entered, saved, and the card is in the list.
    await robot.createCard('abandon', 'từ bỏ');
    await robot.scrollToText('abandon');
    expect(find.text('abandon'), findsWidgets);
    expect(find.text('từ bỏ'), findsWidgets);

    // Step 3: a brand-new card reads as New and due now (BR-09).
    expect(find.text('NEW'), findsWidgets);

    // Step 4: it outlives the app.
    await harness.restartApp();
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.openDeck('Academic words');
    await robot.scrollToText('abandon');
    expect(
      find.text('abandon'),
      findsWidgets,
      reason: 'the card did not survive restart; ${robot.visibleText}',
    );
  });

  // SETUP-CARD-EMPTY-TYPED · CLEAN-RESET · UC-04 E1, BR-07
  testWidgets('IT-CARD-003 both sides are validated', (tester) async {
    final harness = await start(tester);
    final robot = await emptyCardDeck(harness, tester);
    await robot.tapText(ItText.cardListEmptyAction);

    // Step 1: empty on both sides is refused, and the editor stays open.
    await robot.tapText(ItText.saveCard);
    expect(find.textContaining("Front can't be empty"), findsWidgets);
    expect(find.textContaining("Back can't be empty"), findsWidgets);

    // Step 2: whitespace counts as empty on the front.
    await robot.enterNthField(0, '   ');
    await robot.enterNthField(1, 'từ bỏ');
    await robot.tapText(ItText.saveCard);
    expect(
      find.textContaining("Front can't be empty"),
      findsWidgets,
      reason: 'whitespace front was accepted; ${robot.visibleText}',
    );

    // Step 3: and on the back, without losing the front.
    await robot.enterNthField(0, 'abandon');
    await robot.enterNthField(1, '   ');
    await robot.tapText(ItText.saveCard);
    expect(find.textContaining("Back can't be empty"), findsWidgets);

    // Step 4: valid on both sides creates exactly one card.
    await robot.enterNthField(1, 'từ bỏ');
    await robot.tapText(ItText.saveCard);
    await robot.scrollToText('abandon');
    expect(find.text('abandon'), findsOneWidget);
  });

  // SETUP-CARD-EMPTY-TYPED · CLEAN-RESET · UC-04, BR-08
  testWidgets('IT-CARD-004 front and back have different length limits', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await emptyCardDeck(harness, tester);
    await robot.tapText(ItText.cardListEmptyAction);

    // Step 1: 60 on the front and 240 on the back are both accepted.
    await robot.enterNthField(0, 'a' * 60);
    await robot.enterNthField(1, 'b' * 240);
    await robot.tapText(ItText.saveCard);
    await robot.scrollToText('a' * 60);
    expect(
      find.text('a' * 60),
      findsWidgets,
      reason: 'a 60/240 card was refused; ${robot.visibleText}',
    );

    // Steps 2 and 3: neither side stores more than its own limit. Read off what
    // the field holds, which covers both accepted outcomes — the extra
    // character refused outright, or an inline error keeping the form open.
    await robot.tapCreateAction(ItText.newCard);
    await robot.enterNthField(0, 'c' * 61);
    await robot.enterNthField(1, 'd' * 241);
    final fields = find.descendant(
      of: find.byType(MxTextField),
      matching: find.byType(TextField),
    );
    final front = tester.widget<TextField>(fields.at(0)).controller?.text ?? '';
    final back = tester.widget<TextField>(fields.at(1)).controller?.text ?? '';
    expect(
      front.length <= 60,
      isTrue,
      reason: 'front kept ${front.length} characters, limit is 60',
    );
    expect(
      back.length <= 240,
      isTrue,
      reason: 'back kept ${back.length} characters, limit is 240',
    );
  });

  // SETUP-CARD-EMPTY-TYPED · CLEAN-RESET · UC-04, BR-95
  testWidgets('IT-CARD-005 optional fields round-trip and can be cleared', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await emptyCardDeck(harness, tester);
    await robot.tapText(ItText.cardListEmptyAction);

    // Steps 1 and 2: the extras section holds example, hint and pronunciation.
    await robot.enterNthField(0, 'abandon');
    await robot.enterNthField(1, 'từ bỏ');
    await robot.revealOptionalFields();
    await robot.enterNthField(2, 'He abandoned the plan.');
    await robot.tapText(ItText.saveCard);

    // Step 3: reopening shows what was saved.
    await robot.scrollToText('abandon');
    await robot.tapText('abandon');
    await robot.revealOptionalFields();
    expect(
      find.text('He abandoned the plan.'),
      findsWidgets,
      reason: 'the example did not round-trip; ${robot.visibleText}',
    );

    // Step 4: clearing one optional field leaves the others alone.
    await robot.enterNthField(2, '');
    await robot.tapText('Save changes');
    await robot.scrollToText('abandon');
    await robot.tapText('abandon');
    await robot.revealOptionalFields();
    expect(find.text('He abandoned the plan.'), findsNothing);
    final fields = find.descendant(
      of: find.byType(MxTextField),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(fields.at(0)).controller?.text, 'abandon');
  });

  // SETUP-CARD-EMPTY-TYPED · CLEAN-RESET · BR-95
  testWidgets('IT-CARD-006 each optional field stops at 240', (tester) async {
    final harness = await start(tester);
    final robot = await emptyCardDeck(harness, tester);
    await robot.tapText(ItText.cardListEmptyAction);
    await robot.enterNthField(0, 'abandon');
    await robot.enterNthField(1, 'từ bỏ');
    await robot.revealOptionalFields();

    // Steps 1 and 2: 240 is accepted, 241 never reaches storage.
    await robot.enterNthField(2, 'e' * 241);
    final fields = find.descendant(
      of: find.byType(MxTextField),
      matching: find.byType(TextField),
    );
    final example =
        tester.widget<TextField>(fields.at(2)).controller?.text ?? '';
    expect(
      example.length <= 240,
      isTrue,
      reason: 'example kept ${example.length} characters, limit is 240',
    );

    // Step 3: back to valid, and the card saves with both sides intact.
    await robot.enterNthField(2, 'e' * 240);
    await robot.tapText(ItText.saveCard);
    await robot.scrollToText('abandon');
    expect(find.text('abandon'), findsWidgets);
    expect(find.text('từ bỏ'), findsWidgets);
  });

  // SETUP-CARD-EMPTY-TYPED · CLEAN-RESET · UC-04 A4
  testWidgets('IT-CARD-007 save-and-add keeps the editor open and empty', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await emptyCardDeck(harness, tester);
    await robot.tapText(ItText.cardListEmptyAction);

    // Steps 1 and 2: the card is saved but the editor stays, cleared.
    await robot.enterNthField(0, 'abandon');
    await robot.enterNthField(1, 'từ bỏ');
    await robot.scrollToText('Save and add another');
    await robot.tapText('Save and add another');
    final fields = find.descendant(
      of: find.byType(MxTextField),
      matching: find.byType(TextField),
    );
    expect(
      tester.widget<TextField>(fields.at(0)).controller?.text,
      isEmpty,
      reason: 'the form was not cleared for the next card',
    );

    // Steps 3 and 4: the second card saves normally and both are listed once.
    await robot.enterNthField(0, 'benevolent');
    await robot.enterNthField(1, 'nhân từ');
    await robot.tapText(ItText.saveCard);
    await robot.scrollToText('benevolent');
    expect(find.text('benevolent'), findsOneWidget);
    await robot.scrollToText('abandon');
    expect(find.text('abandon'), findsOneWidget);
  });

  // SETUP-CARD-BASIC · CLEAN-RESET · UC-04 A1, BR-10
  testWidgets('IT-CARD-008 editing a card keeps its place in the list', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await threeCards(harness, tester);

    // Step 1: the editor is prefilled.
    await robot.scrollToText('abandon');
    await robot.tapText('abandon');
    final fields = find.descendant(
      of: find.byType(MxTextField),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(fields.at(0)).controller?.text, 'abandon');

    // Step 2: the new meaning reaches the list.
    await robot.enterNthField(1, 'rời bỏ');
    await robot.tapText('Save changes');
    await robot.scrollToText('rời bỏ');
    expect(find.text('rời bỏ'), findsWidgets);

    // Step 3: editing does not promote the card to the top — `concise` was
    // created last and must still lead under the default newest-first sort.
    // Read from the top: after the scroll above, the first *built* tile is
    // whatever the recycler kept, not the first row of the list.
    await robot.scrollToTop();
    expect(
      robot.firstRowFront(),
      'concise',
      reason: 'the edited card jumped ahead of newer ones',
    );

    // Step 4: the edit outlives a restart.
    await harness.restartApp();
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.openDeck('Academic words');
    await robot.scrollToText('rời bỏ');
    expect(find.text('rời bỏ'), findsWidgets);
  });

  // SETUP-CARD-BASIC · CLEAN-RESET · UC-04 A2
  testWidgets('IT-CARD-010 deleting a card asks first', (tester) async {
    final harness = await start(tester);
    final robot = await threeCards(harness, tester);

    // Steps 1 and 2: cancelling the confirmation keeps the card.
    await robot.scrollToText('abandon');
    await robot.tapText('abandon');
    await robot.scrollToText('Delete card');
    await robot.tapText('Delete card');
    expect(find.text('Delete this card?'), findsWidgets);
    await robot.tapText(ItText.cancel);
    await robot.dismissSheet();
    await robot.scrollToText('abandon');
    expect(
      find.text('abandon'),
      findsWidgets,
      reason: 'a cancelled delete removed the card; ${robot.visibleText}',
    );

    // Steps 3 and 4: confirming removes it, and it stays removed.
    await robot.tapText('abandon');
    await robot.scrollToText('Delete card');
    await robot.tapText('Delete card');
    await robot.tapText(ItText.delete);
    expect(find.text('abandon'), findsNothing);

    await harness.restartApp();
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.openDeck('Academic words');
    expect(find.text('abandon'), findsNothing);
  });

  // SETUP-CARD-SINGLE · CLEAN-RESET · UC-04 A2, BR-67
  testWidgets('IT-CARD-011 deleting the last card keeps the deck card-typed', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);
    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.createSubDeck('Academic words');
    await robot.openDeck('Academic words');
    await robot.createCard('abandon', 'từ bỏ');

    // Step 1: the list falls back to the add-a-card empty state.
    await robot.deleteOpenCard('abandon');
    expect(find.text('No cards yet'), findsWidgets);

    // Step 2: the create action still leads to a card, never a sub-deck.
    await robot.tapText(ItText.cardListEmptyAction);
    expect(find.text('New flashcard'), findsWidgets);
    expect(
      find.text(ItText.newSubDeck),
      findsNothing,
      reason: 'an emptied card deck offered a sub-deck; ${robot.visibleText}',
    );
  });
}
