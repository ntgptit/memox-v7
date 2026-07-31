import '../entities/deck_entity.dart';
import '../models/deck_search_result_model.dart';
import '../repositories/deck_repository.dart';

/// Every deck under a scope whose name contains what the user typed (UC-06).
///
/// **One read, and no new query.** It watches `watchAllDecks()` and does the
/// scoping, the matching and the trail-building in memory — the same shape the
/// move-target picker already uses, and for the same reason recorded there:
/// ancestry is arithmetic over one result set of parent pointers, not a walk
/// that hits the database again. A deck tree is capped at ten levels (BR-55) and
/// lives on the device, so the set being scanned is small by construction.
///
/// **It searches the subtree, not the level.** A search that only looked at the
/// children in front of the user would answer a question they can already
/// answer by reading the screen. The one worth asking is "where did I put it",
/// and that is the whole branch below where they stand.
class SearchDecksUseCase {
  const SearchDecksUseCase(this._repository);

  final DeckRepository _repository;

  /// [parentDeckId] null searches the whole library; otherwise the subtree
  /// below that deck, excluding the deck itself — the user is standing on it.
  Stream<List<DeckSearchResult>> call({
    required String query,
    String? parentDeckId,
  }) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return Stream<List<DeckSearchResult>>.value(const []);

    return _repository.watchAllDecks().map(
      (List<DeckEntity> decks) => searchDeckTree(
        decks: decks,
        needle: needle,
        parentDeckId: parentDeckId,
      ),
    );
  }
}

/// The pure half, so it can be tested without a repository.
///
/// Ordered shallow-first then by name, which is the design's order and the one
/// that puts the likely answer at the top.
List<DeckSearchResult> searchDeckTree({
  required List<DeckEntity> decks,
  required String needle,
  String? parentDeckId,
}) {
  if (needle.isEmpty) return const <DeckSearchResult>[];

  final byId = <String, DeckEntity>{
    for (final DeckEntity deck in decks) deck.id: deck,
  };

  final results = <DeckSearchResult>[];
  for (final DeckEntity deck in decks) {
    final trail = _trailWithin(deck, byId, parentDeckId);
    // Null means the deck is outside the scope, or is the scope itself.
    if (trail == null) continue;
    if (!deck.name.toLowerCase().contains(needle)) continue;

    results.add(DeckSearchResult(deck: deck, ancestorNames: trail));
  }

  results.sort((a, b) {
    final byDepth = a.depth.compareTo(b.depth);
    if (byDepth != 0) return byDepth;
    return a.deck.name.toLowerCase().compareTo(b.deck.name.toLowerCase());
  });
  return results;
}

/// The names from the scope down to [deck]'s parent, or null when [deck] is not
/// under the scope at all.
///
/// Walking up rather than down: every deck already knows its parent, so a walk
/// up is bounded by the depth cap, where a walk down would have to index the
/// whole set by parent first. It stops at [scopeId] so the trail names only the
/// part of the path the user cannot already see.
List<String>? _trailWithin(
  DeckEntity deck,
  Map<String, DeckEntity> byId,
  String? scopeId,
) {
  final names = <String>[];
  var current = deck;

  // Bounded by BR-55's ten levels; the guard is against a cycle a corrupt row
  // could introduce, not against legitimate depth.
  for (var step = 0; step <= 10; step++) {
    final parentId = current.parentDeckId;
    if (parentId == scopeId) return names.reversed.toList();
    if (parentId == null) {
      return scopeId == null ? names.reversed.toList() : null;
    }

    final parent = byId[parentId];
    if (parent == null) return null;

    names.add(parent.name);
    current = parent;
  }
  return null;
}
