import '../../../../core/database/app_database.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/models/scheduler_type_model.dart';
import '../mappers/study_state_reset_mapper.dart';

/// Data access for the Deck side of the vertical.
///
/// Receives an already-open [AppDatabase] — `core/database/connection.dart` is
/// the only place that opens one (AD-08). Reads delegate to the typed queries
/// in `queries/deck.drift`, so every piece of business SQL — the cycle-safe
/// subtree walk included — is checked by `drift_dev` at build time (AD-02).
///
/// Card CRUD lives in `CardDao`; the two card-shaped queries kept here
/// (`directCardCount`, `subtreeCardCount`) serve Deck use cases — the
/// automatic content-type unset (BR-163) and the deletion confirm (BR-04).
///
/// This class speaks Drift rows and companions. They stop here: the repository
/// maps them to domain entities and never lets one across (AD-01).
final class DeckDao {
  DeckDao(this._db);

  /// One step beyond the deepest valid tree makes the read bound derive from
  /// BR-55 while leaving room to terminate corrupt ancestry safely.
  static const int _ancestryWalkLimit = DeckEntity.maxTreeDepth + 1;

  final AppDatabase _db;

  /// Runs [action] atomically. A thrown error rolls the whole block back —
  /// multi-step writes (BR-62, BR-71) all go through this.
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  // ---- reads -------------------------------------------------------------

  Stream<List<Deck>> watchRootDecks() => _db.rootDecks().watch();

  /// Root decks with their aggregate card and due counts, one statement
  /// (UC-06). [now] is a parameter so the due boundary is testable (BR-22);
  /// [startOfToday] is the local-day boundary the overdue partition cuts at
  /// (BR-162), computed by the caller from `LocalDayModel` — SQL never
  /// derives a local midnight itself.
  Stream<List<RootDeckSummariesResult>> watchRootDeckSummaries({
    required DateTime now,
    required DateTime startOfToday,
  }) => _db.rootDeckSummaries(now, startOfToday).watch();

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
    required DateTime startOfToday,
  }) => _db
      .childDeckLevel(parentDeckId, _ancestryWalkLimit, now, startOfToday)
      .watch();

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

  Future<int> nextSiblingPosition(String? parentDeckId) =>
      _db.nextSiblingPosition(parentDeckId).getSingle();

  Future<List<Deck>> siblingDecks(String? parentDeckId) =>
      _db.siblingDecks(parentDeckId).get();

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
  /// Every card in a tree, back to the state a card is born in (BR-42, BR-09).
  ///
  /// Takes the scheduler as a domain value rather than a string plus four
  /// nullable numbers: which columns a scheduler owns is a rule, and a caller
  /// passing them by hand is a caller that can pass `eight_box` with an ease
  /// factor.
  Future<int> resetTreeStudyStates({
    required String rootDeckId,
    required SchedulerType schedulerType,
    required int generation,
  }) {
    final initial = initialStudyColumnsFor(schedulerType);

    return _db.resetTreeStudyStates(
      schedulerType.dbValue,
      generation,
      initial.box,
      initial.ease,
      initial.interval,
      initial.repetitions,
      rootDeckId,
    );
  }

  Future<int> updateSubtreeRootDeck({
    required String deckId,
    required String newRootDeckId,
    required DateTime updatedAt,
  }) => _db.updateSubtreeRootDeck(newRootDeckId, updatedAt, deckId);
}
