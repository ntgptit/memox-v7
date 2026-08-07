/// What a recorded turn was for (BR-75, BR-143).
///
/// **Stored, never derived** (BR-76, AD-11). Diffing the before and after state
/// gets it wrong in a case that is not rare: a `scheduled` turn answered
/// `remembered` on a box-8 card leaves `previous_box == next_box == 8`, exactly
/// like a turn that changed nothing. History written with the wrong label cannot
/// be recomputed later, because the thing that would recompute it is the same
/// broken inference.
enum StudyAnswerKind {
  /// A turn inside the new-card chain (BR-143).
  ///
  /// Records history and changes no schedule. Never appears in a `reviewing`
  /// session.
  learning('learning'),

  /// The turn that moves the long-term schedule (BR-77).
  ///
  /// The first turn of each card in a `reviewing` session, and the only kind
  /// that may change `current_box`, `ease_factor`, `interval_days` or `due_at`.
  /// A `learning` session produces none at all (BR-141, BR-144).
  scheduled('scheduled'),

  /// A repeat turn within the same session (BR-78).
  ///
  /// Updates `last_answered_at` and nothing else about the schedule.
  relearning('relearning');

  const StudyAnswerKind(this.dbValue);

  /// The value stored in the database.
  final String dbValue;

  /// Whether this kind may move the schedule.
  ///
  /// One place, so that "only `scheduled` changes the schedule" is a property of
  /// the enum rather than a condition three call sites have to agree on.
  bool get movesSchedule => this == scheduled;

  /// Maps a stored value to the enum.
  static StudyAnswerKind fromDbValue(String value) {
    for (final kind in values) {
      if (kind.dbValue == value) return kind;
    }

    throw StateError('Unknown StudyAnswerKind: $value');
  }
}
