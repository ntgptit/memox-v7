import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/domain/models/study_deck_context_model.dart';

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

  /// Moves [deckId] to Trash the way `markDeckDeleted` does: a batch row, then
  /// `delete_batch_id` on the deck. The row stays — that is the point of a
  /// tombstone, and the reason an unfiltered read still finds it (BR-256,
  /// BR-257).
  Future<void> tombstone(String deckId) async {
    await harness.db.customStatement(
      'INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) '
      "VALUES ('batch-1', 'deck', '$deckId', 0)",
    );
    // `customUpdate` with `updates:`, not `customStatement`. Drift only
    // invalidates a watched query when the write says which tables it touched,
    // and `customStatement` says nothing — so a tombstone written that way is
    // in the database and invisible to every stream, which is a property of
    // this test rather than of the app. The generated `markDecksDeleted`
    // declares `updates: {decks}`; this mirrors it.
    await harness.db.customUpdate(
      "UPDATE decks SET delete_batch_id = 'batch-1' WHERE id = '$deckId'",
      updates: {harness.db.decks},
    );
  }

  group('a deleted deck stops producing counts', () {
    test('the target in Trash reports nothing, not its tree', () async {
      // **The residual, stated as the number it used to return.** The outer
      // `d.delete_batch_id IS NULL` excludes the decks whose cards are counted;
      // it says nothing about the deck the counts claim to be *about*. So the
      // subquery resolved a tombstoned branch to its still-live root and the
      // screen went on showing the rest of the tree's workload under a name
      // that no longer existed.
      await seedTree(cardCount: 3);
      // A second card-holding branch, so the tree still has work after the
      // first one is deleted. Without it the counts fall to zero for the
      // uninteresting reason that nothing is left anywhere.
      await harness.db.customStatement(
        'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
        'content_type, scheduler_type, scheduler_version, '
        'scheduler_generation, created_at, updated_at) '
        "VALUES ('sibling', 'Chapter 2', 'root', 'root', 'card', "
        "'eight_box', 1, 1, 0, 0)",
      );
      await harness.db.customStatement(
        'INSERT INTO cards (id, deck_id, front, back, front_folded, '
        'back_folded, created_at, updated_at) '
        "VALUES ('s0', 'sibling', 'f', 'b', 'f', 'b', 0, 0)",
      );
      await harness.db.customStatement(
        'INSERT INTO card_study_states (card_id, scheduler_type, '
        'scheduler_version, scheduler_generation, answer_count, lapse_count, '
        'current_box) '
        "VALUES ('s0', 'eight_box', 1, 1, 0, 0, 1)",
      );

      await tombstone('child');

      final summary = await harness.repository
          .watchStudyEntry('child', now: StudyHarness.now)
          .first;

      expect(summary.newCount, 0, reason: 'the sibling owns those cards');
      expect(summary.dueCount, 0);
    });

    test('while the live sibling keeps counting its own', () async {
      // The control: the fix must exclude the deleted target, not break the
      // resolution for everyone.
      await seedTree(cardCount: 3);
      await tombstone('child');

      final fromRoot = await harness.repository
          .watchStudyEntry('root', now: StudyHarness.now)
          .first;

      // The root is alive, and its remaining live cards are none — the delete
      // marked the branch, and `d.delete_batch_id IS NULL` drops its cards.
      expect(fromRoot.newCount, 0);
    });

    test(
      'and the watched context reports the absence rather than hiding it',
      () async {
        // The other half of the same residual, one layer up: the stream used to
        // filter its `null`, so the event that says "deleted" was the one event
        // it would not carry.
        await seedTree(cardCount: 1);

        final contexts = <StudyDeckContextModel?>[];
        final subscription = harness.repository
            .watchDeckContext('child')
            .listen(contexts.add);
        await pumpEventQueue();
        expect(contexts.single?.deckName, 'Chapter 1');

        await tombstone('child');
        await pumpEventQueue();

        expect(
          contexts.last,
          isNull,
          reason: 'deletion has to reach the screen as a value it can act on',
        );
        await subscription.cancel();
      },
    );

    test(
      'and the one-shot read refuses it instead of resolving a root',
      () async {
        // `deckById` in the DAO was a hand-built select with no tombstone
        // predicate while its watched twin used the `.drift` statement that has
        // one — the same name answering two different questions. So a deck in
        // Trash was absent to the stream and present to every `Future` caller.
        await seedTree(cardCount: 1);
        await tombstone('child');

        await expectLater(
          harness.repository.deckContext('child'),
          throwsA(isA<NotFoundFailure>()),
        );
      },
    );
  });
}
