/// Why a study operation was refused, as a value rather than a sentence.
///
/// The same shape as `DeckConflictReason`, and for the same reason: a refusal
/// the user could act on has to reach the screen as something it can switch on.
/// `Failure.message` is a sanitized diagnostic the UI must not render, so a
/// refusal carried only as a message arrives as one indistinguishable line.
///
/// **Only refusals a user could plausibly act on, or needs explained.** A
/// programming error stays a `DatabaseFailure` — see
/// `core/error/drift_error_mapper.dart` for that split.
enum StudyRefusalReason {
  /// Opening a review session with nothing due (BR-145).
  ///
  /// Not an error state and not an empty list: studying ahead is a rule, not a
  /// missing feature, so the screen says so plainly and offers no way past it
  /// (BR-29).
  nothingDueToReview,

  /// Opening a learning session when every card in the deck has been learned.
  nothingLeftToLearn,

  /// The chosen mode cannot build content from this session's cards (BR-99).
  ///
  /// `fill` with no card carrying an `example`, `guess` with fewer than five
  /// distinct meanings, `match` with fewer than two pairs (BR-153). In a review
  /// session the mode is disabled on the chooser **with its reason** rather than
  /// hidden — a mode that vanishes reads as a bug (BR-99, BR-154).
  modeHasNoContent,

  /// The mode is not one this deck's algorithm offers (BR-146).
  ///
  /// Presented as unavailable for this deck, and never as something Reset
  /// learning progress would unlock (BR-100).
  modeNotSupportedByScheduler,

  /// A write arrived from a session opened under an older generation (BR-84).
  ///
  /// The session is invalidated and the turn is not written. Letting it through
  /// would let a Reset silently un-reset itself.
  staleGeneration,

  /// A write arrived for a session that is no longer open (BR-79).
  sessionNotOpen,
}
