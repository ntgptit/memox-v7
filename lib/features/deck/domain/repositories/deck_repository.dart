import '../models/deck_deletion_impact_model.dart';
import '../entities/deck_entity.dart';
import '../models/deck_name_model.dart';
import '../models/deck_list_snapshot_model.dart';
import '../models/deck_reorder_placement_model.dart';
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
///   content-type rules (BR-58, BR-63, BR-64, BR-163), an
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
    required Duration utcOffset,
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

  /// Moves a deck and its whole active subtree to Trash (BR-256, BR-258).
  ///
  /// **Nothing is destroyed.** Since v8 this marks one deletion batch: rows
  /// stay, so cards keep their ids, study states, history and tags until the
  /// batch is purged (BR-259). Every active surface loses the subtree in the
  /// same instant (BR-257), and a non-root parent left empty goes back to
  /// `unset` in the same atomic write — BR-260.
  Future<void> deleteDeck(String deckId);

  /// The same deletion, returning the batch id so the caller can offer Undo
  /// (BR-256, BR-263).
  ///
  /// A separate method rather than a return value on [deleteDeck], because
  /// almost every caller has no Undo to offer and a batch id it must not hold
  /// on to — a stale one names a batch that has since been restored or purged.
  Future<String> deleteDeckForUndo(String deckId);

  /// Resets a root deck's learning progress, optionally onto a new scheduler
  /// (UC-07).
  ///
  /// **The one way to change a locked scheduler** (BR-13, BR-44). Everything
  /// lands together or not at all — BR-47: the generation goes up (BR-40),
  /// `first_answered_at` goes back to NULL, every card in the tree returns to
  /// the state it was born in (BR-42, BR-09) with `learned_at` and `due_at`
  /// both NULL (BR-152), and every open session of the tree ends `invalidated`
  /// (BR-83).
  ///
  /// **What it does not touch:** the tree, `content_type`, card content, tags
  /// or media (BR-41), and `study_answers` — the old history stays, carrying
  /// the old generation (BR-43).
  ///
  /// Refused for anything but a root: the scheduler and the generation belong
  /// to the root (BR-05), so there is no such operation one level down.
  Future<void> resetLearningProgress({
    required String rootDeckId,
    required SchedulerType schedulerType,
  });

  /// Changes a root deck's scheduler while it is still unlocked (BR-12, UC-03).
  ///
  /// **Deliberately not folded into [resetLearningProgress], and the difference
  /// is a generation.** Both rewrite the scheduler and reinitialise every study
  /// state in the tree. Only reset bumps `scheduler_generation` — because only
  /// reset is throwing a generation of learning away. A deck nobody has finished
  /// a card in has nothing to throw away, so BR-12 lets the choice change
  /// outright and UC-03's postcondition says the generation must **not** move.
  /// Routing this through reset would spend a generation on nothing, mark the
  /// old (empty) history as belonging to a superseded cycle, and make the user
  /// confirm a destructive warning about progress that does not exist.
  ///
  /// All of it inside a single BR-47 transaction, and every check is re-read
  /// there rather than trusted from the caller:
  ///
  /// * refused for anything but a root — the scheduler lives on the root
  ///   (BR-05, BR-06);
  /// * refused once `first_answered_at` is set — that is BR-13's lock, and
  ///   Reset is the only way past it (BR-44);
  /// * refused for `SchedulerType.unknown`, which has no `dbValue` to write;
  /// * every card in the tree is reinitialised onto the new scheduler at the
  ///   **current** generation (BR-14);
  /// * every open session of the tree ends `invalidated` — its queue was dealt
  ///   against the old algorithm and cannot be finished under the new one.
  ///
  /// Choosing the scheduler the deck already runs is accepted and does nothing
  /// the user can observe. It is still one transaction: re-seeding the tree onto
  /// the same algorithm is a no-op in content, and refusing would make the UI
  /// responsible for comparing before submitting.
  ///
  /// Content, tags, media and `study_answers` are untouched — the same list
  /// reset keeps (BR-41, BR-43).
  Future<void> changeUnlockedScheduler({
    required String rootDeckId,
    required SchedulerType schedulerType,
  });

  /// Moves [deckId] and its whole subtree under [targetParentDeckId]
  /// (UC-09, BR-69…BR-74), rewriting `root_deck_id` for every node
  /// atomically — BR-71. Refused when the deepest resulting level would
  /// exceed `DeckEntity.maxTreeDepth` (BR-55) — nothing moves in that case.
  Future<void> moveDeck({
    required String deckId,
    required String targetParentDeckId,
  });

  /// Changes [deckId]'s order relative to [targetSiblingDeckId]. Both rows are
  /// re-read inside the transaction and must still share exactly one parent;
  /// this operation never changes a tree pointer or any study data.
  Future<void> reorderDeck({
    required String deckId,
    required String targetSiblingDeckId,
    required DeckReorderPlacement placement,
  });
}
