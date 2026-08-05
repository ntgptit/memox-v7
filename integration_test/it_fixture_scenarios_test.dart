import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/it_fixtures.dart';
import 'support/it_harness.dart';
import 'support/it_robot.dart';

/// The nine scenarios the catalog held as `FIXTURE-BLOCKED`, now runnable:
/// IT-DISC-001…004 and IT-ORG-003/005/010 on `S-DUE`/`S-PROGRESS`,
/// IT-CARD-009 on `S-PROGRESS`, IT-ORG-012 on `S-LARGE`.
///
/// Every test pins the clock to `T0` before the first frame, which is what
/// makes "2 due" a fact rather than a race against the wall clock.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<(ItHarness, ItRobot)> startOnDueLibrary(WidgetTester tester) async {
    final harness = await ItHarness.open(tester);
    addTearDown(harness.dispose);
    await ItFixtures.loadDueLibrary(harness);
    await harness.launchApp();

    return (harness, ItRobot(tester, harness));
  }

  // S-DUE · CLEAN-RESET · UC-06, BR-22
  testWidgets('IT-DISC-001 the deck tile carries the deciding numbers', (
    tester,
  ) async {
    final (harness, robot) = await startOnDueLibrary(tester);

    // Step 1: the root tile aggregates its whole subtree.
    expect(find.text('Due library'), findsWidgets);
    expect(
      find.textContaining('5 cards'),
      findsWidgets,
      reason: 'the tile does not total the subtree; ${robot.visibleText}',
    );
    expect(find.textContaining('2 due'), findsWidgets);
    expect(find.textContaining('2 sub-decks'), findsWidgets);

    // Step 3: a child level uses the same shape with its own numbers.
    await robot.openDeck('Due library');
    expect(
      find.textContaining('4 cards'),
      findsWidgets,
      reason: 'Mixed due does not total its own cards; ${robot.visibleText}',
    );
    expect(
      find.textContaining('Nothing due'),
      findsWidgets,
      reason: 'No due group does not read as quiet; ${robot.visibleText}',
    );
  });

  // S-DUE · CLEAN-RESET · UC-06 A1, BR-29
  testWidgets('IT-DISC-002 nothing due is a normal state', (tester) async {
    final (harness, robot) = await startOnDueLibrary(tester);
    await robot.openDeck('Due library');
    await robot.openDeck('No due group');

    // Step 1: the child with only future cards reads as quiet, not broken.
    expect(find.text('Future only'), findsWidgets);
    expect(
      find.textContaining('Nothing due'),
      findsWidgets,
      reason: 'zero due is not communicated; ${robot.visibleText}',
    );

    // Step 2: no error surface anywhere.
    expect(find.text('Retry'), findsNothing);
  });

  // S-DUE · CLEAN-RESET · UC-06, BR-22
  testWidgets('IT-DISC-003 the due filter keeps only decks with due cards', (
    tester,
  ) async {
    final (harness, robot) = await startOnDueLibrary(tester);
    await robot.openDeck('Due library');

    // Step 1: Due only leaves Mixed due and drops No due group. The control
    // is a toggle showing the state currently applied, so this taps the
    // "All decks" it displays to switch into due-only.
    await robot.setDeckDueFilter(dueOnly: true);
    expect(find.text('Mixed due'), findsWidgets);
    expect(
      find.text('No due group'),
      findsNothing,
      reason: 'the due filter kept a no-due deck; ${robot.visibleText}',
    );

    // Step 2: opening a result and coming back still shows the truth.
    await robot.openDeck('Mixed due');
    await harness.pressBack();
    expect(find.text('Mixed due'), findsWidgets);

    // Step 3: Show all restores the level.
    await robot.setDeckDueFilter(dueOnly: false);
    expect(find.text('No due group'), findsWidgets);
  });

  // S-DUE · CLEAN-RESET · UC-06, BR-29
  testWidgets('IT-DISC-004 an empty due filter offers the way back', (
    tester,
  ) async {
    final (harness, robot) = await startOnDueLibrary(tester);
    await robot.openDeck('Due library');
    await robot.openDeck('No due group');

    // Step 1: nothing here is due, and that is an empty state, not an error.
    await robot.setDeckDueFilter(dueOnly: true);
    expect(
      find.textContaining('Nothing due right now'),
      findsWidgets,
      reason: 'no neutral empty state for the due filter; ${robot.visibleText}',
    );
    expect(find.text('Retry'), findsNothing);

    // Step 2: the escape hatch restores the list.
    await robot.tapText('Show all decks');
    expect(find.text('Future only'), findsWidgets);
  });

  // S-PROGRESS · CLEAN-RESET · UC-04 A1, BR-10, BR-92
  testWidgets('IT-CARD-009 editing text leaves progress and the flag alone', (
    tester,
  ) async {
    final (harness, robot) = await startOnDueLibrary(tester);
    await robot.openDeck('Due library');
    await robot.openDeck('Mixed due');

    // Step 1: the baseline — a learned, flagged, due card.
    await robot.scrollToText('beginning-visible');
    expect(find.text('BEGINNING'), findsWidgets);
    expect(find.byIcon(Icons.flag), findsWidgets);
    expect(find.text('now'), findsWidgets);

    // Step 2: edit only the text.
    await robot.tapText('beginning-visible');
    await robot.enterNthField(1, 'nghĩa mới');
    await robot.tapText('Save changes');

    // Step 3: the content changed and nothing else did.
    await robot.scrollToText('beginning-visible');
    expect(find.text('nghĩa mới'), findsWidgets);
    expect(
      find.text('BEGINNING'),
      findsWidgets,
      reason: 'editing text moved the display state; ${robot.visibleText}',
    );
    expect(
      find.byIcon(Icons.flag),
      findsWidgets,
      reason: 'editing text dropped the flag; ${robot.visibleText}',
    );
    expect(find.text('now'), findsWidgets);
  });

  // S-DUE · CLEAN-RESET · UC-04, BR-22
  testWidgets('IT-ORG-003 newest and due-first agree on this fixture', (
    tester,
  ) async {
    final (harness, robot) = await startOnDueLibrary(tester);
    await robot.openDeck('Due library');
    await robot.openDeck('Mixed due');

    // Step 1: newest-first puts the youngest card on top. Adjacent pairs,
    // because a phone viewport cannot hold all four rows at once and a lazy
    // list only has geometry for what is built.
    await robot.expectRowOrder('new-visible', 'beginning-visible');
    await robot.expectRowOrder('beginning-visible', 'reviewing-visible');

    // Step 2: due-first keeps the same head — due-now cards before future ones.
    await robot.scrollToTop();
    await robot.tapBySemantics('Sort');
    await robot.tapText('Due first');
    await robot.waitCardListSteady();
    await robot.expectRowOrder('new-visible', 'beginning-visible');
    await robot.expectRowOrder('beginning-visible', 'reviewing-visible');

    // Step 3: a filter composes with the sort instead of overriding it.
    await robot.tapTextContaining('Flagged');
    await robot.waitCardListSteady();
    expect(find.text('beginning-visible'), findsWidgets);
    expect(
      find.text('new-visible'),
      findsNothing,
      reason: 'the filter let an unflagged card through; ${robot.visibleText}',
    );
  });

  // S-DUE · CLEAN-RESET · BR-22, BR-90, BR-92
  testWidgets('IT-ORG-005 the four pills carry the exact counts', (
    tester,
  ) async {
    final (harness, robot) = await startOnDueLibrary(tester);
    await robot.openDeck('Due library');
    await robot.openDeck('Mixed due');

    // Step 1: All 4 · Due 1 · New 1 · Flagged 1, as numbers, not vibes.
    //
    // **Due is 1, not 2, and that is the point of the pill.** All four cards
    // sit in one deck: one never opened, one that has come back around, one
    // scheduled ahead, one finished. BR-22's session queue holds the first two
    // — but `CardListFilter.due` subtracts New from that queue, so Due counts
    // only the card that has actually returned. While Due was the bare queue
    // this line read `Due 2 · New 1` for three distinct cards, and `new-visible`
    // answered to both pills.
    for (final pill in <String>['All 4', 'Due 1', 'New 1', 'Flagged 1']) {
      expect(
        find.textContaining(pill),
        findsWidgets,
        reason: 'pill "$pill" is missing or wrong; ${robot.visibleText}',
      );
    }

    // Step 2: Due keeps the returning card and nothing else — including not the
    // new one, which is the pill's whole job.
    //
    // `Due 1` rather than `Due`: the panel above the pills carries "1 due · 1
    // new", and a bare prefix would be one tap away from landing on prose.
    await robot.tapTextContaining('Due 1');
    await robot.waitCardListSteady();
    expect(
      find.text('new-visible'),
      findsNothing,
      reason: 'Due let a never-reviewed card through; ${robot.visibleText}',
    );
    expect(find.text('beginning-visible'), findsWidgets);
    expect(find.text('reviewing-visible'), findsNothing);
    expect(find.text('mastered-visible'), findsNothing);

    // Step 3: New keeps only the unlearned card.
    await robot.tapTextContaining('New 1');
    await robot.waitCardListSteady();
    expect(find.text('new-visible'), findsWidgets);
    expect(find.text('beginning-visible'), findsNothing);

    // Step 4: Flagged keeps only the flagged card.
    await robot.tapTextContaining('Flagged');
    await robot.waitCardListSteady();
    expect(find.text('beginning-visible'), findsWidgets);
    expect(find.text('new-visible'), findsNothing);

    // Step 5: All brings the deck back.
    await robot.tapTextContaining('All 4');
    await robot.waitCardListSteady();
    await robot.scrollToText('mastered-visible');
    expect(find.text('mastered-visible'), findsWidgets);
  });

  // S-PROGRESS + S-DUE · CLEAN-RESET · BR-89, BR-90, BR-91
  testWidgets('IT-ORG-010 states, badges and the panel tell one story', (
    tester,
  ) async {
    final (harness, robot) = await startOnDueLibrary(tester);
    await robot.openDeck('Due library');
    await robot.openDeck('Mixed due');

    // Steps 1 and 2: each display state sits on its own row, wearing the due
    // badge the fixture's clock offsets dictate. Checked row by row — on a
    // lazy list, labels belonging to rows that are not built are not merely
    // off-screen, they do not exist.
    const expectations = <(String, String, String?)>[
      ('new-visible', 'NEW', 'now'),
      ('beginning-visible', 'BEGINNING', 'now'),
      ('reviewing-visible', 'REVIEWING', '2d'),
      ('mastered-visible', 'MASTERED', '30d'),
    ];
    for (final (front, state, badge) in expectations) {
      await robot.scrollToText(front);
      expect(
        find.text(state),
        findsWidgets,
        reason: 'no $state beside $front; ${robot.visibleText}',
      );
      if (badge != null) {
        expect(
          find.text(badge),
          findsWidgets,
          reason: 'no "$badge" badge beside $front; ${robot.visibleText}',
        );
      }
    }

    // Step 3: the panel agrees — 4 cards, one per band, a quarter mastered.
    // The row walk above ended at the tail; the panel lives at the head.
    await robot.scrollToTop();
    expect(find.textContaining('1 of 4 mastered'), findsWidgets);
    expect(find.textContaining('25%'), findsWidgets);

    // Step 4: flagging is not a review, so progress must not move.
    await robot.scrollToText('mastered-visible');
    await robot.tapText('mastered-visible');
    await robot.tapBySemantics(ItText.flagCard);
    await robot.tapBySemantics(ItText.cardEditorClose);
    // The panel lives at the head of the list, and the walk above ended at the
    // tail — on a lazy list "not built" and "changed" read identically, so
    // climb back before deciding which one it is.
    await robot.scrollToTop();
    expect(
      find.textContaining('1 of 4 mastered'),
      findsWidgets,
      reason: 'a flag toggle moved the progress panel; ${robot.visibleText}',
    );
  });

  // S-LARGE · CLEAN-RESET · M4.11 W1b
  testWidgets('IT-ORG-012 a large deck loads in windows and loses nothing', (
    tester,
  ) async {
    final harness = await ItHarness.open(tester);
    addTearDown(harness.dispose);
    await ItFixtures.loadLargeDeck(harness);
    await harness.launchApp();
    final robot = ItRobot(tester, harness);
    await robot.openDeck('Large library');
    await robot.openDeck('Large deck 65');

    // Step 1: the first window is fifty of sixty-five, and says so.
    expect(
      find.textContaining('Showing 50 of 65'),
      findsWidgets,
      reason: 'the first window is not 50/65; ${robot.visibleText}',
    );

    // Step 2: the tail offers more instead of claiming completeness.
    await robot.scrollToText('Load 50 more');
    expect(find.textContaining('Load 50 more'), findsWidgets);

    // Step 3: loading the rest reaches 65/65 with the oldest card present.
    await robot.tapTextContaining('Load 50 more');
    await robot.waitCardListSteady();
    // The showing line sits above the rows; the load-more tap happened at the
    // tail, so climb back to read it.
    await robot.scrollToTop();
    expect(find.textContaining('Showing 65 of 65'), findsWidgets);
    await robot.scrollToText('card-001');
    expect(
      find.text('card-001'),
      findsOneWidget,
      reason: 'the oldest card is missing or duplicated; ${robot.visibleText}',
    );

    // Step 4: opening a card and returning leaves the list usable.
    await robot.tapText('card-001');
    await robot.tapBySemantics(ItText.cardEditorClose);
    expect(
      find.byType(Scrollable),
      findsWidgets,
      reason: 'the list did not survive the round trip; ${robot.visibleText}',
    );
  });
}
