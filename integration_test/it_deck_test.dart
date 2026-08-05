import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:integration_test/integration_test.dart';

import 'support/it_harness.dart';
import 'support/it_robot.dart';

/// IT scenarios for the root deck lifecycle — `02-root-deck-lifecycle.md`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ItHarness> start(WidgetTester tester) async {
    final harness = await ItHarness.open(tester);
    addTearDown(harness.dispose);
    await harness.launchApp();

    return harness;
  }

  // SETUP-EMPTY · CLEAN-RESET · UC-02, BR-11
  testWidgets('IT-DECK-001 create a root deck using Eight Box', (tester) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    // Step 1 and 2: the form offers a name and a study mode, and says the mode
    // locks after the first review.
    await robot.tapCreateAction(ItText.newDeck);
    expect(find.text(ItText.eightBox), findsWidgets);
    expect(
      find.textContaining('locks'),
      findsWidgets,
      reason: 'no lock notice on the form; screen ${robot.visibleText}',
    );

    // Step 3: the deck appears with its name and mode.
    await robot.enterNthField(0, 'Giao tiếp hằng ngày');
    await robot.tapText(ItText.eightBox);
    await robot.tapText(ItText.createSubmit);
    expect(find.text('Giao tiếp hằng ngày'), findsWidgets);

    // Step 4: it survives a restart.
    await harness.restartApp();
    expect(
      find.text('Giao tiếp hằng ngày'),
      findsWidgets,
      reason: 'deck did not survive restart; screen ${robot.visibleText}',
    );
  });

  // SETUP-EMPTY · CLEAN-RESET · UC-02, BR-01, BR-11
  testWidgets('IT-DECK-003 required data is enforced before creating', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    await robot.tapCreateAction(ItText.newDeck);

    // Step 1: an empty name is refused at the field, and no deck is created.
    await robot.tapText(ItText.eightBox);
    await robot.tapText(ItText.createSubmit);
    expect(
      find.text('Enter a name.'),
      findsWidgets,
      reason: 'blank name was accepted; screen ${robot.visibleText}',
    );

    // Step 2: whitespace counts as empty.
    await robot.enterNthField(0, '   ');
    await robot.tapText(ItText.createSubmit);
    expect(
      find.text('Enter a name.'),
      findsWidgets,
      reason: 'whitespace name was accepted; screen ${robot.visibleText}',
    );

    // Step 4: with both parts valid the deck is created exactly once.
    await robot.enterNthField(0, 'Giao tiếp hằng ngày');
    await robot.tapText(ItText.createSubmit);
    expect(find.text('Giao tiếp hằng ngày'), findsOneWidget);
  });

  // SETUP-D-SM2 · CLEAN-RESET · UC-02, BR-02
  testWidgets('IT-DECK-002 a second root may reuse a name, with SM-2', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    await robot.createRootDeck('IELTS 2026', scheduler: ItText.eightBox);

    // Step 1 and 2: the same name is accepted, with the other study mode.
    await robot.createRootDeck('IELTS 2026', scheduler: ItText.sm2);

    // Step 3: two decks now carry that name — the first was not overwritten.
    expect(
      find.text('IELTS 2026'),
      findsNWidgets(2),
      reason: 'duplicate name did not produce two decks; ${robot.visibleText}',
    );
    expect(
      find.textContaining('SM-2'),
      findsWidgets,
      reason: 'the SM-2 deck does not show its mode; ${robot.visibleText}',
    );
  });

  // SETUP-EMPTY · CLEAN-RESET · UC-02, BR-01
  testWidgets('IT-DECK-004 the name limit holds and input survives an error', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    // Step 1: exactly 200 characters is allowed.
    final atLimit = 'a' * 200;
    await robot.createRootDeck(atLimit, scheduler: ItText.eightBox);
    expect(
      find.text(atLimit),
      findsWidgets,
      reason: 'a 200-character name was refused; ${robot.visibleText}',
    );

    // Step 2: a 201st character must not reach storage. The scenario accepts
    // either outcome — the field refuses the extra character, or the form stays
    // open with an inline error — so both are read off one observation: what
    // the field is holding after the attempt.
    await robot.tapCreateAction(ItText.newDeck);
    await robot.enterNthField(0, 'b' * 201);
    final field = tester.widget<TextField>(
      find
          .descendant(
            of: find.byType(MxTextField),
            matching: find.byType(TextField),
          )
          .first,
    );
    final typed = field.controller?.text ?? '';
    expect(
      typed.length <= 200 || find.textContaining('200').evaluate().isNotEmpty,
      isTrue,
      reason: 'the field kept ${typed.length} characters with no error shown',
    );
  });

  // SETUP-EMPTY · CLEAN-RESET · UC-02 A1
  testWidgets('IT-DECK-005 discarding a form asks only when there is input', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    // Step 1: closing an untouched form asks nothing and creates nothing.
    await robot.tapCreateAction(ItText.newDeck);
    await robot.tapText(ItText.cancel);
    expect(
      find.text('Discard this deck?'),
      findsNothing,
      reason: 'an untouched form asked to discard; ${robot.visibleText}',
    );
    expect(find.text(ItText.decksEmpty), findsOneWidget);

    // Step 2: with something typed, closing asks first.
    await robot.tapCreateAction(ItText.newDeck);
    await robot.enterNthField(0, 'Giao tiếp hằng ngày');
    await robot.tapText(ItText.cancel);
    expect(
      find.text('Discard this deck?'),
      findsOneWidget,
      reason: 'a filled form closed without asking; ${robot.visibleText}',
    );

    // Step 3: choosing to keep editing returns the text intact.
    await robot.tapText(ItText.cancel);
    expect(
      find.text('Giao tiếp hằng ngày'),
      findsWidgets,
      reason: 'keeping the form lost what was typed; ${robot.visibleText}',
    );

    // Step 4: discarding closes the form and creates no deck.
    await robot.tapText(ItText.cancel);
    await robot.tapText('Discard');
    expect(find.text(ItText.decksEmpty), findsOneWidget);
  });

  // SETUP-D-EB · CLEAN-RESET · UC-03, BR-01
  testWidgets('IT-DECK-006 rename a root deck', (tester) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );

    // Step 1: the rename form opens on the current name.
    await robot.openDeckActions('Giao tiếp hằng ngày');
    await robot.tapText(ItText.rename);

    // Step 2: the new name appears in the list straight away.
    await robot.enterNthField(0, 'Giao tiếp công việc');
    await robot.tapText('Save');
    expect(
      find.text('Giao tiếp công việc'),
      findsWidgets,
      reason: 'rename did not reach the list; ${robot.visibleText}',
    );
    expect(find.text('Giao tiếp hằng ngày'), findsNothing);

    // Step 4: the new name survives a restart.
    await harness.restartApp();
    expect(
      find.text('Giao tiếp công việc'),
      findsWidgets,
      reason: 'rename did not survive restart; ${robot.visibleText}',
    );
  });

  // SETUP-TREE-CARD · CLEAN-RESET · UC-03 A4, BR-04
  testWidgets('IT-DECK-007 cancelling delete keeps the whole tree', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.createSubDeck('Vocabulary');
    await harness.pressBack();

    // Step 1: the confirmation names the deck and what would be lost.
    await robot.openDeckActions('Giao tiếp hằng ngày');
    await robot.tapText(ItText.delete);
    expect(
      find.textContaining('Giao tiếp hằng ngày'),
      findsWidgets,
      reason: 'confirmation did not name the deck; ${robot.visibleText}',
    );

    // Step 2 and 3: cancelling leaves the deck and its child untouched.
    await robot.tapText(ItText.cancel);
    expect(find.text('Giao tiếp hằng ngày'), findsWidgets);

    await robot.openDeck('Giao tiếp hằng ngày');
    expect(
      find.text('Vocabulary'),
      findsWidgets,
      reason: 'the sub-deck did not survive a cancelled delete',
    );
  });

  // SETUP-TREE-CARD · CLEAN-RESET · UC-03, BR-03, BR-04
  testWidgets('IT-DECK-008 confirming delete removes the whole tree', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.createSubDeck('Vocabulary');
    await harness.pressBack();

    // Step 1 and 2: confirming returns to the root list without the deck.
    await robot.openDeckActions('Giao tiếp hằng ngày');
    await robot.tapText(ItText.delete);
    await robot.tapText(ItText.delete);
    expect(
      find.text('Giao tiếp hằng ngày'),
      findsNothing,
      reason: 'deck survived a confirmed delete; ${robot.visibleText}',
    );

    // Step 3: it does not come back after a restart.
    await harness.restartApp();
    expect(find.text('Giao tiếp hằng ngày'), findsNothing);
    expect(
      find.text(ItText.decksEmpty),
      findsOneWidget,
      reason: 'the root list is not empty after deleting its only deck',
    );

    // Step 4: no descendant of the deleted tree is findable by search.
    //
    // Asserted through the no-match state rather than `find.text('Vocabulary')`,
    // which the empty-state copy itself contains — it quotes the query back, so
    // that finder matches whether or not the deck survived.
    await robot.enterSearch('Vocabulary');
    expect(
      find.textContaining('No decks match'),
      findsWidgets,
      reason: 'a descendant outlived its deleted root; ${robot.visibleText}',
    );
  });
}
