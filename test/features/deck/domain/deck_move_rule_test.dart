import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_move_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

/// UC-09 step 2, tested where it now lives — once.
///
/// The rule used to exist twice: as a pure function behind the move picker, and
/// again as eight `ConflictFailure(message: '<sentence>')` throws inside
/// `moveDeck`, with no import between them. Two spellings of one rule set, free
/// to drift, and `deck_move_target_test.dart` only ever exercised the first.
///
/// Now both callers reach [deckMoveRejection], so these cases cover the picker
/// *and* the write path. The repository's job is reduced to gathering the facts,
/// which is what `deck_repository_move_test.dart` asserts against real SQLite.
void main() {
  DeckEntity deck({
    required String id,
    String? parentDeckId,
    String? rootDeckId,
    DeckContentType contentType = DeckContentType.deck,
    SchedulerType? schedulerType,
    int? schedulerGeneration,
  }) => DeckEntity(
    id: id,
    name: 'deck $id',
    parentDeckId: parentDeckId,
    rootDeckId: rootDeckId ?? id,
    contentType: contentType,
    schedulerType: schedulerType,
    schedulerGeneration: schedulerGeneration,
    firstAnsweredAt: null,
    createdAt: DateTime.utc(2026, 7, 30),
    updatedAt: DateTime.utc(2026, 7, 30),
  );

  /// The happy path, with one fact overridable per case.
  DeckMoveRejection? rejectionFor({
    DeckEntity? source,
    DeckEntity? target,
    bool isTargetInSourceSubtree = false,
    SchedulerType? sourceRootScheduler = SchedulerType.eightBox,
    int? sourceRootGeneration = 1,
    SchedulerType? targetRootScheduler = SchedulerType.eightBox,
    int? targetRootGeneration = 1,
    int targetDepth = 2,
    int sourceSubtreeHeight = 1,
  }) => deckMoveRejection(
    source: source ?? deck(id: 's', parentDeckId: 'r1', rootDeckId: 'r1'),
    target: target ?? deck(id: 't', parentDeckId: 'r2', rootDeckId: 'r2'),
    isTargetInSourceSubtree: isTargetInSourceSubtree,
    sourceRootScheduler: sourceRootScheduler,
    sourceRootGeneration: sourceRootGeneration,
    targetRootScheduler: targetRootScheduler,
    targetRootGeneration: targetRootGeneration,
    targetDepth: targetDepth,
    sourceSubtreeHeight: sourceSubtreeHeight,
  );

  test('a legal move is not rejected', () {
    expect(rejectionFor(), isNull);
  });

  group('every rejection has a case, in UC-09 order', () {
    test('a root cannot be moved (BR-06)', () {
      // Unreachable from the picker — it is not offered for a root — but the
      // rule lived only in the repository before, where the picker could never
      // see it. Now there is one home for it.
      expect(
        rejectionFor(source: deck(id: 's')),
        DeckMoveRejection.sourceIsRoot,
      );
    });

    test('a deck cannot be moved into itself (BR-70)', () {
      final same = deck(id: 'x', parentDeckId: 'r1', rootDeckId: 'r1');

      expect(
        rejectionFor(source: same, target: same),
        DeckMoveRejection.itself,
      );
    });

    test('a deck cannot be moved into its own subtree (BR-69, BR-70)', () {
      expect(
        rejectionFor(isTargetInSourceSubtree: true),
        DeckMoveRejection.ownDescendant,
      );
    });

    test('moving into the current parent is a no-op', () {
      expect(
        rejectionFor(
          source: deck(id: 's', parentDeckId: 't', rootDeckId: 'r1'),
        ),
        DeckMoveRejection.alreadyParent,
      );
    });

    test('a target holding cards cannot hold decks (BR-64)', () {
      expect(
        rejectionFor(
          target: deck(
            id: 't',
            parentDeckId: 'r2',
            rootDeckId: 'r2',
            contentType: DeckContentType.card,
          ),
        ),
        DeckMoveRejection.holdsCards,
      );
    });

    test('a different scheduler is refused, never converted (BR-73)', () {
      expect(
        rejectionFor(targetRootScheduler: SchedulerType.sm2),
        DeckMoveRejection.differentScheduler,
      );
    });

    test('an unreadable root is refused as a scheduler mismatch', () {
      // A missing root means the snapshot is inconsistent, or a row vanished
      // mid-transaction. Refusing is the safe direction to be wrong in.
      expect(
        rejectionFor(targetRootScheduler: null),
        DeckMoveRejection.differentScheduler,
      );
    });

    test('a different generation is refused (BR-74)', () {
      expect(
        rejectionFor(targetRootGeneration: 2),
        DeckMoveRejection.differentGeneration,
      );
    });

    test('the resulting depth is target depth plus subtree height (BR-55)', () {
      // At the limit exactly: allowed. `sourceSubtreeHeight` is left at its
      // default of 1 — a lone deck is a subtree of height one.
      expect(rejectionFor(targetDepth: DeckEntity.maxTreeDepth - 1), isNull);
      // One past it: refused.
      expect(
        rejectionFor(
          targetDepth: DeckEntity.maxTreeDepth - 1,
          sourceSubtreeHeight: 2,
        ),
        DeckMoveRejection.tooDeep,
      );
    });
  });

  test('the order is specific-first, so the reason is the useful one', () {
    // A target that is both inside the subtree AND on a different scheduler
    // reports the cycle, because that is the fact the user needs. Both callers
    // run this same sequence, which is what makes the picker and the write path
    // agree on what to say.
    expect(
      rejectionFor(
        isTargetInSourceSubtree: true,
        targetRootScheduler: SchedulerType.sm2,
      ),
      DeckMoveRejection.ownDescendant,
    );
  });

  test('every enum value is reachable through this function', () {
    // Guards against a value added to the enum with no rule producing it — a
    // reason that can never be shown, which reads as coverage in the ARB file.
    final produced = <DeckMoveRejection>{
      rejectionFor(source: deck(id: 's'))!,
      rejectionFor(
        source: deck(id: 'x', parentDeckId: 'r1'),
        target: deck(id: 'x', parentDeckId: 'r1'),
      )!,
      rejectionFor(isTargetInSourceSubtree: true)!,
      rejectionFor(
        source: deck(id: 's', parentDeckId: 't'),
      )!,
      rejectionFor(
        target: deck(
          id: 't',
          parentDeckId: 'r2',
          contentType: DeckContentType.card,
        ),
      )!,
      rejectionFor(targetRootScheduler: SchedulerType.sm2)!,
      rejectionFor(targetRootGeneration: 2)!,
      rejectionFor(
        targetDepth: DeckEntity.maxTreeDepth,
        sourceSubtreeHeight: 2,
      )!,
    };

    expect(produced, DeckMoveRejection.values.toSet());
  });
}
