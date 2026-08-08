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
mixin _StudyQueueOperations {
  StudyDao get _dao;
  Random get _random;
  String Function() get _idGenerator;

  /// Declared, not defined: the stale-generation guard belongs to the session's
  /// lifecycle and commits outside the write transaction (BR-84). Naming it here
  /// is what lets [submitAnswer] stay next to the queue rules it applies without
  /// dragging that guard along with it.
  Future<StudySession> _invalidateIfStale(String sessionId);

  /// The card set for a session — one set, never both (BR-142).
  Future<List<StudyCardModel>> _cardsFor({
    required String rootDeckId,
    required StudySessionKind kind,
    required int cardLimit,
    required NewCardOrder newCardOrder,
    required DateTime now,
  }) async {
    if (kind == StudySessionKind.reviewing) {
      final due = await _dao.dueCards(rootDeckId, now, cardLimit);

      return due.map((row) => studyCardModelFromRow(row.c)).toList();
    }

    // `random` shuffles **before** the ceiling, and that ordering is the rule
    // rather than a detail. BR-113 gives every stage its own shuffle, so the
    // order this list is in never reaches the user — the only thing
    // `new_card_order` can decide is *which* new cards enter the session when
    // the deck has more than the limit. Shuffling after `LIMIT` reorders a set
    // already chosen by `created_at`, which is the same set every time: the
    // option looked implemented and did nothing at all.
    //
    // The shuffle stays in Dart because `RANDOM()` in SQL cannot be seeded, and
    // a shuffle no test can pin is a shuffle nobody can check.
    if (newCardOrder == NewCardOrder.created) {
      final fresh = await _dao.newCards(rootDeckId, cardLimit);

      return fresh.map((row) => studyCardModelFromRow(row.c)).toList();
    }

    final all = await _dao.allNewCards(rootDeckId);
    final cards = all.map((row) => studyCardModelFromRow(row.c)).toList()
      ..shuffle(_random);

    return cards.take(cardLimit).toList();
  }

  /// Round 1 of a stage: every card the stage can use, in an order of its own.
  ///
  /// **A card the mode cannot use gets no row at all** (BR-114). That is the
  /// difference between "skipped" and "stuck": with no row here, it has nothing
  /// left pending in this stage, so it finishes the learning chain alongside the
  /// others (BR-144). `fill` is the mode this matters for — `example` is
  /// optional, and an earlier reading would have frozen every card without one.
  ///
  /// Two independent shuffles per stage keep BR-117 true: sharing one order
  /// across stages would make the second stage a re-run of the first.
  List<StudyQueueItemsCompanion> _roundOne({
    required String sessionId,
    required StudyMode mode,
    required List<StudyCardModel> cards,
  }) {
    final handler = studyModeHandler(mode);

    // A stage that cannot run on this card set gets no rows at all (BR-99).
    // With none it is exhausted from the start, so the session advances past it
    // — the same path a `fill` stage takes when no card carries an example. The
    // alternative, which is what used to happen, is a stage full of rows whose
    // widget renders nothing and a session with nowhere to go.
    if (!(handler?.canRunOn(cards) ?? false)) {
      return const <StudyQueueItemsCompanion>[];
    }

    final usable = <StudyCardModel>[
      for (final card in cards)
        if (handler!.canTake(card)) card,
    ]..shuffle(_random);

    return <StudyQueueItemsCompanion>[
      for (final (index, card) in usable.indexed)
        StudyQueueItemsCompanion.insert(
          sessionId: sessionId,
          mode: mode.dbValue,
          cardId: card.id,
          position: index,
          status: 'pending',
        ),
    ];
  }

  Future<StudyTurnModel?> nextTurn(String sessionId) async {
    final session = await _dao.sessionById(sessionId);
    if (session == null) return null;

    final row = await _dao.nextQueueItem(
      sessionId: sessionId,
      mode: session.currentMode,
      cursor: session.cursor,
    );
    if (row == null) return null;

    // The card content comes from the same call, not a second one: the screen
    // needs both together, and two reads can straddle a write (AD-13).
    final card = await _dao.cardById(row.cardId);
    if (card == null) {
      throw const NotFoundFailure(message: 'Queued card no longer exists');
    }

    return StudyTurnModel(
      item: studyQueueItemEntityFromRow(row),
      card: studyCardModelFromRow(card),
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

  Future<void> submitAnswer({
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

      await _applyQueueEffect(
        session: session,
        item: item,
        mode: mode,
        action: action,
        round: round,
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

        return;
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
  /// mode.
  Future<void> _applyQueueEffect({
    required StudySession session,
    required StudyQueueItem item,
    required StudyMode mode,
    required StudyAction action,
    required int round,
  }) async {
    final answers = item.answersInSession + 1;

    Future<void> writeItem(StudyQueueItemsCompanion values) =>
        _dao.updateQueueItem(
          sessionId: session.id,
          mode: mode.dbValue,
          round: round,
          cardId: item.cardId,
          values: values,
        );

    if (!action.isLapse) {
      return writeItem(
        StudyQueueItemsCompanion(
          status: const Value<String>('completed'),
          answersInSession: Value<int>(answers),
        ),
      );
    }

    if (mode.usesRounds) {
      // **Enrolled at the moment of failure, not when the round ends.** BR-116
      // says a card that failed at any point in a round belongs to the failed
      // set even if it is later answered correctly to clear the board — and the
      // only way a later correct answer cannot erase that is for the record to
      // already exist. Round N+1's membership *is* the record.
      //
      // Its position is drawn at random rather than taken from failure order,
      // which is what gives the next round its own shuffle (BR-117).
      await _dao.enrolInRound(
        StudyQueueItemsCompanion.insert(
          sessionId: session.id,
          mode: mode.dbValue,
          round: Value<int>(round + 1),
          cardId: item.cardId,
          position: _random.nextInt(1 << 30),
          status: 'pending',
        ),
      );

      return writeItem(
        StudyQueueItemsCompanion(
          status: const Value<String>('completed'),
          answersInSession: Value<int>(answers),
        ),
      );
    }

    // `self_assess`: the card stays in this one queue and comes back after at
    // least three others (BR-26) — or leaves and gets flagged once it has used
    // its three turns (BR-104).
    if (answers >= kSelfAssessRelearningCeiling) {
      await _dao.flagCard(item.cardId);

      return writeItem(
        StudyQueueItemsCompanion(
          status: const Value<String>('completed'),
          answersInSession: Value<int>(answers),
        ),
      );
    }

    return writeItem(
      StudyQueueItemsCompanion(
        answersInSession: Value<int>(answers),
        availableAt: Value<int>(session.cursor + 1 + kSelfAssessComebackGap),
      ),
    );
  }
}
