import '../models/deck_deletion_impact_model.dart';
import '../models/deck_detail_model.dart';
import '../entities/deck_entity.dart';
import '../models/deck_name_model.dart';
import '../models/root_deck_summary_model.dart';
import '../models/scheduler_type_model.dart';

/// Contract for deck-tree management (UC-02, UC-03, UC-08, UC-09). Card CRUD
/// lives in `CardRepository` — one contract per responsibility (M4.9a).
///
/// Written from what presentation needs, not from the shape of the `decks`
/// table (AD-01): no method accepts or returns a Drift row, companion or DAO
/// type, and no Drift/SQLite exception escapes an implementation — failures
/// surface as the domain `Failure` hierarchy, thrown from the returned
/// futures/streams:
///
/// - `ValidationFailure` — input broke BR-01 or no scheduler was chosen
///   (BR-11);
/// - `NotFoundFailure` — the referenced deck does not exist;
/// - `ConflictFailure` — the operation contradicts the current tree state:
///   content-type rules (BR-58, BR-63, BR-64), a non-empty reset (BR-68), an
///   illegal move (BR-70, BR-74), a tree deeper than
///   `DeckEntity.maxTreeDepth` (BR-55), or a database constraint conflict;
/// - `DatabaseFailure` — any other persistence error.
///
/// Reads are `watch()` streams (AD-01): they emit the current value on listen
/// and re-emit whenever the underlying data changes, from any screen.
abstract interface class DeckRepository {
  /// All root decks, re-emitted on every change.
  Stream<List<DeckEntity>> watchRootDecks();

  /// Root decks with their aggregate progress — total cards in the tree and
  /// how many are due (UC-06).
  ///
  /// [now] is passed in, never read from a clock inside the query: "due
  /// exactly at now" is a boundary that has to work, and a query that reads
  /// the clock itself cannot be tested at it (BR-22). The caller owns when the
  /// number is recomputed.
  ///
  /// One query, not one per deck. The counts reach descendants through
  /// `root_deck_id` (BR-56), which is what makes a flat aggregate possible
  /// where a parent walk would need recursion.
  Stream<List<RootDeckSummary>> watchRootDeckSummaries({required DateTime now});

  /// Every deck in the database, for building a move-target picker (UC-09).
  ///
  /// Deliberately unfiltered and unsorted by hierarchy: eligibility is decided
  /// by `buildDeckMoveTargets`, which is pure and testable, and the picker has
  /// to show every tree by definition. One stream rather than one per root.
  Stream<List<DeckEntity>> watchAllDecks();

  /// A root deck and every descendant, to the allowed depth (BR-55).
  Stream<List<DeckEntity>> watchDeckTree(String rootDeckId);

  /// One deck together with its direct children (UC-06 step 4, UC-08).
  ///
  /// **One method, because the screen needs one snapshot.** The action set is
  /// computed from the deck's `content_type` and from whether the children are
  /// empty (BR-68) at the same time, so the two facts must come from the same
  /// read. This used to be `watchChildDecks` plus `getDeckById`, composed in the
  /// controller — two statements, two snapshots, and a window a rename or a
  /// create could land in.
  ///
  /// Errors as `NotFoundFailure` when the deck does not exist, which is a
  /// different thing from a deck with no children and has to stay different: one
  /// is a dead route, the other is an empty state.
  Stream<DeckDetail> watchDeckDetail(String deckId);

  /// Creates a root deck (UC-02): `parent_deck_id = NULL`, `root_deck_id =
  /// id`, `content_type = deck`, generation 1, `first_review_at = NULL`.
  ///
  /// [schedulerType] is mandatory and must be a real scheduler (BR-11) —
  /// there is no implicit default and `unknown` is rejected.
  ///
  /// [name] is a [DeckName], not a `String`: BR-01 has already been applied and
  /// the value is normalised. The signature is what makes "has this been
  /// validated?" answerable without reading the implementation — and it is what
  /// stops this layer checking again.
  Future<DeckEntity> createRootDeck({
    required DeckName name,
    required SchedulerType schedulerType,
  });

  /// Creates a sub-deck under [parentDeckId] (UC-08, BR-62): the child starts
  /// `unset` with no scheduler columns; a parent still `unset` becomes `deck`
  /// in the same atomic step. Refused when the child would sit deeper than
  /// `DeckEntity.maxTreeDepth` (BR-55) — nothing is written in that case.
  Future<DeckEntity> createSubDeck({
    required DeckName name,
    required String parentDeckId,
  });

  /// Renames a deck. Touches nothing but the name and `updated_at`.
  ///
  /// BR-01 was applied when the [DeckName] was constructed; this layer does not
  /// re-check it.
  Future<void> renameDeck({required String deckId, required DeckName name});

  /// What deleting [deckId] would remove — shown before the delete (BR-04).
  Future<DeckDeletionImpact> getDeletionImpact(String deckId);

  /// Deletes a deck; descendants, cards, review states, history and sessions
  /// go with it by cascade (BR-03).
  Future<void> deleteDeck(String deckId);

  /// Puts an empty sub-deck back to `unset` (BR-68). Blocked with a
  /// `ConflictFailure` when the deck still has cards or child decks, and for
  /// root decks, whose content type is invariant.
  Future<void> resetContentType(String deckId);

  /// Moves [deckId] and its whole subtree under [targetParentDeckId]
  /// (UC-09, BR-69…BR-74), rewriting `root_deck_id` for every node
  /// atomically — BR-71. Refused when the deepest resulting level would
  /// exceed `DeckEntity.maxTreeDepth` (BR-55) — nothing moves in that case.
  Future<void> moveDeck({
    required String deckId,
    required String targetParentDeckId,
  });
}
