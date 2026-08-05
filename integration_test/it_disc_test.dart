import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/it_harness.dart';
import 'support/it_robot.dart';

/// IT scenarios for deck discovery and progress —
/// `04-deck-discovery-and-progress.md`.
///
/// IT-DISC-001…004 are absent on purpose: all four need the `S-DUE` fixture
/// with the clock pinned at `T0`, which is not implemented, so they stay
/// `FIXTURE-BLOCKED` in the catalog rather than being approximated here.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<ItHarness> start(WidgetTester tester) async {
    final harness = await ItHarness.open(tester);
    addTearDown(harness.dispose);
    await harness.launchApp();

    return harness;
  }

  // SETUP-ROOT-TRIO · CLEAN-RESET · UC-06
  testWidgets('IT-DISC-005 sorting by name and by recent', (tester) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    // Created beta, Alpha, gamma in that order — and at three distinct
    // instants, because the harness clock is otherwise frozen at T0 and three
    // identical created_at values make "recent" a coin toss instead of a sort.
    harness.setNow(kT0.subtract(const Duration(minutes: 3)));
    await robot.createRootDeck('beta', scheduler: ItText.eightBox);
    harness.setNow(kT0.subtract(const Duration(minutes: 2)));
    await robot.createRootDeck('Alpha', scheduler: ItText.eightBox);
    harness.setNow(kT0.subtract(const Duration(minutes: 1)));
    await robot.createRootDeck('gamma', scheduler: ItText.eightBox);
    harness.setNow(kT0);

    // Step 1: by name is case-insensitive — Alpha, beta, gamma.
    await robot.chooseSort('A-Z');
    final byName = robot.verticalOrderOf(<String>['Alpha', 'beta', 'gamma']);
    expect(byName, <String>[
      'Alpha',
      'beta',
      'gamma',
    ], reason: 'name sort is case-sensitive or wrong; got $byName');

    // Step 2: by recent is newest first — gamma, Alpha, beta.
    await robot.chooseSort('Recent');
    final byRecent = robot.verticalOrderOf(<String>['Alpha', 'beta', 'gamma']);
    expect(byRecent, <String>[
      'gamma',
      'Alpha',
      'beta',
    ], reason: 'recent sort is not newest-first; got $byRecent');
  });

  // SETUP-SEARCH-TREES · CLEAN-RESET · UC-06 A3, BR-56, BR-57
  testWidgets('IT-DISC-006 deck search stays inside the open subtree', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);

    // Two trees, each with a deck whose name contains "Academic".
    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );
    await robot.createRootDeck('IELTS 2026', scheduler: ItText.sm2);
    await robot.openDeck('IELTS 2026');
    await robot.createSubDeck('Reading');
    await robot.openDeck('Reading');
    await robot.createSubDeck('Academic archive');
    await harness.pressBack();
    await harness.pressBack();
    await robot.openDeck('Giao tiếp hằng ngày');
    await robot.createSubDeck('Vocabulary');
    await robot.openDeck('Vocabulary');
    await robot.createSubDeck('Academic words');
    await harness.pressBack();

    // Steps 1 and 2: searching inside D-EB finds its own deck and not the one
    // under the other root (BR-57).
    await robot.enterSearch('Academic');
    expect(
      find.textContaining('Academic words'),
      findsWidgets,
      reason: 'subtree search missed its own deck; ${robot.visibleText}',
    );
    expect(
      find.textContaining('Academic archive'),
      findsNothing,
      reason: 'search leaked outside the subtree; ${robot.visibleText}',
    );

    // Step 4: clearing returns the level to normal.
    await robot.enterSearch('');
    expect(find.textContaining('Vocabulary'), findsWidgets);
  });

  // SETUP-D-EB · CLEAN-RESET · UC-06
  testWidgets('IT-DISC-007 a deck search with no match names its scope', (
    tester,
  ) async {
    final harness = await start(tester);
    final robot = ItRobot(tester, harness);
    await robot.createRootDeck(
      'Giao tiếp hằng ngày',
      scheduler: ItText.eightBox,
    );

    // Step 1: the no-result state says what was searched and where.
    await robot.enterSearch('không-tồn-tại');
    expect(
      find.textContaining('No decks match'),
      findsWidgets,
      reason: 'no scope-aware empty state; ${robot.visibleText}',
    );

    // Step 2: clearing brings the level back.
    await robot.enterSearch('');
    expect(
      find.text('Giao tiếp hằng ngày'),
      findsWidgets,
      reason: 'clearing the search did not restore the list',
    );
  });

  // SETUP-TREE-CARD · CLEAN-RESET · UC-06 A2, BR-22
  testWidgets('IT-DISC-008 ancestor counts follow a card being added', (
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

    // Step 1: baseline — the ancestor level reports no cards yet.
    expect(
      find.textContaining('No cards'),
      findsWidgets,
      reason: 'no card count on the ancestor; ${robot.visibleText}',
    );

    // Step 2: adding a card updates the ancestor without a manual refresh.
    await robot.openDeck('Academic words');
    await robot.createCard('abandon', 'từ bỏ');
    await harness.pressBack();
    await harness.pressBack();
    await robot.openDeck('Giao tiếp hằng ngày');
    expect(
      find.textContaining('1 card'),
      findsWidgets,
      reason:
          'the ancestor count did not follow the new card; '
          '${robot.visibleText}',
    );

    // Step 3: deleting it returns the count to the baseline.
    await robot.openDeck('Academic words');
    await robot.deleteOpenCard('abandon');
    await harness.pressBack();
    await harness.pressBack();
    await robot.openDeck('Giao tiếp hằng ngày');
    expect(
      find.textContaining('No cards'),
      findsWidgets,
      reason: 'the ancestor count did not return to zero; ${robot.visibleText}',
    );
  });
}
