/// Why a turn ended the way it did, when the action alone does not say (BR-131).
///
/// Only [timeout] exists, and only `recall` can produce it. **Stored rather than
/// inferred**, for the same reason `kind` is: owning up to a blank and running
/// out of time produce the same `action`, and the difference is exactly what a
/// later look at the history would want to know.
enum StudyOutcomeReason {
  /// The twenty seconds ran out (BR-128, BR-130).
  timeout('timeout');

  const StudyOutcomeReason(this.dbValue);

  /// The value stored in the database.
  final String dbValue;

  /// Maps a stored value to the enum.
  static StudyOutcomeReason fromDbValue(String value) {
    for (final reason in values) {
      if (reason.dbValue == value) return reason;
    }

    throw StateError('Unknown StudyOutcomeReason: $value');
  }
}
