import '../entities/deck_entity.dart';
import '../models/deck_content_type_model.dart';
import '../models/scheduler_type_model.dart';

/// Why a deck cannot receive a move (UC-09 step 2).
///
/// An enum rather than a message, because the copy is the screen's job and the
/// reason is the domain's. It carries the *first* rule that fails, in the order
/// UC-09 lists them, so the explanation the user reads is the one the repository
/// would also produce.
enum DeckMoveRejection {
  /// The deck being moved is a root. Moving it would put scheduler columns on a
  /// non-root (BR-06); demoting a root is a separate decision, not a move.
  ///
  /// Unreachable from the picker, which is not offered for a root
  /// (`if (!deck.isRoot)` in `deck_actions_widget.dart`). It exists so the rule
  /// has one home rather than living only in the repository, where the picker
  /// could never see it.
  sourceIsRoot,

  /// The target is the deck being moved (BR-70).
  itself,

  /// The target sits inside the deck being moved — the cycle guard (BR-69,
  /// BR-70).
  ownDescendant,

  /// The target already holds cards, so it cannot hold decks (BR-64).
  holdsCards,

  /// The target's root uses a different scheduler (BR-73, BR-74).
  differentScheduler,

  /// The target's root is on a different learning cycle (BR-74).
  differentGeneration,

  /// The move would nest deeper than [DeckEntity.maxTreeDepth] (BR-55).
  tooDeep,

  /// The target is already this deck's parent, so the move is a no-op.
  alreadyParent,
}

/// UC-09 step 2, once.
///
/// **Why this is a free function taking facts rather than a method on anything.**
/// Two callers need this decision and they gather its inputs in completely
/// different ways:
///
/// - the move picker (`buildDeckMoveTargets`) has every deck already loaded in
///   one query and derives depth by walking parent pointers in memory;
/// - `moveDeck` is inside a write transaction and asks SQLite for each fact
///   separately, because loading every deck inside a write would be wasteful and
///   the guards must run before the first mutation.
///
/// So the shared thing is not the loading, it is the **decision**. Parameterising
/// on facts rather than on a tree is what lets both callers reach it. Until M4.10
/// they did not: the picker had this logic and the repository had a second copy
/// as eight `ConflictFailure(message: '<sentence>')` throws, with no import
/// between them — two spellings of one rule set, free to drift.
///
/// Every parameter is a fact, not a source of facts. That is deliberate: it keeps
/// this function pure, so `deck_move_target_test.dart` can exercise all eight
/// rejections with no database and no widget.
DeckMoveRejection? deckMoveRejection({
  required DeckEntity source,
  required DeckEntity target,
  required bool isTargetInSourceSubtree,
  required SchedulerType? sourceRootScheduler,
  required int? sourceRootGeneration,
  required SchedulerType? targetRootScheduler,
  required int? targetRootGeneration,
  required int targetDepth,
  required int sourceSubtreeHeight,
}) {
  // The order is UC-09 step 2's order. The first failure is the one reported, so
  // the reason a user sees is the most specific one that applies — and both
  // callers report the same one because they run the same sequence.
  if (source.isRoot) return DeckMoveRejection.sourceIsRoot;
  if (target.id == source.id) return DeckMoveRejection.itself;
  if (isTargetInSourceSubtree) return DeckMoveRejection.ownDescendant;
  // `holdsCards` before `alreadyParent`, and the order is load-bearing for
  // restore, not for move. On a live move the parent of `source` can never be
  // `card`-typed while holding `source`, so the reorder changes nothing
  // there (invariant Q3 in `test/database/invariant_queries.dart` is the
  // mechanical proof). On a restore/undo the origin parent may have
  // emptied to `unset`
  // and taken cards since (BR-260, BR-61) — and the restore path treats
  // `alreadyParent` as a non-blocking answer, so reporting it first would
  // wave a subtree into a card deck (BR-64, invariant Q3).
  if (target.contentType == DeckContentType.card) {
    return DeckMoveRejection.holdsCards;
  }
  if (target.id == source.parentDeckId) return DeckMoveRejection.alreadyParent;

  // A missing root means the snapshot is inconsistent, or a row vanished mid
  // transaction. Refuse rather than allow a move whose scheduler pairing cannot
  // be checked — the safe direction to be wrong in.
  if (sourceRootScheduler == null || targetRootScheduler == null) {
    return DeckMoveRejection.differentScheduler;
  }
  if (sourceRootScheduler != targetRootScheduler) {
    return DeckMoveRejection.differentScheduler;
  }
  if (sourceRootGeneration != targetRootGeneration) {
    return DeckMoveRejection.differentGeneration;
  }

  // BR-55 — the deepest resulting level is the target's level plus the subtree's
  // height, with the source itself counting as height 1.
  if (targetDepth + sourceSubtreeHeight > DeckEntity.maxTreeDepth) {
    return DeckMoveRejection.tooDeep;
  }

  return null;
}
