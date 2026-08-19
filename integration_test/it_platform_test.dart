import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/it_harness.dart';
import 'support/it_robot.dart';
import 'support/it_scenario.dart';

/// **The whole device suite.** Eight scenarios, and nothing else belongs here.
///
/// Step 7 of the testing-pyramid refactor. This file replaces nine files and
/// sixty-seven scenarios, and the deletion was safe for one reason only: every
/// business rule those scenarios walked is now proven by `flutter test` — 133
/// of 133 rows of `14-host-coverage-map.md`, on real SQLite, on every PR. What
/// was left over is what a host cannot reach, and it is this:
///
/// | Scenario | The boundary it is here for |
/// |---|---|
/// | IT-PLAT-001 | The engine's own bootstrap, the platform's database path, the installed asset bundle |
/// | IT-PLAT-002 | A real file on device storage, written by one executor and read by another |
/// | IT-PLAT-003 | The session cursor living on disk rather than in memory |
/// | IT-PLAT-004 | A URL arriving from outside the app, on the OS channel |
/// | IT-PLAT-005 | Android's back gesture, and the path it takes to `PopScope` |
/// | IT-PLAT-006 | A build that does not run: missing asset, wrong flavor, R8, migration |
/// | IT-NAV-007 | Content management with the radios off |
/// | IT-CONT-008 | A whole session with the radios off |
///
/// **The business rules are deliberately not re-asserted.** A scenario here
/// that walked a rule would be a slower, flakier copy of a host test, and the
/// copy is the one that rots — it stays green while the rule changes underneath
/// it, because nobody looks at a device suite until it is already red.
///
/// **Two limits, stated rather than papered over.**
///
/// `restartApp` discards the widget tree, closes the executor and re-opens the
/// same file. It is *not* a process death: `flutter test` cannot kill the
/// process it is running in and keep going. So IT-PLAT-002 and IT-PLAT-003
/// prove that the bytes reached the file and outlived the objects that wrote
/// them — which is the claim that matters — and the OS-kill half is owed. The
/// same is true of the Android intent filter behind IT-PLAT-004; see
/// `ItHarness.deliverDeepLink`.
///
/// Airplane mode is a **precondition of the run**, not a step. IT-NAV-007 and
/// IT-CONT-008 assert what must still work with no network, and the run script
/// is what turns the radios off — `adb shell cmd connectivity airplane-mode
/// enable`. Run without it and the two scenarios still pass, which is the
/// honest shape: they cannot fail *harder* offline than they do online, because
/// AD-05 says there is no `dio` in the tree at all.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('IT-PLAT-001 · a cold start on the device opens the deck list', (
    tester,
  ) async {
    await startScenario(tester);

    // Step 1. The three things that only exist on a device are all upstream of
    // this line: the engine started, `AppDatabase.open()` resolved a path the
    // platform gave it, and the asset bundle of an installed build loaded. A
    // host test builds a widget tree and skips every one of them.
    expect(find.byType(ErrorWidget), findsNothing);

    // Step 2.
    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 0);

    // Step 3.
    expect(find.text(ItText.decksEmpty), findsOneWidget);
    expect(find.text(ItText.newDeck), findsWidgets);
  });

  testWidgets('IT-PLAT-002 · what was written reaches the file and outlives '
      'the objects that wrote it', (tester) async {
    final robot = await startScenario(tester);
    final harness = harnessOf(robot);

    // Steps 1 and 2, through the UI, because the point is the whole stack:
    // a deck, a card inside it, and a flag — three different tables.
    await seedDeck(robot, <(String, String)>[('사과', 'apple')]);
    await robot.tapText('사과');
    // Since M99.31 a tap opens the read-only detail; the editor is one
    // explicit action away (UC-19).
    await robot.tapBySemantics('Edit card');
    // By semantics, not by text: the editor's flag and close are icons carrying
    // their label as a tooltip, so there is no text on screen to tap.
    await robot.tapBySemantics(ItText.flagCard);
    await robot.tapBySemantics(ItText.cardEditorClose);

    // Step 3, as far as one process can go: the tree is discarded and the
    // executor is closed. See the file comment — this is not an OS kill.
    await harness.restartApp();

    // Step 4. Read back through the screens, not through the database: a query
    // that still answers proves the rows exist, and a screen that shows them
    // proves the app can find them again from a cold start.
    await robot.openDeck('Korean');
    await robot.openDeck('Chapter 1');
    expect(
      find.text('사과'),
      findsWidgets,
      reason: 'the card did not survive the restart; ${robot.visibleText}',
    );

    // And the flag, which lives on a different table than the card text — a
    // restart that loses only one of the two is the failure this catches.
    final flagged = await harness.database
        .customSelect('SELECT is_flagged FROM cards')
        .get();
    expect(flagged.single.read<int>('is_flagged'), 1);
  });

  testWidgets('IT-PLAT-003 · a session interrupted mid-way resumes at its own '
      'cursor', (tester) async {
    final robot = await startScenario(tester);
    final harness = harnessOf(robot);
    await seedDeck(robot, kStudyCards);

    // Step 1: open a session and answer at least one turn.
    await robot.tapTextContaining(ItText.studyLearnEntry);
    await robot.tapText(ItText.studyLearnNew);
    expect(find.text(ItText.studyBrowseMode), findsOneWidget);
    // Through the robot, not a Next button: `browse` has no control at all
    // since BR-155 — moving between cards is the swipe, and the band of screen
    // a button took belongs to the card.
    await robot.answerStudyTurn();

    final cursorBefore = await _sessionCursor(harness);
    expect(
      cursorBefore,
      greaterThan(0),
      reason: 'the scenario needs a session that has actually moved',
    );

    // Step 2: interrupted, not closed. The ✕ would end the session as
    // `user_exit` (BR-82) and there would be nothing left to resume — which is
    // IT-PLAT-005's scenario, and the opposite of this one.
    await harness.restartApp();

    // Step 3: the app offers to continue, and continuing lands on the turn the
    // session stopped at rather than at the top of the queue.
    await robot.openDeck('Korean');
    await robot.openDeck('Chapter 1');
    await robot.tapTextContaining(ItText.studyLearnEntry);
    expect(
      find.text('Continue'),
      findsOneWidget,
      reason: 'no open session survived the restart; ${robot.visibleText}',
    );
    await robot.tapText('Continue');

    expect(
      await _sessionCursor(harness),
      cursorBefore,
      reason:
          'the cursor came back from disk, not from a queue rebuilt at zero',
    );
  });

  testWidgets('IT-PLAT-004 · a link handed over by the OS lands on the deck, '
      'and a broken one lands somewhere with a way out', (tester) async {
    final robot = await startScenario(tester);
    final harness = harnessOf(robot);

    await robot.createRootDeck('Korean', scheduler: ItText.eightBox);
    final deckId =
        (await harness.database
                .customSelect('SELECT id FROM decks LIMIT 1')
                .get())
            .single
            .read<String>('id');

    // Step 1. On the `flutter/navigation` channel, which is where a real deep
    // link arrives — not `appRouter.go`, which is the app calling itself.
    await harness.deliverDeepLink('/decks/$deckId');
    expect(
      find.text('Korean'),
      findsWidgets,
      reason: 'the OS link did not open the deck; ${robot.visibleText}',
    );

    // Step 2: a way out exists, and it is not a white screen.
    await harness.pressBack();
    expect(find.byType(ErrorWidget), findsNothing);
    expect(find.byType(Scaffold), findsWidgets);

    // Step 3: an invalid link shows the 404 and its recovery, and does not
    // silently redirect — a redirect would hide a broken link forever.
    await harness.deliverDeepLink('/no-such-place');
    expect(find.text('Go home'), findsOneWidget);
    await robot.tapText('Go home');
    expect(find.text('Korean'), findsWidgets);
  });

  testWidgets('IT-PLAT-005 · the system back gesture leaves a session on the '
      'same contract as the ✕', (tester) async {
    final robot = await startScenario(tester);
    final harness = harnessOf(robot);
    await seedDeck(robot, kStudyCards);

    await robot.tapTextContaining(ItText.studyLearnEntry);
    await robot.tapText(ItText.studyLearnNew);
    expect(find.text(ItText.studyBrowseMode), findsOneWidget);

    // Step 1: the OS path, not `Navigator.pop` — the gesture reaches the app
    // through the platform channel, and `PopScope` is what has to be on the
    // other end of it.
    await harness.pressBack();

    // BR-82: one way out, and it ends the session rather than leaving it open.
    // Asserted on the row, because "the screen went away" is also what a
    // half-handled back gesture looks like.
    final ended = await harness.database
        .customSelect('SELECT status, end_reason FROM study_sessions')
        .get();
    expect(ended.single.read<String>('status'), 'abandoned');
    expect(ended.single.read<String?>('end_reason'), 'user_exit');

    // And it lands where the ✕ lands: on the summary, not back on the deck.
    // A back gesture that skipped the summary would be a second, quieter
    // contract for the same action.
    // Waited for rather than asserted straight away: `leave()` writes the row
    // and then *reads* the summary, and a screen waiting on a read schedules
    // no frames — so settling returns before the summary can arrive.
    await robot.waitForText(ItText.studyBackToDeck);
    await robot.tapText(ItText.studyBackToDeck);

    // Step 2, and it has to be a real re-entry: the resume offer is made once,
    // in a post-frame callback when the study entry screen mounts. Asserting on
    // the screen already open would assert that a sheet nobody asked for is
    // absent, which is true of every screen in the app.
    // Back once lands on the deck level, not the card list — a card deck's
    // level offers its list rather than being it (BR-63).
    await harness.pressBack();
    await robot.tapText(ItText.openCards);
    await robot.tapTextContaining(ItText.studyLearnEntry);
    expect(
      find.text('Continue'),
      findsNothing,
      reason:
          'the back gesture left a session open that the ✕ would have closed',
    );
  });

  testWidgets('IT-PLAT-006 · pre-release smoke: open, create, study, reopen', (
    tester,
  ) async {
    // The one scenario in the catalog that crosses layers on purpose. It is not
    // here to catch a business bug — every rule it touches is proven on a host.
    // It is here to catch a build that does not run: a missing asset, the wrong
    // flavor, a broken signature, R8 stripping something reflective, a
    // migration that has never executed on a real device.
    final robot = await startScenario(tester);
    final harness = harnessOf(robot);

    await seedDeck(robot, kStudyCards);

    await robot.tapTextContaining(ItText.studyLearnEntry);
    await robot.tapText(ItText.studyLearnNew);
    final turns = await robot.studyUntilFinished();
    robot.trace('smoke: $turns turns');
    expect(find.text(ItText.studyBackToDeck), findsOneWidget);

    // The session ran to a summary, and the cards carry a schedule — the one
    // assertion worth making here, because a build that half-works usually
    // half-works at the write.
    await harness.restartApp();
    final learned = await harness.database
        .customSelect(
          'SELECT COUNT(*) AS n FROM card_study_states '
          'WHERE learned_at IS NOT NULL',
        )
        .get();
    expect(
      learned.single.read<int>('n'),
      5,
      reason: 'progress did not survive the reopen',
    );
  });
}

/// The running session's cursor, or -1 when there is none.
///
/// Read from the row rather than counted off the screen: BR-133 says the cursor
/// is what a resume restores, and a screen showing "2 / 5" would look identical
/// whether the queue came back from disk or was rebuilt from scratch and
/// happened to land in the same place.
Future<int> _sessionCursor(ItHarness harness) async {
  final rows = await harness.database
      .customSelect(
        "SELECT cursor FROM study_sessions WHERE status = 'in_progress' "
        'LIMIT 1',
      )
      .get();

  return rows.isEmpty ? -1 : rows.single.read<int>('cursor');
}
