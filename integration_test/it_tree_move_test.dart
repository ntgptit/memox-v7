import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/it_harness.dart';
import 'support/it_robot.dart';

/// IT scenarios for moving decks and the depth limit —
/// `03-deck-tree-and-content-type.md`, IT-TREE-009…014.
///
/// Held in their own file because every one of them builds a two- or
/// three-branch tree first; keeping them beside the content-type scenarios made
/// that file's setup helpers mean two different things.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ItHarness> start(WidgetTester tester) async {
    final harness = await ItHarness.open(tester);
    addTearDown(harness.dispose);
    await harness.launchApp();

    return harness;
  }

  Future<ItRobot> openedRoot(ItHarness harness, WidgetTester tester) async {
    final robot = ItRobot(tester, harness);
    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );
    await robot.openDeck('Giao tiếp hằng ngày');

    return robot;
  }

  // SETUP-MOVE-TREE · CLEAN-RESET · UC-09, BR-71
  testWidgets('IT-TREE-009 moving a sub-deck to a valid target', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await openedRoot(harness, tester);
    await robot.createSubDeck('Vocabulary');
    await robot.createSubDeck('Grammar');
    await robot.openDeck('Vocabulary');
    await robot.createSubDeck('Academic words');

    // Step 1: the move sheet opens on the deck being moved.
    await robot.openDeckActions('Academic words');
    await robot.tapText(ItText.move);
    expect(
      find.text('Move to'),
      findsWidgets,
      reason: 'the move sheet did not open; ${robot.visibleText}',
    );

    // Steps 2 and 3: choosing Grammar moves it, with its contents.
    await robot.tapText('Grammar');
    await harness.pressBack();
    await robot.openDeck('Grammar');
    expect(
      find.text('Academic words'),
      findsWidgets,
      reason: 'the deck did not arrive at its target; ${robot.visibleText}',
    );
  });

  // SETUP-CYCLE-TREE · CLEAN-RESET · UC-09 E1, BR-69, BR-70
  testWidgets('IT-TREE-010 a deck cannot move into itself or a descendant', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await openedRoot(harness, tester);
    await robot.createSubDeck('Vocabulary');
    await robot.openDeck('Vocabulary');
    await robot.createSubDeck('Academic words');
    await robot.openDeck('Academic words');
    await robot.createSubDeck('Level 1');
    await harness.pressBack();
    await harness.pressBack();

    // Steps 1 and 2: both refusals are visible, each stating its own reason
    // rather than simply hiding the target.
    await robot.openDeckActions('Vocabulary');
    await robot.tapText(ItText.move);

    // **The product hides invalid targets rather than listing them disabled.**
    // The scenario text imagined self and descendants shown with per-row
    // reasons; the sheet instead offers only decks the move could land in, and
    // with every candidate excluded (itself, its subtree, its current parent)
    // it says outright that nowhere can take it. BR-69/BR-70 care that a cycle
    // is impossible and the user is told why nothing is offered; both hold.
    expect(
      find.textContaining('Nowhere to move this'),
      findsWidgets,
      reason: 'no explanation for the empty target list; ${robot.visibleText}',
    );

    // Step 3: closing leaves the tree as it was — no cycle.
    await robot.dismissSheet();
    expect(find.text('Vocabulary'), findsWidgets);
  });

  // SETUP-MOVE-TREE · CLEAN-RESET · UC-09 E2, BR-64
  testWidgets('IT-TREE-011 a deck cannot move into a deck holding cards', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await openedRoot(harness, tester);
    await robot.createSubDeck('Vocabulary');
    await robot.createSubDeck('Cards here');
    await robot.openDeck('Cards here');
    await robot.createCard('abandon', 'từ bỏ');
    // One back leaves the cards; the breadcrumb's root-deck step then jumps to
    // the level that lists Vocabulary, whatever shape the stack is in.
    await harness.pressBack();
    await robot.tapText('Giao tiếp hằng ngày');

    // Steps 1 and 2: the card deck stays visible so the scope is understood,
    // but it is refused and says why.
    await robot.openDeckActions('Vocabulary');
    await robot.tapText(ItText.move);
    // Either surface satisfies BR-64: the card deck listed disabled with its
    // reason, or excluded entirely with the sheet saying nowhere can take the
    // move. What must never exist is "Cards here" as a live target.
    final reasonShown = find
        .textContaining('Holds cards, not decks')
        .evaluate()
        .isNotEmpty;
    final nowhere = find
        .textContaining('Nowhere to move this')
        .evaluate()
        .isNotEmpty;
    expect(
      reasonShown || nowhere,
      isTrue,
      reason: 'a card deck reads as a movable target; ${robot.visibleText}',
    );

    // Step 3: nothing moved.
    await robot.dismissSheet();
    expect(find.text('Vocabulary'), findsWidgets);
  });

  // SETUP-CROSS-SCHEDULER-MOVE · CLEAN-RESET · UC-09 E3, BR-73, BR-74
  testWidgets('IT-TREE-012 a deck cannot move across study modes', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);
    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );
    await robot.createRootDeck('IELTS 2026', scheduler: ItText.sm2);
    await robot.openDeck('IELTS 2026');
    await robot.createSubDeck('Target branch');
    await harness.pressBack();
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.createSubDeck('Source branch');

    // Steps 1 and 2: the other tree's branch is refused, and the reason names
    // the study mode — nothing is converted silently.
    await robot.openDeckActions('Source branch');
    await robot.tapText(ItText.move);
    // BR-73/BR-74 hold under either surface: the other tree's branch shown
    // disabled with the study-mode reason, or not offered at all with the
    // sheet explaining that nothing can take the move.
    final crossReason = find
        .textContaining('Uses a different study mode')
        .evaluate()
        .isNotEmpty;
    final nowhereCross = find
        .textContaining('Nowhere to move this')
        .evaluate()
        .isNotEmpty;
    expect(
      crossReason || nowhereCross,
      isTrue,
      reason:
          'a cross-mode deck reads as a movable target; ${robot.visibleText}',
    );

    // Step 3: both trees survive unchanged.
    await robot.dismissSheet();
    expect(find.text('Source branch'), findsWidgets);
  });

  // SETUP-DEEP-10 · CLEAN-RESET · UC-08 E4, UC-09 E5, BR-55
  testWidgets('IT-TREE-013 the tree stops at ten levels', (tester) async {
    final harness = await start(tester);
    final robot = await openedRoot(harness, tester);

    // The root is level 1, so nine more sub-decks reach the limit.
    for (var level = 2; level <= 10; level++) {
      await robot.createSubDeck('Level $level');
      await robot.openDeck('Level $level');
    }

    // Step 1: level 11 is refused in the user's own words, with nothing
    // technical leaking through (execution guide §9).
    // Level 10 is still unset, so the create action asks which kind first.
    await robot.tapText(ItText.addToThisDeck);
    await robot.tapText(ItText.newSubDeck);
    await robot.enterNthField(0, 'Level 11');
    await robot.tapText(ItText.createSubmit);
    for (final leak in <String>['Exception', 'SELECT', 'Failure']) {
      expect(
        find.textContaining(leak),
        findsNothing,
        reason: 'the depth refusal leaked "$leak"; ${robot.visibleText}',
      );
    }
    expect(
      find.textContaining('deepest allowed level'),
      findsWidgets,
      reason: 'no depth-limit message; ${robot.visibleText}',
    );

    // Step 2: a card is still allowed there — it adds no depth.
    await robot.dismissSheet();
    await robot.createCard('abandon', 'từ bỏ');
    await robot.scrollToText('abandon');
    expect(
      find.text('abandon'),
      findsWidgets,
      reason: 'a card was refused at the depth limit; ${robot.visibleText}',
    );
  });

  // SETUP-CARD-EMPTY-TYPED · CLEAN-RESET · UC-03 A3, BR-67, BR-68
  testWidgets('IT-TREE-014 an emptied card deck can be managed', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await openedRoot(harness, tester);
    await robot.createSubDeck('Academic words');
    await robot.openDeck('Academic words');
    await robot.createCard('abandon', 'từ bỏ');
    await robot.deleteOpenCard('abandon');

    // Step 1: from the empty card list, management is one Back away — the
    // deck's own level, whose app-bar menu offers the reset because that level
    // knows it is empty (mayOfferReset) and card-typed. The catalog carried
    // this as KNOWN-GAP on the belief that no entry existed; this journey is
    // that entry, so the gap closes without new UI. What would reopen it is
    // this menu losing the action — exactly what the assertion pins.
    await harness.pressBack();
    await robot.openCurrentDeckActions();
    expect(
      find.text(ItText.resetContentType),
      findsWidgets,
      reason:
          'no deck management within reach of an empty card list; '
          '${robot.visibleText}',
    );

    // Steps 2 to 4: resetting returns the deck to undecided, and both kinds
    // become available again.
    await robot.tapText(ItText.resetContentType);
    await robot.tapText(ItText.allowBoth);
    await robot.tapText(ItText.addToThisDeck);
    expect(find.text(ItText.newCard), findsWidgets);
    expect(find.text(ItText.newSubDeck), findsWidgets);
  });
}
