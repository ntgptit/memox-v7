import 'package:flutter_test/flutter_test.dart';

import 'support/study_harness.dart';

/// What the study entry counts, and which deck it counts for (BR-06, BR-57).
///
/// **The bug this file exists for was invisible to every test that had one.**
/// `studyEntryCounts` filters on `root_deck_id`, and the screen handed it
/// whatever deck the user had open. Every caller until M5.15 happened to pass a
/// root, so the query looked right — and a study entry opened on a *sub-deck*
/// matched nothing and told the learner every card had already been learned. A
/// screen showing 0 and 0 is not an error state; it is a wrong answer that reads
/// like a correct one, which is why only a test that opens a branch can catch it.
///
/// CI does not run the integration suite, so the claim lives here too: the
/// emulator run proved the path, this proves the query.
void main() {
  late StudyHarness harness;

  setUp(() => harness = StudyHarness());
  tearDown(() => harness.close());

  /// A root with a card-holding child, and [cardCount] cards inside the child.
  Future<void> seedTree({required int cardCount}) async {
    await harness.db.customStatement(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'created_at, updated_at) '
      "VALUES ('root', 'Korean', 'root', 'deck', 'eight_box', 1, 1, 0, 0)",
    );
    await harness.db.customStatement(
      'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
      'content_type, scheduler_type, scheduler_version, scheduler_generation, '
      'created_at, updated_at) '
      "VALUES ('child', 'Chapter 1', 'root', 'root', 'card', 'eight_box', "
      '1, 1, 0, 0)',
    );

    for (var i = 0; i < cardCount; i++) {
      await harness.db.customStatement(
        'INSERT INTO cards (id, deck_id, front, back, front_folded, '
        'back_folded, created_at, updated_at) '
        "VALUES ('c$i', 'child', 'front$i', 'back$i', 'front$i', 'back$i', "
        '$i, $i)',
      );
      await harness.db.customStatement(
        'INSERT INTO card_study_states (card_id, scheduler_type, '
        'scheduler_version, scheduler_generation, answer_count, lapse_count, '
        'current_box) '
        "VALUES ('c$i', 'eight_box', 1, 1, 0, 0, 1)",
      );
    }
  }

  test('a branch counts the tree it belongs to, not nothing', () async {
    await seedTree(cardCount: 3);

    final summary = await harness.repository
        .watchStudyEntry('child', now: StudyHarness.now)
        .first;

    expect(summary.newCount, 3);
    expect(summary.dueCount, 0);
  });

  test('and the root it resolves to agrees with it', () async {
    // The counterpart. Without it, "a branch counts 3" also passes on a query
    // that ignores its argument entirely and counts every card in the database.
    await seedTree(cardCount: 3);

    final fromRoot = await harness.repository
        .watchStudyEntry('root', now: StudyHarness.now)
        .first;
    final fromBranch = await harness.repository
        .watchStudyEntry('child', now: StudyHarness.now)
        .first;

    expect(fromBranch.newCount, fromRoot.newCount);
    expect(fromBranch.dueCount, fromRoot.dueCount);
  });

  test('a deck of another tree counts none of it', () async {
    await seedTree(cardCount: 3);
    await harness.db.customStatement(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'created_at, updated_at) '
      "VALUES ('other', 'Japanese', 'other', 'card', 'eight_box', 1, 1, 0, 0)",
    );

    final summary = await harness.repository
        .watchStudyEntry('other', now: StudyHarness.now)
        .first;

    expect(summary.newCount, 0);
  });
}
