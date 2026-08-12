/// Why a deck write was refused, as a value instead of a sentence.
///
/// Every one of these was an English string inside
/// `ConflictFailure(message: ...)` until M4.10. Eight distinct refusals reached
/// the user as one message, because `Failure.message` is a sanitized diagnostic
/// the UI must not render — so the presentation layer had nothing to switch on
/// and fell back to a single line.
///
/// Now the repository throws `ConflictFailure(reason: <one of these>)` and
/// `context.deckConflict` maps each to its own copy in an exhaustive switch. A
/// ninth refusal added here fails to compile until it has text.
///
/// **Only refusals the user could plausibly act on, or needs explained.** A
/// programming error is a `DatabaseFailure`, not a reason on this list — see
/// `core/error/drift_error_mapper.dart` for that split.
enum DeckConflictReason {
  /// Creating a sub-deck under a deck that already holds cards (BR-63, BR-66).
  /// A deck holds one kind of thing.
  parentHoldsCards,

  /// Creating a sub-deck under a deck already at level 10 (BR-55).
  parentAtMaxDepth,

  /// Resetting learning progress on something that is not a root. The
  /// scheduler and the generation belong to the root (BR-05), so a reset one
  /// level down would either do nothing or quietly reset a sibling's tree.
  resetNeedsRootDeck,

  /// Resetting onto a study mode this build does not know. It has no `dbValue`,
  /// so the write is impossible rather than merely refused — the check exists
  /// to make that an answer instead of a crash.
  resetSchedulerUnknown,

  /// The stored `content_type` is a value this build does not know — the deck
  /// was written by a newer version. Refused rather than guessed at, because
  /// altering it could contradict a rule the newer schema attached to it.
  unknownContentType,

  /// The deck sits deeper than the walk bound allows, so its level cannot be
  /// established. Either the data is corrupt or a cycle exists; both are refused
  /// rather than answered with a number that might be wrong.
  deckDepthUnknowable,

  /// The subtree is taller than the walk bound allows. Same reasoning as
  /// [deckDepthUnknowable], from the other end of the tree.
  subtreeHeightUnknowable,
}
