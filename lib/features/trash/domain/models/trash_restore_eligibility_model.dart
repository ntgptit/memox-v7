import '../../../deck/domain/entities/deck_entity.dart';
import '../../../deck/domain/failures/deck_move_failure.dart';

/// One candidate for restoring a deck subtree, and whether it would be accepted.
final class TrashDeckCandidate {
  const TrashDeckCandidate({
    required this.deck,
    required this.depth,
    required this.rejection,
  });

  final DeckEntity deck;

  /// Level in the tree, root = 1 (BR-55) — the picker indents by it.
  final int depth;

  /// Null when the restore would be accepted.
  final DeckMoveRejection? rejection;

  bool get isEligible => rejection == null;
}

/// Where a deleted sub-deck may be restored to (BR-261).
///
/// **The rule is `deckMoveRejection`, unchanged.** BR-261 says restore uses the
/// move rule set, and this function only does the half `buildDeckMoveTargets`
/// calls "the loading": it rebuilds depth from a flat list of active decks and
/// hands the facts over. Reimplementing the decision would be the second
/// spelling that drifts — which is exactly the mistake M4.10 undid for the move
/// picker itself.
///
/// **It cannot reuse `buildDeckMoveTargets` even so**, and the reason is
/// structural rather than stylistic: that function derives the source's subtree
/// and its height from the list it is given, and a deleted source is not in
/// that list — every active deck is, by definition, outside it. So the height
/// arrives here as [sourceSubtreeHeight], measured over the batch's own rows,
/// and subtree membership is simply false: no active deck can sit under a
/// tombstone (invariant 32).
///
/// **`alreadyParent` is not a rejection here.** For a move it means "this
/// changes nothing"; for a restore, putting the item back where it came from is
/// the single most likely thing the user wants (BR-262 only forbids choosing it
/// *for* them).
List<TrashDeckCandidate> buildTrashDeckCandidates({
  required DeckEntity source,
  required DeckEntity? sourceRoot,
  required List<DeckEntity> activeDecks,
  required int sourceSubtreeHeight,
}) {
  // A root deck has exactly one destination and it is not in this list
  // (BR-261); `TrashTopLevelTarget` is the whole answer there.
  if (source.isRoot) return const <TrashDeckCandidate>[];

  final byId = <String, DeckEntity>{
    for (final deck in activeDecks) deck.id: deck,
  };

  final candidates = <TrashDeckCandidate>[
    for (final deck in activeDecks)
      TrashDeckCandidate(
        deck: deck,
        depth: _depthOf(deck, byId),
        rejection: _rejectionFor(
          source: source,
          sourceRoot: sourceRoot,
          target: deck,
          byId: byId,
          sourceSubtreeHeight: sourceSubtreeHeight,
        ),
      ),
  ];

  // Tree order, so indentation reads as a hierarchy rather than as a flat list
  // with gaps — the same ordering the move picker uses.
  candidates.sort((a, b) {
    final byRoot = a.deck.rootDeckId.compareTo(b.deck.rootDeckId);
    if (byRoot != 0) return byRoot;

    return a.deck.createdAt.compareTo(b.deck.createdAt);
  });

  return List<TrashDeckCandidate>.unmodifiable(candidates);
}

DeckMoveRejection? _rejectionFor({
  required DeckEntity source,
  required DeckEntity? sourceRoot,
  required DeckEntity target,
  required Map<String, DeckEntity> byId,
  required int sourceSubtreeHeight,
}) {
  final targetRoot = byId[target.rootDeckId];
  final rejection = deckMoveRejection(
    source: source,
    target: target,
    // No active deck can be inside a deleted subtree (invariant 32), so the
    // cycle guard has nothing to find. Stated rather than assumed: if that
    // invariant ever broke, this would be the line that made it dangerous.
    isTargetInSourceSubtree: false,
    sourceRootScheduler: sourceRoot?.schedulerType,
    sourceRootGeneration: sourceRoot?.schedulerGeneration,
    targetRootScheduler: targetRoot?.schedulerType,
    targetRootGeneration: targetRoot?.schedulerGeneration,
    targetDepth: _depthOf(target, byId),
    sourceSubtreeHeight: sourceSubtreeHeight,
  );

  return rejection == DeckMoveRejection.alreadyParent ? null : rejection;
}

/// Level in the tree, root = 1, walking parents in memory.
///
/// Bounded by the map's own size so corrupt data cannot spin here; a chain that
/// runs past every deck it knows about is answered with what it has, and the
/// repository re-checks depth against SQLite before writing anything.
int _depthOf(DeckEntity deck, Map<String, DeckEntity> byId) {
  var depth = 1;
  var current = deck;
  final seen = <String>{current.id};

  while (true) {
    final parentId = current.parentDeckId;
    if (parentId == null) return depth;
    final parent = byId[parentId];
    if (parent == null || !seen.add(parent.id)) return depth;
    current = parent;
    depth++;
  }
}
