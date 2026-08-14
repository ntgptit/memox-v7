part of 'study_repository_impl.dart';

/// The queue engine: choosing a session's cards, laying out a stage's first
/// round, and deciding what one answer does to the row it came from.
///
/// **Split out of the repository at the 400-line guard, and the seam is a real
/// one.** Everything here answers "what happens to the queue, and to the card,
/// when one answer arrives"; what stays behind answers "what happens to the
/// session". They were only ever in one file because they run inside the same
/// transaction — which is a reason to share a library, not a reason to share a
/// file.
///
/// A mixin rather than free functions because every method needs [_dao] and
/// [_random], and threading both through six signatures reads worse than
/// declaring that this is part of one object.
///
/// **Laying a session out is a second seam**, and it moved to
/// `study_queue_layout_repository_impl.dart` when this file crossed the guard's
/// 400 lines again: choosing which cards a session takes and dealing a stage's
/// first round happen once, at the moment a session opens; everything left here
/// happens once per answer.
mixin _StudyQueueOperations on _StudyQueueLayoutOperations {
  @override
  StudyDao get _dao;
  @override
  Random get _random;
  String Function() get _idGenerator;

  /// Declared, not defined: the stale-generation guard belongs to the session's
  /// lifecycle and commits outside the write transaction (BR-84). Naming it here
  /// is what lets [submitAnswer] stay next to the queue rules it applies without
  /// dragging that guard along with it.
  Future<StudySession> _invalidateIfStale(String sessionId);

  Future<StudyTurnModel?> nextTurn(String sessionId) async {
    final session = await _dao.sessionById(sessionId);
    if (session == null) return null;

    final row = await _dao.nextQueueItem(
      sessionId: sessionId,
      mode: session.currentMode,
      cursor: session.cursor,
    );
    if (row == null) return null;

    // Card content and counter come from the same call, not from two more
    // (AD-13): read on its own, the counter is drawn against a total from
    // before the answer that just landed.
    final card = await _dao.cardById(row.cardId);
    if (card == null) {
      throw const NotFoundFailure(message: 'Queued card no longer exists');
    }

    final progress = await _dao.stageRoundProgress(
      sessionId: sessionId,
      mode: session.currentMode,
      round: row.round,
    );
    final completed = await _dao.completedInRound(
      sessionId: sessionId,
      mode: session.currentMode,
      round: row.round,
    );
    // What the round holds, not what the session holds (BR-156). `match` deals
    // its boards from this; from round 2 the two are different lists.
    final roundCardIds = await _dao.cardsInRound(
      sessionId: sessionId,
      mode: session.currentMode,
      round: row.round,
    );

    return StudyTurnModel(
      item: studyQueueItemEntityFromRow(row),
      card: studyCardModelFromRow(card),
      progress: StudyStageProgressModel(
        round: row.round,
        done: progress.done,
        total: progress.total,
        completedCardIds: completed,
        roundCardIds: roundCardIds,
      ),
    );
  }

  Future<bool> isStageExhausted(String sessionId) async {
    final session = await _dao.sessionById(sessionId);
    if (session == null) return true;

    final pending = await _dao.pendingInStage(
      sessionId: sessionId,
      mode: session.currentMode,
    );

    return pending == 0;
  }

  Future<StudyAnswerCommitModel> submitAnswer({
    required String sessionId,
    required String cardId,
    required StudyMode mode,
    required StudyAction action,
    required DateTime now,
    StudyOutcomeReason? outcomeReason,
    int? comparisonVersion,
    bool? usedHint,
    DateTime? nextDueAt,
    int? nextBox,
    double? nextEaseFactor,
    int? nextIntervalDays,
  }) async {
    // **Outside the transaction, deliberately.** BR-84 wants two things at once:
    // the turn must not be written, and the session must end `invalidated`. A
    // rollback cannot deliver both — the invalidation would roll back with
    // everything else, and the session would sit there still offering to accept
    // turns it can never accept. So the stale check runs first and commits its
    // own write, and the transaction below re-checks and merely refuses.
    final session = await _invalidateIfStale(sessionId);

    return _dao.runInTransaction(() async {
      final round = await _dao.currentRound(
        sessionId: sessionId,
        mode: mode.dbValue,
      );
      if (round == null) {
        throw const ConflictFailure(message: 'Stage has nothing pending');
      }

      final item = await _dao.queueItem(
        sessionId: sessionId,
        mode: mode.dbValue,
        round: round,
        cardId: cardId,
      );
      if (item == null) {
        throw const NotFoundFailure(message: 'Card is not in this stage');
      }

      final state = await _dao.studyStateOf(cardId);
      if (state == null) {
        throw const NotFoundFailure(message: 'Card has no study state');
      }

      // BR-120, asked of the card's own row rather than of the caller, and
      // inside the transaction: a use case that forgot to check, or checked
      // against a deck that has changed algorithm since, still cannot get past
      // here. It costs no query — the type is already read for the row below.
      if (!isCanonicalAction(
        action,
        type: SchedulerType.fromDbValue(state.schedulerType),
      )) {
        throw ConflictFailure(
          message:
              'This deck\'s algorithm does not use "${action.dbValue}" here',
        );
      }

      // The one place `kind` is decided, and it is decided from the session and
      // the queue row rather than from what the schedule looks like afterwards
      // (BR-76). A `scheduled` turn answered `remembered` on a box-8 card leaves
      // the box untouched, so the shape of the data cannot tell the two apart.
      final kind = switch (session.sessionKind) {
        'learning' => StudyAnswerKind.learning,
        _ when item.answersInSession == 0 => StudyAnswerKind.scheduled,
        _ => StudyAnswerKind.relearning,
      };

      await _dao.insertAnswer(
        StudyAnswersCompanion.insert(
          id: _idGenerator(),
          cardId: cardId,
          sessionId: sessionId,
          schedulerType: state.schedulerType,
          schedulerGeneration: session.schedulerGeneration,
          kind: kind.dbValue,
          mode: mode.dbValue,
          action: action.dbValue,

          // BR-185, read off `item` rather than taken from the caller: a
          // history row that disagrees with the queue row it was answered on
          // cannot be repaired afterwards (BR-76).
          direction: Value<String?>(item.direction),
          answeredAt: now,
          outcomeReason: Value<String?>(outcomeReason?.dbValue),
          comparisonVersion: Value<int?>(comparisonVersion),
          usedHint: Value<int?>(usedHint == null ? null : (usedHint ? 1 : 0)),
          nextDueAt: Value<DateTime?>(kind.movesSchedule ? nextDueAt : null),
          previousBox: Value<int?>(state.currentBox),
          nextBox: Value<int?>(kind.movesSchedule ? nextBox : state.currentBox),
          previousEaseFactor: Value<double?>(state.easeFactor),
          nextEaseFactor: Value<double?>(
            kind.movesSchedule ? nextEaseFactor : state.easeFactor,
          ),
          previousIntervalDays: Value<int?>(state.intervalDays),
          nextIntervalDays: Value<int?>(
            kind.movesSchedule ? nextIntervalDays : state.intervalDays,
          ),
        ),
      );

      final status = await _applyQueueEffect(
        session: session,
        item: item,
        mode: mode,
        action: action,
        round: round,
      );
      final commit = StudyAnswerCommitModel(
        cardId: cardId,
        round: round,
        currentItemStatus: status,
      );

      await _dao.updateSession(
        sessionId,
        StudySessionsCompanion(cursor: Value<int>(session.cursor + 1)),
      );

      if (!kind.movesSchedule) {
        // `relearning` touches the stamp and nothing else (BR-78); a `learning`
        // turn changes no schedule at all (BR-141, BR-144), and its stamp belongs
        // to the completion event rather than to each stage.
        if (kind == StudyAnswerKind.relearning) {
          await _dao.updateStudyState(
            cardId,
            CardStudyStatesCompanion(lastAnsweredAt: Value<DateTime?>(now)),
          );
        }

        return commit;
      }

      await _dao.updateStudyState(
        cardId,
        CardStudyStatesCompanion(
          dueAt: Value<DateTime?>(nextDueAt),
          lastAnsweredAt: Value<DateTime?>(now),
          answerCount: Value<int>(state.answerCount + 1),
          lapseCount: Value<int>(state.lapseCount + (action.isLapse ? 1 : 0)),
          currentBox: Value<int?>(nextBox ?? state.currentBox),
          easeFactor: Value<double?>(nextEaseFactor ?? state.easeFactor),
          intervalDays: Value<int?>(nextIntervalDays ?? state.intervalDays),
        ),
      );

      return commit;
    });
  }

  Future<void> markBrowsed({
    required String sessionId,
    required String cardId,
  }) => _dao.runInTransaction(() async {
    final session = await _invalidateIfStale(sessionId);

    final round = await _dao.currentRound(
      sessionId: sessionId,
      mode: StudyMode.browse.dbValue,
    );
    if (round == null) return;

    await _dao.updateQueueItem(
      sessionId: sessionId,
      mode: StudyMode.browse.dbValue,
      round: round,
      cardId: cardId,
      values: const StudyQueueItemsCompanion(
        status: Value<String>('completed'),
      ),
    );

    // The cursor still moves. It counts turns served, and a browsed card was
    // served — BR-26's comeback gap is measured in cards seen, not in cards
    // graded.
    await _dao.updateSession(
      sessionId,
      StudySessionsCompanion(cursor: Value<int>(session.cursor + 1)),
    );
  });

  /// What the answer does to the queue — the half of the rules that differ by
  /// mode, executed from the mode's own [StudyLapsePolicy] rather than from its
  /// name.
  ///
  /// **This used to open with `if (mode == StudyMode.match)`.** That is a second
  /// exhaustive branch on [StudyMode], in the layer furthest from the one file
  /// AD-18 allows one in — and it would have grown a third arm the first time
  /// another mode wanted to keep its card on screen. The policy says what to do;
  /// nothing here knows which mode asked.
  ///
  /// Returns the status the row holds afterwards, because the caller cannot
  /// work it out: `isLapse` is what the user did, and two policies turn the same
  /// lapse into different rows.
  Future<StudyQueueItemStatus> _applyQueueEffect({
    required StudySession session,
    required StudyQueueItem item,
    required StudyMode mode,
    required StudyAction action,
    required int round,
  }) async {
    final answers = item.answersInSession + 1;

    Future<StudyQueueItemStatus> writeItem(
      StudyQueueItemsCompanion values, {
      required StudyQueueItemStatus status,
    }) async {
      await _dao.updateQueueItem(
        sessionId: session.id,
        mode: mode.dbValue,
        round: round,
        cardId: item.cardId,
        values: values,
      );

      return status;
    }

    Future<StudyQueueItemStatus> complete() => writeItem(
      StudyQueueItemsCompanion(
        status: const Value<String>('completed'),
        answersInSession: Value<int>(answers),
      ),
      status: StudyQueueItemStatus.completed,
    );

    if (!action.isLapse) return complete();

    // **Enrolled at the moment of failure, not when the round ends.** BR-116
    // says a card that failed at any point in a round belongs to the failed set
    // even if it is later answered correctly to clear the board — and the only
    // way a later correct answer cannot erase that is for the record to already
    // exist. Round N+1's membership *is* the record.
    //
    // Its position is drawn at random rather than taken from failure order,
    // which is what gives the next round its own shuffle (BR-117).
    // `insertOrIgnore`, so failing the same card four times enrols it once.
    Future<void> enrolNextRound() => _dao.enrolInRound(
      StudyQueueItemsCompanion.insert(
        sessionId: session.id,
        mode: mode.dbValue,
        round: Value<int>(round + 1),
        cardId: item.cardId,
        position: _random.nextInt(1 << 30),
        status: 'pending',

        // The direction travels with the card, not with the round (BR-184).
        // Null on every path that reaches here today — no round-based mode is
        // eligible — and written anyway, because the alternative is a silent
        // drop the day one becomes eligible.
        direction: Value<String?>(item.direction),
      ),
    );

    switch (studyModeHandler(mode)?.lapsePolicy) {
      case StudyLapsePolicy.retainAndEnrollNextRound:
        await enrolNextRound();

        // The row stays open: the card is still on the board and still has to
        // be answered (BR-118).
        return writeItem(
          StudyQueueItemsCompanion(answersInSession: Value<int>(answers)),
          status: StudyQueueItemStatus.pending,
        );

      case StudyLapsePolicy.completeAndEnrollNextRound:
        await enrolNextRound();

        return complete();

      case StudyLapsePolicy.spacedRetry:
        // The card stays in this one queue and comes back after at least three
        // others (BR-26) — or leaves and gets flagged once it has used its
        // three turns (BR-104).
        if (answers >= kSelfAssessRelearningCeiling) {
          await _dao.flagCard(item.cardId);

          return complete();
        }

        return writeItem(
          StudyQueueItemsCompanion(
            answersInSession: Value<int>(answers),
            availableAt: Value<int>(
              session.cursor + 1 + kSelfAssessComebackGap,
            ),
          ),
          status: StudyQueueItemStatus.pending,
        );

      // `browse` records no answer at all (BR-111), so it never reaches here;
      // a mode this build does not recognise cannot be run either (BR-107).
      // Completing the row is the safe reading of both: it is what the row
      // would have done before any policy existed.
      case StudyLapsePolicy.noAnswer:
      case null:
        return complete();
    }
  }
}
