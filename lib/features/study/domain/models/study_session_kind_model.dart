/// Which of the two card sets a session is working through (BR-142).
///
/// **The two never mix.** A session either takes cards that have not finished
/// the learning chain, or cards that finished it and have come due — never
/// both. That is what stops a session padding itself to twenty cards with new
/// material the user did not ask to learn, and it is why the split lives on the
/// session rather than being re-derived per card.
enum StudySessionKind {
  /// Cards with `learned_at IS NULL`.
  ///
  /// Walks the algorithm's whole `stageSequence` (BR-109), writes only
  /// `learning` and `relearning` turns, and changes no schedule until the card
  /// finishes — at which point completion is an **event**, not an answer
  /// (BR-144).
  learning('learning'),

  /// Cards with `learned_at IS NOT NULL AND due_at <= now`.
  ///
  /// Runs exactly one user-chosen mode (BR-146), and the first turn of each
  /// card is the `scheduled` one that moves the schedule (BR-77).
  ///
  /// It cannot be opened when nothing is due (BR-145): studying ahead is not a
  /// missing feature, it is a rule.
  reviewing('reviewing');

  const StudySessionKind(this.dbValue);

  /// The value stored in the database.
  ///
  /// No `unknown` here, unlike [StudyMode]. A session with an unreadable kind
  /// cannot be shown *or* continued — there is no safe half-render — so an
  /// unrecognised value is a genuine read failure rather than something to
  /// tolerate.
  final String dbValue;

  /// Maps a stored value to the enum.
  ///
  /// Throws for anything else, deliberately: see [dbValue].
  static StudySessionKind fromDbValue(String value) {
    for (final kind in values) {
      if (kind.dbValue == value) return kind;
    }

    throw StateError('Unknown StudySessionKind: $value');
  }
}
