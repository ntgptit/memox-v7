part of 'study_repository_impl.dart';

/// The two endings: how a session stops, and how a card stops being new.
///
/// **Split from the repository at the 400-line guard, on the seam the rules
/// already draw.** The session half changes a session's `status` and nothing
/// here touches `study_answers` — that absence *is* BR-86, because turns already
/// recorded survive every one of the five endings by having no path to them.
///
/// `completeLearning` joined it at the same guard boundary, and it belongs: it
/// is the *other* terminal event this feature owns, the one that ends a card's
/// pass through the learning chain (BR-144) and, with it, the root's freedom to
/// change algorithm (BR-13).
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

  // No `@override`: this mixin does not declare `implements StudyRepository`,
  // and neither does `endSession` above it. The concrete repository is what
  // satisfies the interface.
  Future<void> completeLearning({
    required String cardId,
    required DateTime learnedAt,
    required DateTime dueAt,
    int? box,
    int? intervalDays,
  }) => _dao.runInTransaction(() async {
    final state = await _dao.studyStateOf(cardId);
    if (state == null) {
      throw const NotFoundFailure(message: 'Card has no study state');
    }

    // Both columns in one statement. A card holding `learned_at` without a
    // schedule, or a schedule without `learned_at`, is exactly what invariants
    // 24 and 28 exist to catch — and writing them separately is the only way to
    // produce one.
    final isEightBox =
        SchedulerType.fromDbValue(state.schedulerType) ==
        SchedulerType.eightBox;

    await _dao.updateStudyState(
      cardId,
      CardStudyStatesCompanion(
        learnedAt: Value<DateTime?>(learnedAt),
        dueAt: Value<DateTime?>(dueAt),
        currentBox: Value<int?>(isEightBox ? (box ?? kInitialBox) : null),
        intervalDays: Value<int?>(
          isEightBox ? null : (intervalDays ?? kInitialIntervalDays),
        ),
      ),
    );

    // **BR-13, and this is where it lives.** Completing the chain is the event
    // that locks the root's scheduler, and it had no owner at all: nothing in
    // the app ever wrote `first_answered_at`, so BR-12 read every deck as
    // unlocked forever and a fully learned tree could still have its algorithm
    // swapped underneath it.
    //
    // In *this* transaction, not beside it. A card marked learned while the
    // root still says unlocked is the state invariant 30 exists to catch, and
    // two statements are the only way to produce it.
    //
    // [learnedAt], not a second clock read: the lock is a fact about the
    // completion, so it carries the completion's own timestamp.
    await _dao.lockRootSchedulerIfUnlocked(
      cardId: cardId,
      firstAnsweredAt: learnedAt,
    );
  });
}
