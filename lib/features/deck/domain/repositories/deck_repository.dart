import '../models/deck_deletion_impact_model.dart';
import '../entities/deck_entity.dart';
import '../models/deck_name_model.dart';
import '../models/deck_list_snapshot_model.dart';
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

  /// One level of the deck tree, re-emitted on every change (UC-06, UC-08).
  ///
  /// [parentDeckId] null asks for the root level: every root deck, and no parent.
  /// Any other id asks for what is inside that deck, and the snapshot carries the
  /// deck itself so the screen can title itself and build its action set from the
  /// same instant the list came from.
  ///
  /// **One method, because it is one screen.** The root list and the inside of a
  /// deck were `watchRootDeckList` and `watchDeckDetail`, and the second returned
  /// bare rows where the first returned aggregates — so opening a deck showed a
  /// plainer list than the one the user came from. That difference was two reads
  /// showing through, not a decision anyone made.
  ///
  /// Every level costs **one statement**. Which statement differs — a root's
  /// subtree is free through `root_deck_id` (BR-56) while a deeper one has to be
  /// walked — but no screen state is ever built from two.
  ///
  /// [now] is passed in, never read from a clock inside the query: "due exactly at
  /// now" is a boundary that has to work, and a query that reads the clock itself
  /// cannot be tested at it (BR-22). The caller owns when the number is recomputed.
  ///
  /// Errors as `NotFoundFailure` when [parentDeckId] names a deck that does not
  /// exist. That is a different thing from a level with no children and has to
  /// stay different: one is a dead route, the other is an empty state.
  Stream<DeckListSnapshot> watchDeckList({
    required String? parentDeckId,
    required DateTime now,
  });

  /// Every deck in the database, for building a move-target picker (UC-09).
  ///
  /// Deliberately unfiltered and unsorted by hierarchy: eligibility is decided
  /// by `buildDeckMoveTargets`, which is pure and testable, and the picker has
  /// to show every tree by definition. One stream rather than one per root.
  Stream<List<DeckEntity>> watchAllDecks();

  /// A root deck and every descendant, to the allowed depth (BR-55).
  Stream<List<DeckEntity>> watchDeckTree(String rootDeckId);

  /// Creates a root deck (UC-02): `parent_deck_id = NULL`, `root_deck_id =
  /// id`, `content_type = deck`, generation 1, `first_answered_at = NULL`.
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

  /// Deletes a deck; descendants, cards, study states, history and sessions
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
