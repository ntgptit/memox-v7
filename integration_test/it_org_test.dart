import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/it_harness.dart';
import 'support/it_robot.dart';

/// IT scenarios for card discovery and organization —
/// `06-card-discovery-and-organization.md`.
///
/// IT-ORG-003, 005, 010 and 012 are absent on purpose: they need the `S-DUE`,
/// `S-PROGRESS` and `S-LARGE` fixtures, which are not implemented, so they stay
/// `FIXTURE-BLOCKED` in the catalog rather than being approximated here.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ItHarness> start(WidgetTester tester) async {
    final harness = await ItHarness.open(tester);
    addTearDown(harness.dispose);
    await harness.launchApp();

    return harness;
  }

  /// `SETUP-CARD-PLAIN`: three cards, no tags, nothing flagged.
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

  // SETUP-CARD-BASIC · CLEAN-RESET · UC-04, S1
  testWidgets('IT-ORG-001 search matches the front and the back', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await threeCards(harness, tester);

    // Step 1: a front-side term narrows the list to its card.
    await robot.enterCardSearch('abandon');
    expect(find.text('abandon'), findsWidgets);
    expect(
      find.text('benevolent'),
      findsNothing,
      reason: 'search did not narrow the list; ${robot.visibleText}',
    );

    // Step 2: a back-side meaning matches too — search reads both sides.
    await robot.enterCardSearch('nhân từ');
    expect(
      find.text('benevolent'),
      findsWidgets,
      reason: 'the back side is not searchable; ${robot.visibleText}',
    );
    expect(find.text('abandon'), findsNothing);

    // Step 3: clearing brings everything back.
    await robot.enterCardSearch('');
    await robot.scrollToText('abandon');
    expect(find.text('abandon'), findsWidgets);
  });

  // SETUP-CARD-BASIC · CLEAN-RESET · UC-04, S1
  testWidgets('IT-ORG-002 a search with no match recovers', (tester) async {
    final harness = await start(tester);
    final robot = await threeCards(harness, tester);

    // Step 1: the no-match state names the query and does not invite a first
    // card — the deck is not empty, the filter is.
    await robot.enterCardSearch('không-tồn-tại');
    expect(find.textContaining('No cards match'), findsWidgets);
    expect(
      find.text(ItText.cardListEmptyAction),
      findsNothing,
      reason: 'a filtered-out list offered the first-card action',
    );

    // Step 2: clearing restores the list.
    await robot.enterCardSearch('');
    await robot.scrollToText('abandon');
    expect(find.text('abandon'), findsWidgets);
  });

  // SETUP-CARD-PLAIN · CLEAN-RESET · BR-92
  testWidgets('IT-ORG-004 flagging and unflagging a card', (tester) async {
    final harness = await start(tester);
    final robot = await threeCards(harness, tester);

    // Steps 1 and 2: the flag is set from the editor and shows on the row.
    await robot.scrollToText('concise');
    await robot.tapText('concise');
    await robot.tapBySemantics(ItText.flagCard);
    await robot.tapBySemantics(ItText.cardEditorClose);
    await robot.scrollToText('concise');
    expect(
      find.byIcon(Icons.flag),
      findsWidgets,
      reason: 'the flag did not reach the row; ${robot.visibleText}',
    );

    // Step 3: it survives a restart.
    await harness.restartApp();
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.openDeck('Academic words');
    await robot.scrollToText('concise');
    expect(find.byIcon(Icons.flag), findsWidgets);

    // Step 4: tapping again clears it.
    await robot.tapText('concise');
    await robot.tapBySemantics(ItText.unflagCard);
    await robot.tapBySemantics(ItText.cardEditorClose);
    await robot.scrollToText('concise');
    expect(
      find.byIcon(Icons.flag),
      findsNothing,
      reason: 'the flag survived being cleared; ${robot.visibleText}',
    );
  });

  // SETUP-TREE-CARD · CLEAN-RESET · BR-92
  testWidgets('IT-ORG-006 an empty filter is not an empty deck', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = await threeCards(harness, tester);

    // Step 1: nothing is flagged, so the Flagged pill matches nothing — and
    // that must not read as "this deck has no cards".
    await robot.tapTextContaining('Flagged');
    expect(
      find.text(ItText.cardListEmptyAction),
      findsNothing,
      reason: 'an empty filter offered the first-card action',
    );
    expect(find.textContaining('No cards match'), findsWidgets);

    // Step 2: All brings the cards back.
    await robot.tapTextContaining('All');
    await robot.scrollToText('abandon');
    expect(find.text('abandon'), findsWidgets);
  });

  // SETUP-CARD-PLAIN · CLEAN-RESET · BR-93
  testWidgets('IT-ORG-007 tags are reused regardless of case', (tester) async {
    final harness = await start(tester);
    final robot = await threeCards(harness, tester);

    // Steps 1 and 2: a tag added in the editor shows on the row.
    await robot.scrollToText('abandon');
    await robot.tapText('abandon');
    await robot.addTag('IELTS');
    await robot.tapBySemantics(ItText.cardEditorClose);
    await robot.scrollToText('IELTS');
    expect(
      find.text('IELTS'),
      findsWidgets,
      reason: 'the tag did not reach the row; ${robot.visibleText}',
    );

    // Step 3: the same name in another case is the same tag (BR-93), so the
    // chip keeps the spelling the tag was created with.
    await robot.scrollToText('benevolent');
    await robot.tapText('benevolent');
    await robot.addTag('ielts');
    await robot.tapBySemantics(ItText.cardEditorClose);
    await robot.scrollToText('benevolent');
    expect(find.text('IELTS'), findsWidgets);

    // Step 4: adding it again on the same card produces no duplicate chip.
    await robot.tapText('benevolent');
    await robot.addTag('IELTS');
    expect(
      find.text('IELTS'),
      findsOneWidget,
      reason: 'a duplicate tag chip appeared; ${robot.visibleText}',
    );
  });

  // SETUP-CARD-TAGS · CLEAN-RESET · BR-93
  testWidgets('IT-ORG-008 removing a tag keeps the card', (tester) async {
    final harness = await start(tester);
    final robot = await threeCards(harness, tester);
    await robot.scrollToText('abandon');
    await robot.tapText('abandon');
    await robot.addTag('IELTS');
    await robot.addTag('Writing');

    // Step 1: removing one chip leaves the other.
    await robot.tapBySemantics('Remove tag IELTS');
    expect(find.text('IELTS'), findsNothing);
    expect(find.text('Writing'), findsWidgets);

    // Step 2: the card itself is untouched.
    await robot.tapBySemantics(ItText.cardEditorClose);
    await robot.scrollToText('abandon');
    expect(find.text('abandon'), findsWidgets);
    expect(find.text('từ bỏ'), findsWidgets);

    // Step 3: the removal sticks.
    await harness.restartApp();
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.openDeck('Academic words');
    await robot.scrollToText('abandon');
    expect(find.text('IELTS'), findsNothing);
  });

  // SETUP-CARD-SINGLE · CLEAN-RESET · BR-93, BR-94
  testWidgets('IT-ORG-009 tag names are validated and capped at ten', (
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
    await robot.scrollToText('abandon');
    await robot.tapText('abandon');

    // Step 1: blank and whitespace-only names are refused.
    await robot.addTag('   ');
    expect(
      find.textContaining("Tag can't be empty"),
      findsWidgets,
      reason: 'a blank tag was accepted; ${robot.visibleText}',
    );

    // Step 2: a name past 50 characters cannot be committed — the field's
    // length limit blocks the surplus (the doc accepts either that or an
    // inline error; the product blocks). Cleared afterwards so no chip is
    // created and the ten slots below stay free.
    final tagField = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == ItText.addTagHint,
    );
    await tester.tap(tagField.first);
    await harness.settle();
    await tester.enterText(tagField.first, 'x' * 60);
    await tester.pump();
    final captured =
        tester.widget<TextField>(tagField.first).controller?.text ?? '';
    expect(
      captured.length,
      50,
      reason: 'the tag field accepted more than 50 characters',
    );
    await tester.enterText(tagField.first, '');
    await harness.settle();

    // Step 3: ten distinct tags are accepted and counted.
    for (var i = 1; i <= 10; i++) {
      await robot.addTag('tag$i');
    }
    expect(
      find.textContaining('10 / 10'),
      findsWidgets,
      reason: 'the tag counter does not read 10 / 10; ${robot.visibleText}',
    );

    // Step 4: the eleventh is refused with a clear message and the ten
    // survive (BR-94). The refusal keeps the typed name in the *field* — the
    // assertion that matters is that no chip was created, so it is scoped to
    // Chip rather than to any text on screen (find.text also matches the
    // field's own EditableText).
    await robot.addTag('tag11');
    expect(
      find.textContaining('A card can hold up to 10 tags'),
      findsWidgets,
      reason: 'no clear refusal message; ${robot.visibleText}',
    );
    expect(
      find.descendant(of: find.byType(Chip), matching: find.text('tag11')),
      findsNothing,
      reason: 'the eleventh tag became a chip',
    );
    expect(
      find.descendant(of: find.byType(Chip), matching: find.text('tag10')),
      findsWidgets,
    );
    expect(find.textContaining('10 / 10'), findsWidgets);
  });

  // SETUP-TREE-CARD · CLEAN-RESET · UC-04, UC-06
  testWidgets('IT-ORG-011 the card list follows an ancestor rename', (
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
    await robot.openDeck('Vocabulary');
    await robot.createSubDeck('Academic words');
    await robot.openDeck('Academic words');
    await robot.createCard('abandon', 'từ bỏ');

    // Step 1: the card list names its deck and its ancestors.
    expect(find.textContaining('Academic words'), findsWidgets);

    // Step 2: renaming the branch updates the breadcrumb the card list shows.
    // One back reaches the deck's own level, whose breadcrumb carries the full
    // ancestor chain — the card list's own crumb shows only Root and the
    // immediate parent, so the root deck's step is not tappable from there.
    await harness.pressBack();
    await robot.tapText('Giao tiếp hằng ngày');
    await robot.openDeckActions('Vocabulary');
    await robot.tapText(ItText.rename);
    await robot.enterNthField(0, 'Từ vựng');
    await robot.tapText('Save');
    await robot.openDeck('Từ vựng');
    await robot.openDeck('Academic words');
    expect(
      find.textContaining('Từ vựng'),
      findsWidgets,
      reason: 'the breadcrumb kept the old ancestor name; ${robot.visibleText}',
    );
  });
}
