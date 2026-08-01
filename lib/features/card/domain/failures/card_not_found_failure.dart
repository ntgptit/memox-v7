/// Which row was missing, when a card operation could not find what it needed.
///
/// Two `NotFoundFailure`s reach presentation from the card repository and they
/// are not the same event to a user: the deck they were adding to has been
/// deleted from under them, or the card they were editing has. Both arrived
/// with only a sanitized `message`, which the UI must not render — so the
/// screen could offer one line for two situations whose recoveries differ
/// (go back to the parent, versus close the editor).
enum CardNotFoundReason {
  /// The target deck is gone — creating into it cannot proceed.
  deckGone,

  /// The card itself is gone — editing or deleting it cannot proceed.
  cardGone,
}
