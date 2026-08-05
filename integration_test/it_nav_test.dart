import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/it_harness.dart';
import 'support/it_robot.dart';

/// IT scenarios for navigation and continuity — `01-navigation-and-continuity.md`.
///
/// One `testWidgets` per scenario ID, with the ID in the test name so a failing
/// run names the scenario rather than a file. The harness is opened inside each
/// test because it needs the `WidgetTester`, and torn down through
/// `addTearDown` so `CLEAN-RESET` still runs when a scenario fails part-way.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ItHarness> start(WidgetTester tester) async {
    final harness = await ItHarness.open(tester);
    addTearDown(harness.dispose);
    await harness.launchApp();

    return harness;
  }

  // SETUP-EMPTY · CLEAN-RESET · UC-06
  testWidgets('IT-NAV-001 cold start opens the deck list', (tester) async {
    await start(tester);

    // Step 1: the app started without a red screen or technical detail.
    expect(find.byType(ErrorWidget), findsNothing);

    // Step 2: the bottom navigation is present with the Deck tab selected.
    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 0);

    // Step 3: no data yet, so the empty state and its create action are shown.
    expect(find.text(ItText.decksEmpty), findsOneWidget);
    expect(find.text(ItText.newDeck), findsWidgets);
  });

  // SETUP-TREE-UNSET · CLEAN-RESET · M4.10a
  testWidgets('IT-NAV-002 switching tabs keeps the open deck', (tester) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.createSubDeck('Vocabulary');
    await robot.openDeck('Vocabulary');

    // Step 1: Review announces itself as not ready, without pretending to start
    // a session.
    await robot.tapText(ItText.reviewTab);
    expect(
      find.text(ItText.decksEmpty),
      findsNothing,
      reason: 'Review tab showed the deck list; screen ${robot.visibleText}',
    );

    // Step 2 and 3: coming back lands on D-BRANCH, not the root list — the
    // branch keeps its own stack.
    await robot.tapText(ItText.decksTab);
    expect(
      find.text('Vocabulary'),
      findsWidgets,
      reason: 'returning to Decks lost the open deck; ${robot.visibleText}',
    );
  });

  // SETUP-TREE-CARD · CLEAN-RESET · UC-06
  testWidgets('IT-NAV-004 breadcrumb returns to a chosen ancestor', (
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

    // Step 1: at depth 3 the breadcrumb shows the way back. It is hidden at
    // depth 1 and 2 by design (M4.10d), so depth 3 is the first level that can
    // assert it at all.
    expect(
      find.text('Root'),
      findsWidgets,
      reason: 'no breadcrumb at depth 3; screen ${robot.visibleText}',
    );

    // Step 2: tapping an ancestor opens that ancestor.
    await robot.tapText('Giao tiếp hằng ngày');
    expect(
      find.text('Vocabulary'),
      findsWidgets,
      reason: 'breadcrumb ancestor did not open D-EB; ${robot.visibleText}',
    );

    // Step 3: the Root step returns to the root deck list.
    await robot.openDeck('Vocabulary');
    await robot.openDeck('Academic words');
    await robot.tapText('Root');
    expect(
      find.text('Giao tiếp hằng ngày'),
      findsWidgets,
      reason: 'Root crumb did not reach the root list; ${robot.visibleText}',
    );
  });

  // SETUP-EMPTY · CLEAN-RESET · M4.1
  testWidgets('IT-NAV-005 an unknown route offers a way back', (tester) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    // Precondition, not a step: reaching a route that does not exist is what a
    // stale deep link does, and there is no in-app control that produces one.
    await harness.openLocation('/khong-ton-tai');

    // Step 1: a page in the user's language, with no technical detail.
    expect(
      find.text('Page not found'),
      findsOneWidget,
      reason: 'no 404 page; screen ${robot.visibleText}',
    );
    for (final leak in <String>['Exception', 'SELECT', '/decks/:', 'null']) {
      expect(
        find.textContaining(leak),
        findsNothing,
        reason: '404 page leaked "$leak"; screen ${robot.visibleText}',
      );
    }

    // Step 2: the recovery action returns to the deck list with its tab active.
    // The label is "Go home" — the 404 page belongs to the app shell, not to
    // the deck feature, so it does not borrow the deck screen's wording.
    await robot.tapText('Go home');
    expect(find.text(ItText.decksEmpty), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  // SETUP-EMPTY · CLEAN-RESET · UC-02, UC-03, UC-04, UC-08, M4.12
  testWidgets('IT-NAV-006 the whole Deck/Card journey survives a restart', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    // Step 1: a root deck with a study mode.
    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );
    expect(find.text('Giao tiếp hằng ngày'), findsWidgets);

    // Step 2: a branch inside it, and the tree shows the parent/child relation.
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.createSubDeck('Vocabulary');
    await robot.openDeck('Vocabulary');

    // Step 3: a leaf, and the first card fixes it to holding cards.
    await robot.createSubDeck('Academic words');
    await robot.openDeck('Academic words');
    await robot.createCard('abandon', 'từ bỏ');

    // Step 4: editing the card shows the new meaning in the list.
    await robot.tapText('abandon');
    await robot.enterNthField(1, 'rời bỏ');
    await robot.tapText('Save changes');
    expect(
      find.text('rời bỏ'),
      findsWidgets,
      reason: 'the edit did not reach the list; ${robot.visibleText}',
    );

    // Step 5 and 6: back at the root list — as the scenario says — the data
    // outlives the app and the walk back down finds it. Restarting from deep
    // inside the pushed stack, which this test used to do, wedged the engine
    // hard enough that even the VM service stopped answering; returning first
    // is not just what the document orders, it is what a user does before
    // killing an app.
    await robot.backUntilRowVisible('Giao tiếp hằng ngày');
    await harness.restartApp();
    expect(
      find.text('Giao tiếp hằng ngày'),
      findsWidgets,
      reason: 'the root deck did not survive restart; ${robot.visibleText}',
    );
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.openDeck('Vocabulary');
    await robot.openDeck('Academic words');
    expect(
      find.text('rời bỏ'),
      findsWidgets,
      reason: 'the edited card did not survive restart; ${robot.visibleText}',
    );

    // Step 7: deleting the only card leaves the card deck empty, not broken.
    // The card editor names its own action "Delete card" and puts it under a
    // danger zone; only the confirmation reuses the bare "Delete".
    await robot.tapText('abandon');
    await robot.scrollToText('Delete card');
    await robot.tapText('Delete card');
    await robot.tapText(ItText.delete);
    expect(
      find.text('No cards yet'),
      findsWidgets,
      reason:
          'the deck did not fall back to its empty state; '
          '${robot.visibleText}',
    );

    // Step 8: the branch can be deleted and the app keeps working. One back
    // leaves the cards; the breadcrumb then jumps straight to D-EB — the jump
    // tool M4.10d built for exactly this, and sturdier after a restart than
    // counting pops (the one post-restart pop this still does is bounded).
    await harness.pressBack();
    await robot.tapText('Giao tiếp hằng ngày');
    await robot.openDeckActions('Vocabulary');
    await robot.tapText(ItText.delete);
    await robot.tapText(ItText.delete);
    expect(find.text('Vocabulary'), findsNothing);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  // SETUP-TREE-CARD · CLEAN-RESET · M5, AD-01
  testWidgets('IT-NAV-007 content management works with no network', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    // The device is in airplane mode for the whole scenario — the run script
    // enables it before `flutter test` starts and disables it afterwards, so
    // every step below happens with no network at all. AD-05 says the app has
    // no `dio` dependency yet, which makes this a check that nothing crept in.
    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );
    await robot.openDeck('Giao tiếp hằng ngày');

    // Step 2: a sub-deck is created and appears, offline.
    await robot.createSubDeck('Academic words');
    expect(
      find.text('Academic words'),
      findsWidgets,
      reason: 'offline create failed; ${robot.visibleText}',
    );

    // Step 1 also: nothing asked the user to sign in or to reconnect.
    for (final blocker in <String>[
      'sign in',
      'Sign in',
      'offline',
      'network',
    ]) {
      expect(
        find.textContaining(blocker),
        findsNothing,
        reason: 'offline blocked content management with "$blocker"',
      );
    }

    // Step 3: create, edit and flag a card, all offline.
    await robot.openDeck('Academic words');
    await robot.createCard('abandon', 'từ bỏ');
    await robot.tapText('abandon');
    await robot.enterNthField(1, 'rời bỏ');
    await robot.tapText('Save changes');
    expect(find.text('rời bỏ'), findsWidgets);

    // Step 4: it all survives a restart while still offline.
    await harness.restartApp();
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.openDeck('Academic words');
    expect(
      find.text('rời bỏ'),
      findsWidgets,
      reason: 'offline data did not survive restart; ${robot.visibleText}',
    );

    // Step 5: deleting works with no network.
    await robot.tapText('abandon');
    await robot.scrollToText('Delete card');
    await robot.tapText('Delete card');
    await robot.tapText(ItText.delete);
    expect(find.text('No cards yet'), findsWidgets);
  });

  // SETUP-TREE-CARD · CLEAN-RESET · UC-06
  testWidgets('IT-NAV-003 back goes up exactly one level', (tester) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    // SETUP-TREE-UNSET, then a card so D-LEAF becomes a card deck.
    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.createSubDeck('Vocabulary');
    await robot.openDeck('Vocabulary');
    await robot.createSubDeck('Academic words');
    await robot.openDeck('Academic words');

    // Precondition: the setup really did open D-LEAF at depth 3. Asserted
    // rather than assumed, so a navigation failure below cannot be blamed on a
    // setup that never got there.
    expect(
      find.text('Academic words'),
      findsWidgets,
      reason: 'setup did not reach D-LEAF; screen showed ${robot.visibleText}',
    );

    // Step 1: back lands on D-BRANCH, which lists D-LEAF — not the root list.
    await harness.pressBack();
    expect(
      find.text('Academic words'),
      findsWidgets,
      reason: 'after 1 back, screen showed ${robot.visibleText}',
    );

    // Step 2: back again lands on D-EB, which lists D-BRANCH.
    await harness.pressBack();
    expect(
      find.text('Vocabulary'),
      findsWidgets,
      reason: 'after 2 backs, screen showed ${robot.visibleText}',
    );

    // Step 3: back again reaches the root deck list.
    await harness.pressBack();
    expect(
      find.text('Giao tiếp hằng ngày'),
      findsWidgets,
      reason: 'after 3 backs, screen showed ${robot.visibleText}',
    );
  });
}
