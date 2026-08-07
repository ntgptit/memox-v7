/// Why a card write was refused, as a value instead of a sentence.
///
/// Every one of these was an English string inside `ConflictFailure(message:)`
/// until M4.10ar — six refusals, and **two of them carried the byte-identical
/// sentence**, which is the clearest possible statement of the problem:
/// `Failure.message` is a sanitized diagnostic the UI must not render, so
/// presentation had nothing to switch on and every refusal would have reached
/// the user as one line. Deck hit this first and fixed it at M4.10; the card
/// repository was written before that and kept the old shape.
///
/// Now the repository throws `ConflictFailure(reason: <one of these>)` and the
/// screen maps each to its own copy in an exhaustive switch. A seventh refusal
/// added here fails to compile until it has text.
///
/// **Only refusals the user could plausibly act on, or needs explained.** A
/// programming error is a `DatabaseFailure`, not a reason on this list — see
/// `core/error/drift_error_mapper.dart` for that split.
enum CardConflictReason {
  /// Creating a card directly under a root deck (BR-58). A root holds decks.
  parentIsRoot,

  /// Creating a card in a deck that already holds sub-decks (BR-63, BR-66).
  /// A deck holds one kind of thing.
  deckHoldsDecks,

  /// The stored `content_type` is a value this build does not know — the deck
  /// was written by a newer version. Refused rather than guessed at, because
  /// altering it could contradict a rule the newer schema attached to it.
  unknownContentType,

  /// The root deck carries no scheduler, which invariant Q11 forbids. The data
  /// is corrupt; refusing is the only honest response, because a card written
  /// now would get a study state with no schedule to follow (BR-09).
  rootSchedulerMissing,

  /// The root's scheduler is a value this build does not know. Same reasoning
  /// as [unknownContentType], one column over.
  unknownScheduler,
}
