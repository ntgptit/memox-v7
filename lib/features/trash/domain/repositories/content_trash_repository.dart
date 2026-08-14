/// Creating a deletion batch — the half of Trash that other features call.
///
/// **Why this is a separate contract from `TrashRepository`.** Deleting a deck
/// is a Deck operation and deleting a card is a Card operation; both have to
/// keep their own rules in the same transaction (BR-186's content-type reset
/// sits in the Deck repository and reads counts the Deck feature owns). So the
/// delete paths stay where they are and reach for the batch mechanics here,
/// rather than the Trash feature growing a second copy of the emptied-parent
/// rule.
///
/// A feature may depend on another feature's **domain** contract — the Deck
/// repository already takes `StudyRepository` for the same reason — and never
/// on its `data/`.
///
/// **Every method here runs inside the caller's transaction.** They open none
/// of their own: a batch created in a nested transaction could commit while the
/// delete around it rolls back, which is precisely the half-deleted state
/// BR-182's "one transaction" forbids.
abstract interface class ContentTrashRepository {
  /// Marks [deckId] and every **active** descendant — decks and cards — as one
  /// batch, and closes the sessions that touched them (BR-182, BR-184, BR-185).
  ///
  /// A descendant already in Trash keeps its older batch and is not swept into
  /// this one; restoring this batch will not revive it (BR-184).
  ///
  /// Returns the new batch id, which is what an Undo affordance holds on to.
  Future<String> markDeckDeleted(String deckId);

  /// Marks each of [cardIds] as its **own** batch (BR-182).
  ///
  /// One batch per card rather than one per action, because the item root is
  /// singular and each card must be restorable on its own — a bulk delete of
  /// fifty is fifty things the user may change their mind about separately.
  ///
  /// Returns the batch ids in the order the cards were given. A single-element
  /// call is what the Undo affordance uses.
  Future<List<String>> markCardsDeleted(List<String> cardIds);
}
