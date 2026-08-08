import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

/// Data access for the Study side of the vertical.
///
/// Receives an already-open [AppDatabase] — `core/database/connection.dart` is
/// the only place that opens one (AD-08). Reads delegate to the typed queries in
/// `queries/study.drift`, so every piece of business SQL is checked by
/// `drift_dev` at build time (AD-02).
///
/// This class speaks Drift rows and companions. They stop here: the repository
/// maps them to domain entities and never lets one across (AD-01).
final class StudyDao {
  StudyDao(this._db);

  final AppDatabase _db;

  /// Runs [action] atomically.
  ///
  /// Every write below belongs inside one of these. A turn is a history row, a
  /// queue row, a cursor and — sometimes — a schedule; BR-86 says a half of that
  /// must not be able to exist.
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  // ---- reads -------------------------------------------------------------

  Future<List<NewCardsInTreeResult>> newCards(String rootDeckId, int limit) =>
      _db.newCardsInTree(rootDeckId, limit).get();

  /// Every unlearned card of a tree, for the `random` ordering (BR-148).
  Future<List<NewCardsInTreeAllResult>> allNewCards(String rootDeckId) =>
      _db.newCardsInTreeAll(rootDeckId).get();

  Future<List<DueCardsInTreeResult>> dueCards(
    String rootDeckId,
    DateTime now,
    int limit,
  ) => _db.dueCardsInTree(rootDeckId, now, limit).get();

  /// The four numbers the entry point needs, watched as one row (AD-13).
  ///
  /// Takes the deck the user opened — root or branch. The query resolves the
  /// root itself (BR-06, BR-57); it used to take a root and be handed whatever
  /// the screen had, so a study entry opened on a sub-deck counted nothing.
  Stream<StudyEntryCountsResult> watchEntryCounts(
    String deckId,
    DateTime now,
  ) => _db.studyEntryCounts(now, deckId).watchSingle();

  Future<StudyQueueItem?> nextQueueItem({
    required String sessionId,
    required String mode,
    required int cursor,
  }) => _db.nextQueueItem(sessionId, mode, cursor).getSingleOrNull();

  Future<int> pendingInStage({
    required String sessionId,
    required String mode,
  }) => _db.pendingInStage(sessionId, mode).getSingle();

  /// Done and total for one round of a stage — the counter and the bar.
  Future<StageRoundProgressResult> stageRoundProgress({
    required String sessionId,
    required String mode,
    required int round,
  }) => _db.stageRoundProgress(sessionId, mode, round).getSingle();

  /// The cards of a round that are already done — the board's ticks (§4).
  Future<List<String>> completedInRound({
    required String sessionId,
    required String mode,
    required int round,
  }) => _db.completedCardsInRound(sessionId, mode, round).get();

  /// The lowest pending round of a stage — the one being served.
  ///
  /// Null when nothing is pending. Written as a raw statement because
  /// `MIN(round)` over an empty set is SQL NULL, and the generated signature for
  /// a nullable aggregate is what makes that readable rather than a crash.
  Future<int?> currentRound({
    required String sessionId,
    required String mode,
  }) async {
    final row = await _db
        .customSelect(
          'SELECT MIN(round) AS round FROM study_queue_items '
          "WHERE session_id = ? AND mode = ? AND status = 'pending'",
          variables: <Variable<Object>>[
            Variable<String>(sessionId),
            Variable<String>(mode),
          ],
          readsFrom: <TableInfo<Table, Object?>>{_db.studyQueueItems},
        )
        .getSingle();

    return row.read<int?>('round');
  }

  Future<StudyQueueItem?> queueItem({
    required String sessionId,
    required String mode,
    required int round,
    required String cardId,
  }) => _db.queueItemAt(sessionId, mode, round, cardId).getSingleOrNull();

  Future<List<String>> sessionCardIds(String sessionId) =>
      _db.sessionCardIds(sessionId).get();

  Future<StudySession?> sessionById(String id) => (_db.select(
    _db.studySessions,
  )..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<StudySession?> openSessionForDeck(String deckId) =>
      _db.openSessionForDeck(deckId).getSingleOrNull();

  Future<List<StudySession>> staleOpenSessions(DateTime dayStart) =>
      _db.staleOpenSessions(dayStart).get();

  Future<Deck?> deckById(String id) =>
      (_db.select(_db.decks)..where((d) => d.id.equals(id))).getSingleOrNull();

  Future<CardStudyState?> studyStateOf(String cardId) => (_db.select(
    _db.cardStudyStates,
  )..where((s) => s.cardId.equals(cardId))).getSingleOrNull();

  /// Cards of a session that have no `pending` row left anywhere in it.
  ///
  /// Raw SQL rather than the generated API because the shape is an anti-join,
  /// and drift's query builder spells that as a correlated subquery either way.
  Future<List<String>> cardsWithNothingPending(String sessionId) async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT q.card_id AS cardId FROM study_queue_items q '
          'WHERE q.session_id = ? '
          '  AND NOT EXISTS ('
          '    SELECT 1 FROM study_queue_items p '
          "    WHERE p.session_id = q.session_id AND p.card_id = q.card_id "
          "      AND p.status = 'pending')",
          variables: <Variable<Object>>[Variable<String>(sessionId)],
          readsFrom: <TableInfo<Table, Object?>>{_db.studyQueueItems},
        )
        .get();

