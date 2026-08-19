import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/it_robot.dart';
import 'support/it_scenario.dart';

/// The two `DEVICE-E2E` scenarios about **the radios being off** — IT-NAV-007
/// and IT-CONT-008.
///
/// Separate from `it_platform_test.dart` because they are a different claim.
/// The `IT-PLAT` group asks what only a device can show about the platform:
/// its bootstrap, its file system, its deep links, its back gesture. These two
/// ask what must keep working when the network is gone, which is a claim about
/// the *product* — AD-05 keeps `dio` out of the tree entirely, so what they
/// really assert is that nothing has crept in since.
///
/// **Airplane mode is a precondition of the run, not a step.** No widget turns
/// the radios off, so the run script does it: `ci-device.yml` calls
/// `adb shell cmd connectivity airplane-mode enable` before `flutter test` and
/// disables it afterwards. Run without that and both scenarios still pass,
/// which is the honest shape — they cannot fail harder offline than online
/// when there is no network code to fail.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('IT-NAV-007 · content management works with the radios off', (
    tester,
  ) async {
    final robot = await startScenario(tester);
    final harness = harnessOf(robot);

    // Airplane mode is a precondition of the run, not a step — see the file
    // comment. AD-05 keeps `dio` out of the tree entirely, so what this asserts
    // is that nothing has crept in since.
    await robot.createRootDeck('Korean', scheduler: ItText.eightBox);
    await robot.openDeck('Korean');

    // Step 2.
    await robot.createSubDeck('Academic words');
    expect(
      find.text('Academic words'),
      findsWidgets,
      reason: 'offline create failed; ${robot.visibleText}',
    );

    // Step 1's other half: nothing asked the user to sign in or reconnect.
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

    // Step 3: create, edit and flag, all offline.
    await robot.openDeck('Academic words');
    await robot.createCard('abandon', 'từ bỏ');
    await robot.tapText('abandon');
    // Since M99.31 a tap opens the read-only detail; the editor is one
    // explicit action away (UC-19).
    await robot.tapBySemantics('Edit card');
    await robot.enterNthField(1, 'rời bỏ');
    await robot.tapText('Save changes');
    expect(find.text('rời bỏ'), findsWidgets);

    // Step 4: it survives a restart, still offline.
    await harness.restartApp();
    await robot.openDeck('Korean');
    await robot.openDeck('Academic words');
    expect(
      find.text('rời bỏ'),
      findsWidgets,
      reason: 'offline data did not survive restart; ${robot.visibleText}',
    );

    // Step 5: deleting works with no network.
    await robot.tapText('abandon');
    await robot.tapBySemantics('Edit card');
    await robot.scrollToText(ItText.deleteCard);
    await robot.tapText(ItText.deleteCard);
    // The confirm names where the card goes since M99.33 (BR-256).
    await robot.tapText('Move to Trash');
    // Trashing the deck's last card flips it back to `unset` (BR-260), so
    // the exit lands on the deck's own empty face, not a card list.
    expect(find.text('Nothing in here yet'), findsWidgets);
  });

  testWidgets('IT-CONT-008 · a whole session runs with the radios off', (
    tester,
  ) async {
    final robot = await startScenario(tester);
    final harness = harnessOf(robot);
    await seedDeck(robot, kStudyCards);

    // Steps 1 and 2: every stage's content is local, every turn is written
    // immediately, and the summary appears — with no network at all.
    await robot.tapTextContaining(ItText.studyLearnEntry);
    await robot.tapText(ItText.studyLearnNew);
    await robot.studyUntilFinished();
    expect(find.text(ItText.studyBackToDeck), findsOneWidget);

    // Step 3: the session stays `completed` across a reopen, and the schedule
    // it wrote is still there.
    await harness.restartApp();
    final sessions = await harness.database
        .customSelect('SELECT status FROM study_sessions')
        .get();
    expect(
      sessions.map((row) => row.read<String>('status')),
      everyElement('completed'),
    );

    // Step 4: the way back in offers no retry-your-connection wall.
    await robot.openDeck('Korean');
    await robot.openDeck('Chapter 1');
    for (final blocker in <String>['Retry', 'network', 'offline', 'Sign in']) {
      expect(
        find.textContaining(blocker),
        findsNothing,
        reason: 'a fake network wall appeared offline: "$blocker"',
      );
    }
  });
}
