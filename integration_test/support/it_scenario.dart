import 'package:flutter_test/flutter_test.dart';

import 'it_harness.dart';
import 'it_robot.dart';

/// What every `DEVICE-E2E` scenario needs before it can do anything.
///
/// **Shared rather than copied, because there are only eight scenarios and two
/// files.** A second copy of "open the harness, launch, wrap in a robot" is the
/// kind of duplication that stays correct right up until the harness gains a
/// step — and then only one of the copies gets it.
final Map<ItRobot, ItHarness> _harnesses = <ItRobot, ItHarness>{};

/// Opens the harness, launches the real app, and returns the robot driving it.
///
/// Teardown is registered here so `CLEAN-RESET` still runs when a scenario
/// fails part-way — a scenario that dies mid-edit otherwise leaves an open
/// sheet and its rows for the next one to inherit.
Future<ItRobot> startScenario(WidgetTester tester) async {
  final harness = await ItHarness.open(tester);
  addTearDown(harness.dispose);
  await harness.launchApp();

  final robot = ItRobot(tester, harness);
  _harnesses[robot] = harness;

  return robot;
}

/// The database behind a robot, for the assertions a screen cannot make.
///
/// `status`, `end_reason`, `cursor` and `learned_at` are on no screen: they are
/// what the screen is evidence *of*, and a device scenario that only read the
/// screen could not tell "the session ended" from "the screen went away".
ItHarness harnessOf(ItRobot robot) => _harnesses[robot]!;

/// A card deck holding [cards], reached the way a person reaches it.
Future<void> seedDeck(ItRobot robot, List<(String, String)> cards) async {
  await robot.createRootDeck('Korean', scheduler: ItText.eightBox);
  await robot.openDeck('Korean');
  await robot.createSubDeck('Chapter 1');
  await robot.openDeck('Chapter 1');
  for (final (front, back) in cards) {
    await robot.createCard(front, back);
  }
}

/// The five cards every study scenario needs: `guess` wants five distinct
/// meanings (BR-121) and `match` wants two pairs (BR-153), so five is the
/// smallest set that clears every stage at once.
const List<(String, String)> kStudyCards = <(String, String)>[
  ('사과', 'apple'),
  ('물', 'water'),
  ('책', 'book'),
  ('산', 'mountain'),
  ('바다', 'sea'),
];
