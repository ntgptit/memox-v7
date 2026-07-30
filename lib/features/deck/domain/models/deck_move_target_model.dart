import 'package:freezed_annotation/freezed_annotation.dart';

import 'deck_content_type_model.dart';
import '../entities/deck_entity.dart';

part 'deck_move_target_model.freezed.dart';

/// Why a deck cannot receive a move (UC-09 step 2).
///
/// An enum rather than a message, because the copy is the screen's job and the
/// reason is the domain's. It carries the *first* rule that fails, in the order
/// UC-09 lists them, so the explanation the user reads is the one the
/// repository would also produce.
enum DeckMoveRejection {
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

DeckMoveRejection? _rejectionFor({
  required DeckEntity source,
  required DeckEntity? sourceRoot,
  required DeckEntity target,
  required Map<String, DeckEntity> byId,
  required Set<String> subtreeIds,
  required int subtreeHeight,
}) {
  // Order matches UC-09 step 2. The first failure is the one reported, so the
  // reason a user sees is the most specific one that applies.
  if (target.id == source.id) return DeckMoveRejection.itself;
  if (subtreeIds.contains(target.id)) return DeckMoveRejection.ownDescendant;
  if (target.id == source.parentDeckId) return DeckMoveRejection.alreadyParent;
  if (target.contentType == DeckContentType.card) {
    return DeckMoveRejection.holdsCards;
  }

  final targetRoot = byId[target.rootDeckId];
  if (sourceRoot == null || targetRoot == null) {
    // A root that is not in the list means the snapshot is inconsistent. Refuse
    // rather than offer a move whose scheduler pairing cannot be checked.
    return DeckMoveRejection.differentScheduler;
  }
  if (sourceRoot.schedulerType != targetRoot.schedulerType) {
    return DeckMoveRejection.differentScheduler;
  }
  if (sourceRoot.schedulerGeneration != targetRoot.schedulerGeneration) {
    return DeckMoveRejection.differentGeneration;
  }

  final targetDepth = _depthOf(target, byId);
  if (targetDepth + subtreeHeight > DeckEntity.maxTreeDepth) {
    return DeckMoveRejection.tooDeep;
  }

  return null;
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
