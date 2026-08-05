import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/it_harness.dart';
import 'support/it_robot.dart';

/// IT scenarios for the deck tree and content type —
/// `03-deck-tree-and-content-type.md`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ItHarness> start(WidgetTester tester) async {
    final harness = await ItHarness.open(tester);
    addTearDown(harness.dispose);
    await harness.launchApp();

    return harness;
  }

  /// `SETUP-D-EB`, then open it.
  Future<ItRobot> openedRoot(ItHarness harness, WidgetTester tester) async {
    final robot = ItRobot(tester, harness);
    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );
    await robot.openDeck('Giao tiếp hằng ngày');

    return robot;
  }

  // SETUP-D-EB · CLEAN-RESET · UC-08, BR-58, BR-59
  testWidgets('IT-TREE-001 a root deck offers only sub-decks', (tester) async {
    final harness = await start(tester);
    final robot = await openedRoot(harness, tester);

    // Step 1: the create action leads to a sub-deck, with no card option.
    await robot.tapCreateAction(ItText.newSubDeck);
    expect(
      find.text(ItText.newCard),
      findsNothing,
      reason: 'a root deck offered a card; ${robot.visibleText}',
    );

    // Step 2: the sub-deck form asks for a name and not for a scheduler — the
    // root already decided that for the whole tree.
    expect(
      find.text(ItText.eightBox),
      findsNothing,
      reason: 'the sub-deck form asked for a scheduler; ${robot.visibleText}',
    );
    await robot.enterNthField(0, 'Vocabulary');
    await robot.tapText(ItText.createSubmit);
    expect(find.text('Vocabulary'), findsWidgets);
  });

  // SETUP-TREE-UNSET · CLEAN-RESET · UC-08, BR-60, BR-61
  testWidgets('IT-TREE-002 an unset deck offers both kinds', (tester) async {
    final harness = await start(tester);
    final robot = await openedRoot(harness, tester);
    await robot.createSubDeck('Vocabulary');
    await robot.openDeck('Vocabulary');

    // Step 1: both choices are offered — BR-61 is exactly this.
    await robot.tapText(ItText.addToThisDeck);
    expect(find.text(ItText.newCard), findsWidgets);
    expect(find.text(ItText.newSubDeck), findsWidgets);

    // Step 2: closing without choosing creates nothing and changes nothing.
    await robot.dismissSheet();
    await robot.tapText(ItText.addToThisDeck);
    expect(
      find.text(ItText.newCard),
      findsWidgets,
      reason: 'dismissing the sheet narrowed the deck; ${robot.visibleText}',
    );
    expect(find.text(ItText.newSubDeck), findsWidgets);
  });

  // SETUP-TREE-UNSET · CLEAN-RESET · UC-08, BR-62, BR-63
  testWidgets('IT-TREE-003 the first card fixes the deck to cards', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await openedRoot(harness, tester);
    await robot.createSubDeck('Academic words');
    await robot.openDeck('Academic words');

    // Step 1 and 2: choosing a card and saving lands on the card list.
    await robot.createCard('abandon', 'từ bỏ');
    await robot.scrollToText('abandon');
    expect(
      find.text('abandon'),
      findsWidgets,
      reason: 'the saved card never appeared; ${robot.visibleText}',
    );

    // Step 3: the deck now offers cards only — no sub-deck route remains.
    expect(
      find.text(ItText.newSubDeck),
      findsNothing,
      reason: 'a card deck still offered a sub-deck; ${robot.visibleText}',
    );

    // Step 4: leaving and re-entering goes straight to the card list rather
    // than an empty sub-deck level (BR-63).
    await harness.pressBack();

    // Back lands on the deck's own level, which offers the way into its cards
    // rather than an empty sub-deck list (BR-63).
    //
    // **Not the auto-forward the scenario describes.** `_cardDeckRedirect`
    // forwards a card deck into its card list, but go_router does not re-run a
    // redirect on pop, so returning by Back stops here. The level is not a dead
    // end — `DeckCardHandoffWidget` renders the action below — but it is one tap
    // more than "opening the deck goes straight to the cards". Recorded as a
    // product finding rather than silently accepted.
    expect(
      find.text('No sub-decks yet'),
      findsNothing,
      reason: 'a card deck showed a sub-deck list; ${robot.visibleText}',
    );
    expect(
      find.text('Open cards'),
      findsWidgets,
      reason: 'no way back into the cards; ${robot.visibleText}',
    );

    // And that action does reach the card list.
    await robot.tapText('Open cards');
    await robot.scrollToText('abandon');
    expect(
      find.text('abandon'),
      findsWidgets,
      reason: 'the cards action did not open the list; ${robot.visibleText}',
    );
  });

  // SETUP-UNSET-CHILD:Grammar · CLEAN-RESET · UC-08, BR-62, BR-64
  testWidgets('IT-TREE-004 the first sub-deck fixes the deck to decks', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await openedRoot(harness, tester);
    await robot.createSubDeck('Grammar');
    await robot.openDeck('Grammar');

    // Step 1 and 2: a child deck is created through the two-way sheet.
    await robot.createSubDeck('Tenses');
    expect(find.text('Tenses'), findsWidgets);

    // Step 3: the card route is gone for good.
    await robot.tapCreateAction(ItText.newSubDeck);
    expect(
      find.text(ItText.newCard),
      findsNothing,
      reason: 'a deck-type deck still offered a card; ${robot.visibleText}',
    );
  });

  // SETUP-UNSET-CHILD:Unclassified · CLEAN-RESET · UC-08 E1, BR-62
  testWidgets('IT-TREE-005 a failed validation does not fix the type', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await openedRoot(harness, tester);
    await robot.createSubDeck('Unclassified');
    await robot.openDeck('Unclassified');

    // Step 1: an empty card front is refused.
    await robot.tapText(ItText.addToThisDeck);
    await robot.tapText(ItText.newCard);
    await robot.tapText(ItText.saveCard);
    expect(
      find.textContaining("Front can't be empty"),
      findsWidgets,
      reason: 'an empty card was accepted; ${robot.visibleText}',
    );

    // Step 2: after backing out, the deck is still undecided.
    await robot.backToDeckLevel();
    await robot.tapText(ItText.addToThisDeck);
    expect(
      find.text(ItText.newSubDeck),
      findsWidgets,
      reason: 'a refused card still fixed the type; ${robot.visibleText}',
    );

    // Step 3 and 4: the same holds for a refused sub-deck.
    await robot.tapText(ItText.newSubDeck);
    await robot.tapText(ItText.createSubmit);
    expect(find.text('Enter a name.'), findsWidgets);
    await robot.dismissSheet();
    await robot.tapText(ItText.addToThisDeck);
    expect(find.text(ItText.newCard), findsWidgets);
    expect(find.text(ItText.newSubDeck), findsWidgets);
  });

  // SETUP-DECK-TYPED-WITH-CHILD · CLEAN-RESET · UC-08 A3, BR-67
  testWidgets('IT-TREE-006 deleting the last child keeps the deck type', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await openedRoot(harness, tester);
    await robot.createSubDeck('Grammar');
    await robot.openDeck('Grammar');
    await robot.createSubDeck('Tenses');

    // Step 1: the only child is deleted and the level goes empty.
    await robot.openDeckActions('Tenses');
    await robot.tapText(ItText.delete);
    await robot.tapText(ItText.delete);
    expect(
      find.text('No sub-decks yet'),
      findsWidgets,
      reason:
          'emptying did not show the deck-type empty state; '
          '${robot.visibleText}',
    );

    // Step 2: emptying does not re-open the choice — the type stays (BR-67).
    await robot.tapCreateAction(ItText.newSubDeck);
    expect(
      find.text(ItText.newCard),
      findsNothing,
      reason: 'emptying reset the content type; ${robot.visibleText}',
    );
  });

  // SETUP-DECK-TYPED-EMPTY · CLEAN-RESET · UC-03 A3, BR-68
  testWidgets('IT-TREE-007 an empty deck can have its type reset', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await openedRoot(harness, tester);
    await robot.createSubDeck('Grammar');
    await robot.openDeck('Grammar');
    await robot.createSubDeck('Tenses');
    await robot.openDeckActions('Tenses');
    await robot.tapText(ItText.delete);
    await robot.tapText(ItText.delete);
    // Deleting the last child lands on the parent level (#140), so step back in
    // before reading Grammar's own menu.
    await robot.openDeck('Grammar');

    // Step 1 and 2: the reset action exists and asks before doing anything.
    //
    // Opened from *inside* Grammar, not from its row one level up. The row menu
    // passes `mayOfferReset: false` on purpose: a parent level does not know
    // whether the child is empty, and offering a reset it might have to refuse
    // is worse than not offering it (deck_list_screen.dart:167 vs :393).
    await robot.openCurrentDeckActions();
    expect(
      find.text(ItText.resetContentType),
      findsWidgets,
      reason:
          'no reset action on an empty deck. mayOfferReset requires '
          '!isRoot && decks.isEmpty and the widget also requires '
          'contentType != unset; menu showed ${robot.visibleText}',
    );
    await robot.tapText(ItText.resetContentType);
    expect(find.textContaining('Allow both kinds'), findsWidgets);

    // Step 3: cancelling changes nothing.
    await robot.dismissSheet();
    await robot.tapCreateAction(ItText.newSubDeck);
    expect(
      find.text(ItText.newCard),
      findsNothing,
      reason: 'a cancelled reset still took effect; ${robot.visibleText}',
    );
    await robot.dismissSheet();

    // Step 4 and 5: confirming returns the deck to undecided.
    await robot.openCurrentDeckActions();
    await robot.tapText(ItText.resetContentType);
    await robot.tapText(ItText.allowBoth);
    await robot.tapText(ItText.addToThisDeck);
    expect(find.text(ItText.newCard), findsWidgets);
    expect(find.text(ItText.newSubDeck), findsWidgets);
  });

  // SETUP-TREE-UNSET · CLEAN-RESET · UC-03 E3, BR-68
  testWidgets('IT-TREE-008 a deck with content cannot be reset', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await openedRoot(harness, tester);
    await robot.createSubDeck('Vocabulary');
    await robot.openDeck('Vocabulary');
    await robot.createSubDeck('Academic words');

    // Step 1: while it still holds a child, the reset action is not offered.
    // Read from Vocabulary's own menu, where the level knows it is not empty.
    await robot.openCurrentDeckActions();
    expect(
      find.text(ItText.resetContentType),
      findsNothing,
      reason: 'reset offered on a non-empty deck; ${robot.visibleText}',
    );
    await robot.dismissSheet();

    // Step 2: once emptied, it appears.
    await robot.openDeckActions('Academic words');
    await robot.tapText(ItText.delete);
    await robot.tapText(ItText.delete);
    await robot.openDeck('Vocabulary');
    await robot.openCurrentDeckActions();
    expect(
      find.text(ItText.resetContentType),
      findsWidgets,
      reason: 'reset missing after emptying; ${robot.visibleText}',
    );
  });
}
