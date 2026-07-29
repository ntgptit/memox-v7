import 'deck_deletion_impact_model.dart';
import 'deck_entity.dart';
import 'scheduler_type_model.dart';

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

  /// A root deck and every descendant, to the allowed depth (BR-55).
  Stream<List<DeckEntity>> watchDeckTree(String rootDeckId);

  /// The direct children of one deck.
  Stream<List<DeckEntity>> watchChildDecks(String parentDeckId);

  /// One deck, for operations that need its current state.
  Future<DeckEntity> getDeckById(String deckId);

  /// Creates a root deck (UC-02): `parent_deck_id = NULL`, `root_deck_id =
  /// id`, `content_type = deck`, generation 1, `first_review_at = NULL`.
  ///
  /// [schedulerType] is mandatory and must be a real scheduler (BR-11) —
  /// there is no implicit default and `unknown` is rejected.
  Future<DeckEntity> createRootDeck({
    required String name,
    required SchedulerType schedulerType,
  });

  /// Creates a sub-deck under [parentDeckId] (UC-08, BR-62): the child starts
  /// `unset` with no scheduler columns; a parent still `unset` becomes `deck`
  /// in the same atomic step. Refused when the child would sit deeper than
  /// `DeckEntity.maxTreeDepth` (BR-55) — nothing is written in that case.
  Future<DeckEntity> createSubDeck({
    required String name,
    required String parentDeckId,
  });

  /// Renames a deck (BR-01). Touches nothing but the name and `updated_at`.
  Future<void> renameDeck({required String deckId, required String name});

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
