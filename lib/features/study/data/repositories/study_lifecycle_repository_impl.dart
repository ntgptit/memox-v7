part of 'study_repository_impl.dart';

/// How a session ends, and what ending it must never cost.
///
/// **Split from the repository at the 400-line guard, on the seam the rules
/// already draw.** Everything here changes a session's `status`; nothing here
/// touches `study_answers`, and that absence *is* BR-86 — turns already recorded
/// survive every one of the five endings because no ending has any way to reach
/// them.
mixin _StudyLifecycleOperations {
  StudyDao get _dao;

  Future<void> endSession({
    required String sessionId,
    required StudySessionStatus status,
    required StudySessionEndReason? reason,
    required DateTime endedAt,
  }) async {
    if (!status.isValidWith(reason)) {
      throw ConflictFailure(
        message: 'Invalid outcome: ${status.dbValue} with ${reason?.dbValue}',
      );
    }

    // Turns already written stay written, in every ending (BR-86). Nothing here
    // touches `study_answers`, and that is the whole guarantee.
    await _dao.updateSession(
      sessionId,
      StudySessionsCompanion(
        status: Value<String>(status.dbValue),
        endReason: Value<String?>(reason?.dbValue),
        endedAt: Value<DateTime?>(endedAt),
      ),
    );
  }

  Future<int> abandonStaleSessions({required DateTime dayStart}) =>
      _dao.runInTransaction(() async {
        final stale = await _dao.staleOpenSessions(dayStart);

        for (final session in stale) {
          await _dao.updateSession(
            session.id,
            StudySessionsCompanion(
              status: Value<String>(StudySessionStatus.abandoned.dbValue),
              // `interrupted`, never `user_exit`: the user did not leave, the
              // app did (BR-103). Merging them makes the history say somebody
              // gave up when they did not.
              endReason: Value<String?>(
                StudySessionEndReason.interrupted.dbValue,
              ),
              endedAt: Value<DateTime?>(dayStart),
            ),
          );
        }

        return stale.length;
      });

  Future<StudySessionEntity?> openSessionFor(String deckId) async {
    final row = await _dao.openSessionForDeck(deckId);
    return row == null ? null : studySessionEntityFromRow(row);
  }
}
