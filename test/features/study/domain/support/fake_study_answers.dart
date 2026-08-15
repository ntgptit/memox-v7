part of 'fake_study_repository.dart';

/// What a **turn** recorded, split off the main fake at the guard's 400-line
/// mark — the same seam `_FakeStudyLifecycleStubs` took for what a *session*
/// recorded, and the same one the real repository takes.
///
/// A test asking "what did the user answer" reads it from one place here rather
/// than from a field buried in a four-hundred-line double.
// `implements StudyRepository` so the `@override` below stays meaningful: a
// signature drifting from the contract has to fail here, not only in the
// concrete class.
mixin _FakeStudyAnswerStubs implements StudyRepository {
  /// Supplied by the concrete fake — a test holds this to keep a write in
  /// flight and assert on what the screen does meanwhile.
  Completer<void>? get submitGate;

  /// Supplied by the concrete fake: which cards the mode's policy considers
  /// finished, which is what the receipt below is built from.
  List<String> get finishedCardIds;

  final List<
    ({
      String cardId,
      StudyMode mode,
      StudyAction action,
      DateTime? nextDueAt,
      int? nextBox,
      int? nextIntervalDays,
      double? nextEaseFactor,
    })
  >
  answers =
      <
        ({
          String cardId,
          StudyMode mode,
          StudyAction action,
          DateTime? nextDueAt,
          int? nextBox,
          int? nextIntervalDays,
          double? nextEaseFactor,
        })
      >[];

  @override
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
    final gate = submitGate;
    if (gate != null) await gate.future;

    answers.add((
      cardId: cardId,
      mode: mode,
      action: action,
      nextDueAt: nextDueAt,
      nextBox: nextBox,
      nextIntervalDays: nextIntervalDays,
      nextEaseFactor: nextEaseFactor,
    ));

    // **Read from the mode's policy, not invented here.** The receipt is what
    // the controller acts on, so a fake that always said `completed` would let
    // a `match` lapse clear its slot in every widget test while the database
    // keeps the row open (BR-118).
    final retains =
        action.isLapse &&
        studyModeHandler(mode)?.lapsePolicy ==
            StudyLapsePolicy.retainAndEnrollNextRound;

    return StudyAnswerCommitModel(
      cardId: cardId,
      round: 1,
      currentItemStatus: retains
          ? StudyQueueItemStatus.pending
          : StudyQueueItemStatus.completed,
    );
  }
}
