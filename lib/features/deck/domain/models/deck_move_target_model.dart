import 'package:freezed_annotation/freezed_annotation.dart';

import '../entities/deck_entity.dart';
import '../failures/deck_move_failure.dart';

part 'deck_move_target_model.freezed.dart';

/// One candidate in the move picker: a deck, how deep it sits, and whether the
/// move is allowed.
///
/// [depth] is carried so the picker can show hierarchy — UC-09 requires the
/// user be able to tell two decks with the same name apart, and indentation is
/// the only thing that does that without a breadcrumb per row.
@freezed
abstract class DeckMoveTarget with _$DeckMoveTarget {
  const factory DeckMoveTarget({
    required DeckEntity deck,

    /// Level in the tree, root = 1 (BR-55).
    required int depth,

    /// `null` when the move is allowed.
    required DeckMoveRejection? rejection,
  }) = _DeckMoveTarget;

  const DeckMoveTarget._();

  bool get isEligible => rejection == null;
}

/// Builds the candidate list for moving [source], from every deck in the
/// database.
///
/// **Pure, and deliberately not in the repository.** It answers "what should
/// the picker offer", which is a presentation question with a domain answer;
/// the repository answers "what may actually be written", and it re-checks
/// every rule below inside the move transaction. Two checks are not
/// duplication here — the UI one exists to explain, the repository one exists
/// to be safe, and a UI that is out of date must never be able to widen what
/// the database accepts.
///
/// Works from one flat list because [DeckEntity.parentDeckId] and
/// [DeckEntity.rootDeckId] are enough to rebuild the tree in memory (BR-56).
/// Nothing here queries anything, so adding a deck costs one pass, not one
/// round trip.
///
/// Returns an empty list when [source] is a root deck: moving a root is out of
/// scope for the MVP (UC-09 A2) — the deck would need its own scheduler, which
/// is a new decision rather than a move.
List<DeckMoveTarget> buildDeckMoveTargets({
  required DeckEntity source,
  required List<DeckEntity> allDecks,
}) {
  if (source.isRoot) return const <DeckMoveTarget>[];

  final byId = <String, DeckEntity>{for (final deck in allDecks) deck.id: deck};
  final childrenOf = <String, List<DeckEntity>>{};
  for (final deck in allDecks) {
    final parentId = deck.parentDeckId;
    if (parentId == null) continue;
    (childrenOf[parentId] ??= <DeckEntity>[]).add(deck);
  }

  final subtreeIds = _subtreeIds(source.id, childrenOf);
  final subtreeHeight = _subtreeHeight(source.id, childrenOf);
  final sourceRoot = byId[source.rootDeckId];

  final targets = <DeckMoveTarget>[
    for (final deck in allDecks)
      DeckMoveTarget(
        deck: deck,
        depth: _depthOf(deck, byId),
        rejection: _rejectionFor(
          source: source,
          sourceRoot: sourceRoot,
          target: deck,
          byId: byId,
          subtreeIds: subtreeIds,
          subtreeHeight: subtreeHeight,
        ),
      ),
  ];
  // Tree order: each root followed by its descendants, so indentation reads as
  // a hierarchy instead of as a flat list with random gaps.
  targets.sort((a, b) {
    final byRoot = a.deck.rootDeckId.compareTo(b.deck.rootDeckId);
    if (byRoot != 0) return byRoot;

    return a.deck.createdAt.compareTo(b.deck.createdAt);
  });

  return List<DeckMoveTarget>.unmodifiable(targets);
}

/// Gathers the facts UC-09 needs from the loaded snapshot, then defers the
/// decision to [deckMoveRejection].
///
/// The split is the point: this half knows how to read a tree held in memory,
/// and the rule itself lives in one place that `moveDeck` also calls.
DeckMoveRejection? _rejectionFor({
  required DeckEntity source,
  required DeckEntity? sourceRoot,
  required DeckEntity target,
  required Map<String, DeckEntity> byId,
  required Set<String> subtreeIds,
  required int subtreeHeight,
}) {
  final targetRoot = byId[target.rootDeckId];

  return deckMoveRejection(
    source: source,
    target: target,
    isTargetInSourceSubtree: subtreeIds.contains(target.id),
    sourceRootScheduler: sourceRoot?.schedulerType,
    sourceRootGeneration: sourceRoot?.schedulerGeneration,
    targetRootScheduler: targetRoot?.schedulerType,
    targetRootGeneration: targetRoot?.schedulerGeneration,
    targetDepth: _depthOf(target, byId),
    sourceSubtreeHeight: subtreeHeight,
  );
}

/// Level with the root as 1. Bounded so corrupt data cannot loop forever: a
/// walk that runs past the allowed depth returns a value that fails every
/// depth check, which is the safe direction to be wrong in.
int _depthOf(DeckEntity deck, Map<String, DeckEntity> byId) {
  var depth = 1;
  var current = deck;
  while (current.parentDeckId != null && depth <= DeckEntity.maxTreeDepth) {
    final parent = byId[current.parentDeckId];
    if (parent == null) break;
    current = parent;
    depth += 1;
  }

  return depth;
}

Set<String> _subtreeIds(
  String rootId,
  Map<String, List<DeckEntity>> childrenOf,
) {
  final ids = <String>{rootId};
  final queue = <String>[rootId];
  while (queue.isNotEmpty) {
    final id = queue.removeLast();
    for (final child in childrenOf[id] ?? const <DeckEntity>[]) {
      // `add` returning false means the id was already seen, which is how a
      // cyclic tree terminates here instead of hanging.
      if (ids.add(child.id)) queue.add(child.id);
    }
  }

  return ids;
}

/// Height with the deck itself as 1.
int _subtreeHeight(String rootId, Map<String, List<DeckEntity>> childrenOf) {
  var height = 0;
  var level = <String>[rootId];
  final seen = <String>{rootId};
  while (level.isNotEmpty && height <= DeckEntity.maxTreeDepth) {
    height += 1;
    final next = <String>[];
    for (final id in level) {
      for (final child in childrenOf[id] ?? const <DeckEntity>[]) {
        if (seen.add(child.id)) next.add(child.id);
      }
    }
    level = next;
  }

  return height;
}