    return rows.map((row) => row.read<String>('cardId')).toList();
  }

  /// Everything the summary screen shows, in one statement.
  ///
  /// Four correlated subqueries rather than four round trips: the counts and the
  /// session's own outcome have to describe the same instant, and separate reads
  /// let a summary pair the counts of a completed session with the status of a
  /// failed one (AD-13).
  ///
  /// **No algorithm knowledge here.** Which actions mean "wrong" arrive as
  /// parameters, because `eight_box` says `forgotten` and `sm2` says `again`; a
  /// query naming either would report a clean sheet on half the decks. An empty
  /// list matches nothing, which `IN ()` cannot express in SQLite — hence the
  /// explicit `0`.
  Future<QueryRow> sessionSummaryRow({
    required String sessionId,
    required List<String> wrongActions,
  }) {
    final wrongFilter = wrongActions.isEmpty
        ? '0'
        : 'a."action" IN (${List<String>.filled(wrongActions.length, '?').join(', ')})';

    return _db
        .customSelect(
          'SELECT s.session_kind AS kind, s.status AS status, s.end_reason AS endReason, '
          '  (SELECT COUNT(DISTINCT q.card_id) FROM study_queue_items q '
          '     WHERE q.session_id = s.id '
          '       AND NOT EXISTS (SELECT 1 FROM study_queue_items p '
          '         WHERE p.session_id = q.session_id AND p.card_id = q.card_id '
          "         AND p.status = 'pending')) AS finishedCards, "
          '  (SELECT COUNT(DISTINCT a.card_id) FROM study_answers a '
          '     WHERE a.session_id = s.id) AS answeredCards, '
          '  (SELECT COUNT(*) FROM study_answers a '
          '     WHERE a.session_id = s.id AND '
          '$wrongFilter) AS wrongTurns, '
          '  (SELECT COUNT(*) FROM study_answers a '
          '     WHERE a.session_id = s.id) AS totalTurns '
          'FROM study_sessions s WHERE s.id = ?',
          variables: <Variable<Object>>[
            ...wrongActions.map(Variable<String>.new),
            Variable<String>(sessionId),
          ],
          readsFrom: <TableInfo<Table, Object?>>{
            _db.studySessions,
            _db.studyQueueItems,
            _db.studyAnswers,
          },
        )
        .getSingle();
  }

  Future<Card?> cardById(String id) =>
      (_db.select(_db.cards)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<AppSetting> appSettings() => _db.appSettingsRow().getSingle();

  /// Writes a root deck-s study options, and touches nothing else on the row.
  Future<void> updateDeckStudyConfig({
    required String deckId,
    required String studyConfig,
  }) => (_db.update(_db.decks)..where((d) => d.id.equals(deckId))).write(
    DecksCompanion(studyConfig: Value<String?>(studyConfig)),
  );

  // ---- writes ------------------------------------------------------------

  Future<void> insertSession(StudySessionsCompanion session) =>
      _db.into(_db.studySessions).insert(session);

  Future<void> insertQueueItems(List<StudyQueueItemsCompanion> items) =>
      _db.batch((batch) => batch.insertAll(_db.studyQueueItems, items));

  /// Adds a card to a later round, ignoring a row that is already there.
  ///
  /// `DoNothing` rather than a read-then-write: a card can fail twice in one
  /// round of `match`, and the second failure must not become a second row or a
  /// second position.
  Future<void> enrolInRound(StudyQueueItemsCompanion item) => _db
      .into(_db.studyQueueItems)
      .insert(item, mode: InsertMode.insertOrIgnore);

  Future<void> updateQueueItem({
    required String sessionId,
    required String mode,
    required int round,
    required String cardId,
    required StudyQueueItemsCompanion values,
  }) =>
      (_db.update(_db.studyQueueItems)..where(
            (q) =>
                q.sessionId.equals(sessionId) &
                q.mode.equals(mode) &
                q.round.equals(round) &
                q.cardId.equals(cardId),
          ))
          .write(values);

  /// Open sessions of one root deck.
  Future<List<StudySession>> openSessionsForRoot(String rootDeckId) =>
      (_db.select(_db.studySessions)..where(
            (s) =>
                s.rootDeckId.equals(rootDeckId) &
                s.status.equals('in_progress'),
          ))
          .get();

  Future<void> insertAnswer(StudyAnswersCompanion answer) =>
      _db.into(_db.studyAnswers).insert(answer);

  Future<void> updateSession(String id, StudySessionsCompanion values) =>
      (_db.update(
        _db.studySessions,
      )..where((s) => s.id.equals(id))).write(values);

  Future<void> updateStudyState(
    String cardId,
    CardStudyStatesCompanion values,
  ) => (_db.update(
    _db.cardStudyStates,
  )..where((s) => s.cardId.equals(cardId))).write(values);

  /// Turns the card's own flag on (BR-104).
  ///
  /// One direction only: the system may set it, and only the user clears it
  /// (BR-92).
  Future<void> flagCard(String cardId) =>
      (_db.update(_db.cards)..where((c) => c.id.equals(cardId))).write(
        const CardsCompanion(isFlagged: Value<int>(1)),
      );
}
