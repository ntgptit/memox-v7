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

  /// Choosing a study mode this build does not know, on a reset or on an
  /// unlocked change alike. It has no `dbValue`, so the write is impossible
  /// rather than merely refused — the check exists to make that an answer
  /// instead of a crash.
  resetSchedulerUnknown,

  /// Changing the study mode on something that is not a root. The scheduler
  /// lives on the root and a sub-deck's columns must stay NULL (BR-05, BR-06),
  /// so there is nothing one level down for this operation to write.
  schedulerNeedsRootDeck,

  /// Changing the study mode after a card has finished the learning chain
  /// (BR-13). Past that point the choice is locked and Reset learning progress
  /// is the only way through (BR-44) — a different operation, with a warning
  /// about what it destroys, rather than this one with a flag.
  schedulerLocked,

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

  /// Promotion is only meaningful for a branch. A root already owns its
  /// scheduler and cannot be promoted again (BR-269).
  promotionNeedsSubDeck,

  /// A new root may never directly hold cards (BR-58), so a branch with direct
  /// cards must be reorganised before it can be promoted (BR-269).
  promotionDeckHasCards,

  /// Promotion creates a root and a root must choose a scheduler that this
  /// build can persist (BR-11, BR-269).
  promotionSchedulerUnknown,
}
