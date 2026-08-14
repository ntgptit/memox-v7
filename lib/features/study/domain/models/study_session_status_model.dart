/// How a session stands, and — when it has ended — why (BR-79, BR-80).
///
/// The two are separate enums because only some pairs are legal. The matrix in
/// `data-model.md` is the authority, [isValidWith] is its executable form, and
/// invariant 12 is what catches a row that got past both.
enum StudySessionStatus {
  inProgress('in_progress'),
  completed('completed'),
  abandoned('abandoned'),
  invalidated('invalidated'),
  failed('failed');

  const StudySessionStatus(this.dbValue);

  /// The value stored in the database.
  final String dbValue;

  /// Whether this status admits [reason].
  ///
  /// **Deliberately not a database CHECK.** `data-model.md` names invariant 12
  /// as the enforcement for the pair; encoding it in SQL as well would make the
  /// invariant impossible to violate, and an invariant test that cannot build
  /// its own counter-example proves nothing.
  bool isValidWith(StudySessionEndReason? reason) => switch (this) {
    inProgress || completed => reason == null,
    abandoned =>
      reason == StudySessionEndReason.userExit ||
          reason == StudySessionEndReason.interrupted,
    invalidated =>
      reason == StudySessionEndReason.schedulerReset ||
          reason == StudySessionEndReason.staleGeneration ||
          reason == StudySessionEndReason.contentDeleted,
    failed => reason == StudySessionEndReason.persistenceError,
  };

  /// Maps a stored value to the enum.
  static StudySessionStatus fromDbValue(String value) {
    for (final status in values) {
      if (status.dbValue == value) return status;
    }

    throw StateError('Unknown StudySessionStatus: $value');
  }
}

/// Why a session ended, when it did not simply finish (BR-80).
enum StudySessionEndReason {
  /// The user left (BR-82).
  userExit('user_exit'),

  /// A session from an earlier study day was still `in_progress` when the app
  /// reopened (BR-103).
  ///
  /// **Separate from [userExit] for the reason BR-76 stores `kind` rather than
  /// deriving it:** "the user pressed exit" and "the OS reclaimed the app" are
  /// different events, and merging them makes the history say somebody gave up
  /// when they did not.
  interrupted('interrupted'),

  /// The deck was reset while the session was open (BR-83).
  schedulerReset('scheduler_reset'),

  /// A session from an older generation tried to write (BR-84).
  staleGeneration('stale_generation'),

  /// A write failed in a way the session could not continue past (BR-85).
  persistenceError('persistence_error'),

  /// The deck or card the session was running on went to Trash (BR-185).
  ///
  /// **Separate from [schedulerReset], and for the reason BR-76 gives about
  /// `kind`:** both end a session because the ground moved, but one is a
  /// scheduler being rewritten and the other is the material disappearing. A
  /// history that merges them cannot be un-merged later, and only one of them
  /// is undone by pressing Undo.
  contentDeleted('content_deleted');

  const StudySessionEndReason(this.dbValue);

  /// The value stored in the database.
  final String dbValue;

  /// Maps a stored value to the enum.
  static StudySessionEndReason fromDbValue(String value) {
    for (final reason in values) {
      if (reason.dbValue == value) return reason;
    }

    throw StateError('Unknown StudySessionEndReason: $value');
  }
}
