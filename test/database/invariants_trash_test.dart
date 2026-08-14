
import 'support/invariant_harness.dart';
import 'support/test_database.dart';

/// The five Trash invariants (BR-182…BR-193, AD-21), run against a real
/// database.
///
/// **Split from `invariants_test.dart` at the 400-line guard, on the seam the
/// suite already had.** Q31 and Q32 are the pair the whole one-column exclusion
/// strategy rests on: if either fires, `delete_batch_id IS NULL` has stopped
/// meaning "visible" and every active query in the app is quietly lying.
///
/// Each is checked both ways by the shared `invariant` helper — silent on a
/// valid tree, firing on its own defect. Cross-firing between invariants is
/// deliberately not asserted here; `invariants_test.dart` owns that check for
/// the whole set.
void main() {
  invariant(
    'Q31',
    'an active card sits inside a deleted deck (BR-182, BR-184)',
    breakIt: (db) async {
      // The deck goes to Trash and its card is left behind — the one shape
      // that would make `delete_batch_id IS NULL` stop meaning "visible".
      await insertDeleteBatch(
        db,
        id: 'batch-leaf',
        itemType: 'deck',
        rootItemId: 'leaf',
      );
      await markDecksDeleted(
        db,
        batchId: 'batch-leaf',
        deckIds: <String>['leaf'],
      );
    },
    expectOffenders: <String>['card-1'],
  );

  invariant(
    'Q32',
    'an active deck sits under a deleted deck (BR-182, BR-184)',
    breakIt: (db) async {
      await insertDeleteBatch(
        db,
        id: 'batch-branch',
        itemType: 'deck',
        rootItemId: 'branch',
      );
      await markDecksDeleted(
        db,
        batchId: 'batch-branch',
        deckIds: <String>['branch'],
      );
    },
    expectOffenders: <String>['leaf'],
  );

  invariant(
    'Q33',
    'a batch owns no rows at all (BR-191)',
    breakIt: (db) => insertDeleteBatch(
      db,
      id: 'batch-empty',
      itemType: 'deck',
      rootItemId: 'leaf',
    ),
    expectOffenders: <String>['batch-empty'],
  );

  invariant(
    'Q34',
    'a tombstone was deleted after its already-deleted ancestor (BR-184)',
    breakIt: (db) async {
      // `branch` went first, `leaf` a day later — the order BR-191's "eligible
      // ancestor implies eligible descendant" argument forbids.
      await insertDeleteBatch(
        db,
        id: 'batch-older',
        itemType: 'deck',
        rootItemId: 'branch',
        deletedAt: testNow,
      );
      await insertDeleteBatch(
        db,
        id: 'batch-newer',
        itemType: 'deck',
        rootItemId: 'leaf',
        deletedAt: testNow.add(const Duration(days: 1)),
      );
      await markDecksDeleted(
        db,
        batchId: 'batch-older',
        deckIds: <String>['branch'],
      );
      await markDecksDeleted(
        db,
        batchId: 'batch-newer',
        deckIds: <String>['leaf'],
      );
      await markCardsDeleted(
        db,
        batchId: 'batch-newer',
        cardIds: <String>['card-1'],
      );
    },
    expectOffenders: <String>['leaf'],
  );

  invariant(
    'Q35',
    'a batch names an item root that does not carry it (BR-182)',
    breakIt: (db) async {
      await insertDeleteBatch(
        db,
        id: 'batch-mislabelled',
        itemType: 'deck',
        rootItemId: 'branch',
      );
      // Rows exist for the batch — so Q33 stays silent — but not the row the
      // batch claims as its root.
      await markDecksDeleted(
        db,
        batchId: 'batch-mislabelled',
        deckIds: <String>['leaf'],
      );
      await markCardsDeleted(
        db,
        batchId: 'batch-mislabelled',
        cardIds: <String>['card-1'],
      );
    },
    expectOffenders: <String>['batch-mislabelled'],
  );
}
