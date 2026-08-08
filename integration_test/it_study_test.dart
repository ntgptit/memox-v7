import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/it_harness.dart';
import 'support/it_robot.dart';

/// UC-05 through the screens, on a real database (M5.15).
///
/// **M5.6 already proved these rules at the use-case level and wrote down that
/// the UI half was still owed.** This is that half, and it does not re-prove
/// what M5.6 proved: what it adds is that a person with a phone can reach each
/// of them — the path from a deck to a session, the five stages in order, and
/// the two refusals that are only visible as *absences* on a screen.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final harnesses = <ItRobot, ItHarness>{};

  Future<ItRobot> start(WidgetTester tester) async {
    final harness = await ItHarness.open(tester);
    addTearDown(harness.dispose);
    await harness.launchApp();

    final robot = ItRobot(tester, harness);
    harnesses[robot] = harness;

    return robot;
  }

  /// The database behind a robot, for the assertions a screen cannot make.
  ///
  /// `learned_at` and `due_at` are not on any screen — BR-144 sets them as the
  /// consequence of finishing, and the UI shows only that the counts changed.
  ItHarness harnessOf(ItRobot robot) => harnesses[robot]!;

  /// A card deck holding [fronts], reached the way a person reaches it.
  Future<void> seedDeck(ItRobot robot, List<(String, String)> cards) async {
    await robot.createRootDeck('Korean', scheduler: ItText.eightBox);
    await robot.openDeck('Korean');
    await robot.createSubDeck('Chapter 1');
    await robot.openDeck('Chapter 1');
    for (final (front, back) in cards) {
      await robot.createCard(front, back);
    }
  }

  testWidgets('a new deck offers a way into learning, and it opens', (
    tester,
  ) async {
    // The link this milestone had to build before it could test anything. The
    // deck tile's own Study button appears only when something is **due**
    // (BR-150), so a deck whose cards are all new had no path to a session at
    // all — the card list's progress panel is where a first session starts.
    final robot = await start(tester);
    await seedDeck(robot, <(String, String)>[
      ('사과', 'apple'),
      ('물', 'water'),
      ('책', 'book'),
    ]);

    await robot.tapTextContaining(ItText.studyLearnEntry);
    robot.trace('study entry');

    // BR-150's two numbers, and BR-145's absence beside them: three new, none
    // due, and therefore no way to review.
    expect(find.text('New 3'), findsOneWidget);
    expect(find.text('Due 0'), findsOneWidget);
    expect(find.text(ItText.studyLearnNew), findsOneWidget);
    expect(find.textContaining('Nothing to review yet'), findsOneWidget);
  });

  testWidgets('a learning session walks the algorithm-s stages in order', (
    tester,
  ) async {
    // BR-110: `eight_box` runs browse → match → guess → recall → fill. Five
    // cards is the smallest set that clears every stage-s threshold at once —
    // `guess` needs five distinct meanings (BR-121) and `match` needs two pairs
    // (BR-153).
    final robot = await start(tester);
    await seedDeck(robot, <(String, String)>[
      ('사과', 'apple'),
      ('물', 'water'),
      ('책', 'book'),
      ('산', 'mountain'),
      ('바다', 'sea'),
    ]);

    await robot.tapTextContaining(ItText.studyLearnEntry);
    await robot.tapText(ItText.studyLearnNew);
    robot.trace('session opened');

    // The frame the five screens share (M5.18), and the first stage of the
    // chain: browse, which grades nothing (BR-111).
    expect(find.textContaining('Chapter 1 · Learning'), findsOneWidget);
    expect(find.text(ItText.studyBrowseMode), findsOneWidget);
    expect(find.text(ItText.studyBrowseHint), findsOneWidget);

    // `browse` shows both sides at once (BR-112) and offers one way forward.
    expect(find.text('TERM'), findsOneWidget);
    expect(find.text('MEANING'), findsOneWidget);
    expect(find.text(ItText.studyContinue), findsOneWidget);
  });

  testWidgets('a card with no example still reaches the fill stage-s queue', (
    tester,
  ) async {
    // BR-114 and BR-144, through the UI this time: `fill` is the one stage a
    // card can be missing data for, and a card it skips must still finish the
    // chain with the rest rather than sitting `pending` forever.
    //
    // None of these cards carries an example, so `fill` takes none of them —
    // and the session still opens and still runs, which is the claim.
    final robot = await start(tester);
    await seedDeck(robot, <(String, String)>[
      ('사과', 'apple'),
      ('물', 'water'),
      ('책', 'book'),
      ('산', 'mountain'),
      ('바다', 'sea'),
    ]);

    await robot.tapTextContaining(ItText.studyLearnEntry);
    await robot.tapText(ItText.studyLearnNew);

    expect(find.text(ItText.studyBrowseMode), findsOneWidget);
    expect(find.textContaining('cannot be shown here'), findsNothing);
  });

  testWidgets(
    'leaving a session ends it, and the next launch offers to resume',
    (tester) async {
      // BR-82 and BR-103, and the difference between them is the point: the ✕
      // ends the session as `abandoned`/`user_exit`, so what the app offers next
      // is the three paths rather than a session it quietly kept open.
      final robot = await start(tester);
      await seedDeck(robot, <(String, String)>[
        ('사과', 'apple'),
        ('물', 'water'),
        ('책', 'book'),
        ('산', 'mountain'),
        ('바다', 'sea'),
      ]);

      await robot.tapTextContaining(ItText.studyLearnEntry);
      await robot.tapText(ItText.studyLearnNew);
      expect(find.text(ItText.studyBrowseMode), findsOneWidget);

      await robot.tapBySemantics(ItText.studyClose);
      robot.trace('after leaving');

      // The summary, not the session: it says what happened rather than
      // pretending nothing did (BR-79, BR-80).
      expect(find.text(ItText.studyBrowseHint), findsNothing);
    },
  );

  testWidgets(
    'a learning session runs the whole chain and schedules the cards',
    (tester) async {
      // **The part M5.15 left owed, and the only claim that needs the whole
      // chain.** BR-144 makes finishing an *event*, not an answer: the card
      // takes `learned_at` and its first schedule once it has cleared every
      // stage it joined — so nothing short of walking to the end observes it.
      //
      // None of these cards carries an example, so `fill` takes none of them
      // (BR-114) and the chain is browse → match → guess → recall. That they
      // still finish is BR-114's other half, through the UI this time.
      final robot = await start(tester);
      await seedDeck(robot, <(String, String)>[
        ('사과', 'apple'),
        ('물', 'water'),
        ('책', 'book'),
        ('산', 'mountain'),
        ('바다', 'sea'),
      ]);

      await robot.tapTextContaining(ItText.studyLearnEntry);
      await robot.tapText(ItText.studyLearnNew);

      final turns = await robot.studyUntilFinished();
      robot.trace('after $turns turns');

      expect(find.text(ItText.studyBackToDeck), findsOneWidget);

      // **One turn per card per graded stage, and this is the assertion that
      // matters.** Before the board read its ticks from the queue, `match`
      // recorded nine turns for five cards: the screen unmounts the board
      // between turns, every paired tile came back tappable, and the same pair
      // could be answered again.
      final byMode = await harnessOf(robot).database
          .customSelect(
            'SELECT mode, COUNT(*) AS turns, COUNT(DISTINCT card_id) AS cards '
            'FROM study_answers GROUP BY mode ORDER BY mode',
          )
          .get();

      expect(
        <String, List<int>>{
          for (final row in byMode)
            row.read<String>('mode'): <int>[
              row.read<int>('turns'),
              row.read<int>('cards'),
            ],
        },
        <String, List<int>>{
          'guess': <int>[5, 5],
          'match': <int>[5, 5],
          'recall': <int>[5, 5],
        },
        reason: 'one turn per card per graded stage; browse records none',
      );

      final states = await harnessOf(robot).database
          .customSelect('SELECT learned_at, due_at FROM card_study_states')
          .get();

      expect(states, hasLength(5));
      for (final row in states) {
        expect(
          row.read<int?>('learned_at'),
          isNotNull,
          reason: 'a card finished the chain without being marked learned',
        );
        // BR-105 and BR-144: the first schedule is the start of the next study
        // day, never "twenty-four hours from now".
        expect(row.read<int?>('due_at'), isNotNull);
        expect(
          row.read<int>('due_at'),
          greaterThan(row.read<int>('learned_at')),
        );
      }
    },
  );

  testWidgets('and a card just learned cannot be reviewed the same day', (
    tester,
  ) async {
    // BR-145, and it is only observable *after* the chain: the review entry has
    // to be absent while the cards are due tomorrow rather than today.
    final robot = await start(tester);
    await seedDeck(robot, <(String, String)>[
      ('사과', 'apple'),
      ('물', 'water'),
      ('책', 'book'),
      ('산', 'mountain'),
      ('바다', 'sea'),
    ]);

    await robot.tapTextContaining(ItText.studyLearnEntry);
    await robot.tapText(ItText.studyLearnNew);
    await robot.studyUntilFinished();
    await robot.tapText(ItText.studyBackToDeck);

    expect(find.text('New 0'), findsOneWidget);
    expect(find.text('Due 0'), findsOneWidget);
    expect(find.textContaining('Nothing to review yet'), findsOneWidget);
  });
}
