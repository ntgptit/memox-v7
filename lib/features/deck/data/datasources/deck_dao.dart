import '../../../../core/database/app_database.dart';

/// Data access for the Deck side of the vertical.
///
/// Receives an already-open [AppDatabase] — `core/database/connection.dart` is
/// the only place that opens one (AD-08). Reads delegate to the typed queries
/// in `queries/deck.drift`, so every piece of business SQL — the cycle-safe
/// subtree walk included — is checked by `drift_dev` at build time (AD-02).
///
/// Card CRUD lives in `CardDao`; the two card-shaped queries kept here
/// (`directCardCount`, `subtreeCardCount`) serve Deck use cases — the
/// content-type reset (BR-68) and the deletion confirm (BR-04).
///
/// This class speaks Drift rows and companions. They stop here: the repository
/// maps them to domain entities and never lets one across (AD-01).
final class DeckDao {
  DeckDao(this._db);

  final AppDatabase _db;

  /// Runs [action] atomically. A thrown error rolls the whole block back —
  /// multi-step writes (BR-62, BR-71) all go through this.
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  // ---- reads -------------------------------------------------------------

  Stream<List<Deck>> watchRootDecks() => _db.rootDecks().watch();

  /// Root decks with their aggregate card and due counts, one statement
  /// (UC-06). [now] is a parameter so the due boundary is testable (BR-22).
  Stream<List<RootDeckSummariesResult>> watchRootDeckSummaries(DateTime now) =>
      _db.rootDeckSummaries(now).watch();

  /// Every deck, for the move-target picker (UC-09).
  Stream<List<Deck>> watchAllDecks() => _db.allDecks().watch();

  /// One root's whole tree at any allowed depth, via `root_deck_id`
  /// (BR-56, BR-57).
  Stream<List<Deck>> watchDecksInTree(String rootDeckId) =>
      _db.decksInTree(rootDeckId).watch();

  /// One deck and its direct children, each child with its whole subtree's
  /// aggregate — one statement (UC-06 step 4, UC-08).
  ///
  /// A `LEFT JOIN`, so a childless deck still yields exactly one row, with
  /// `child` null. That is why the empty list and "the deck is gone" are
  /// distinguishable here at all: no rows means no deck.
  ///
  /// The recursive walk inside it is what a deeper level costs. A root's subtree
  /// is free — every descendant carries its `root_deck_id` — but nothing
  /// identifies an intermediate ancestor, so `watchRootDeckSummaries` and this
  /// are two statements on purpose rather than one generalised one.
  Stream<List<ChildDeckLevelResult>> watchChildDeckLevel({
    required String parentDeckId,
    required DateTime now,
  }) => _db.childDeckLevel(parentDeckId, now).watch();

  Future<Deck?> deckById(String deckId) =>
      _db.deckById(deckId).getSingleOrNull();

  /// The deck itself plus every descendant. Cycle-safe: the recursive UNION
  /// deduplicates by id, so even corrupt data yields the complete reachable
  /// set instead of a silently truncated one.
  Future<List<String>> subtreeDeckIds(String deckId) =>
      _db.subtreeDeckIds(deckId).get();

  /// How deep [deckId] sits (root = 1, BR-55), walking at most [maxWalk]
  /// steps. `reachedRoot` false means the chain is longer than [maxWalk] or
  /// cyclic — the caller must treat that as a failure, never as a depth.
  Future<DeckDepthProbeResult?> deckDepthProbe({
    required String deckId,
    required int maxWalk,
  }) => _db.deckDepthProbe(deckId, maxWalk).getSingleOrNull();

  /// How tall [deckId]'s subtree is (the deck itself = 1), walking at most
  /// [maxWalk] levels. A result equal to [maxWalk] means "at least this
  /// tall" and the caller must refuse.
  Future<int?> subtreeHeightProbe({
    required String deckId,
    required int maxWalk,
  }) => _db.subtreeHeightProbe(deckId, maxWalk).getSingle();

  Future<int> directChildDeckCount(String deckId) =>
      _db.directChildDeckCount(deckId).getSingle();

  Future<int> directCardCount(String deckId) =>
      _db.directCardCount(deckId).getSingle();

  Future<int> subtreeCardCount(String deckId) =>
      _db.subtreeCardCount(deckId).getSingle();

  // ---- writes ------------------------------------------------------------

  Future<void> insertDeck(DecksCompanion deck) =>
      _db.into(_db.decks).insert(deck);

  Future<int> updateDeckById(String deckId, DecksCompanion changes) =>
      (_db.update(
        _db.decks,
      )..where((Decks deck) => deck.id.equals(deckId))).write(changes);

  Future<int> deleteDeckById(String deckId) => (_db.delete(
    _db.decks,
  )..where((Decks deck) => deck.id.equals(deckId))).go();

  /// Rewrites `root_deck_id` for [deckId] and its whole subtree (BR-71).
  Future<int> updateSubtreeRootDeck({
    required String deckId,
    required String newRootDeckId,
    required DateTime updatedAt,
  }) => _db.updateSubtreeRootDeck(newRootDeckId, updatedAt, deckId);
}
