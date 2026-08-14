import 'dart:async';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/domain/entities/study_session_entity.dart';
import 'package:memox/features/study/domain/failures/study_refusal_failure.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_deck_context_model.dart';
import 'package:memox/features/study/domain/models/study_entry_summary_model.dart';
import 'package:memox/features/study/domain/models/study_answer_commit_model.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_lapse_policy_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_options_model.dart';
import 'package:memox/features/study/domain/models/study_outcome_reason_model.dart';
import 'package:memox/features/study/domain/models/study_schedule_model.dart';
import 'package:memox/features/study/domain/models/study_card_limit_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_session_summary_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';
import 'package:memox/features/study/domain/repositories/study_repository.dart';

part 'fake_study_lifecycle.dart';

/// A `StudyRepository` a use-case test drives by hand, which **records
/// arguments rather than simulating a queue.** The queue engine is
/// tested against a real database in `test/features/study/data/`; repeating it
/// here would test the double. These tests are about the decision a use case
/// makes *before* the write — which stage, which schedule, which scheduler.
/// Not `final`: controller tests subclass it — one fails every write, one defers
/// its first read — and the alternative is a constructor flag for each, which
/// spreads test-only branching through the double.
base class FakeStudyRepository
    with _FakeStudyLifecycleStubs
    implements StudyRepository {
  FakeStudyRepository({
    this.schedulerType = SchedulerType.eightBox,
    this.cardLimit = 20,
    this.newCardOrder = NewCardOrder.created,
    this.schedule = const StudyScheduleModel(box: 3),
    this.stageExhausted = true,
    this.finishedCardIds = const <String>[],
    this.openSessionFails = false,
  });

  final SchedulerType schedulerType;
  final int cardLimit;
  final NewCardOrder newCardOrder;
  final StudyScheduleModel? schedule;
  final bool stageExhausted;
  final List<String> finishedCardIds;

  /// Makes [openSession] refuse the way the real one does when nothing is due.
  final bool openSessionFails;

  final List<({StudySessionKind kind, List<StudyMode> stages, int limit})>
  opened = <({StudySessionKind kind, List<StudyMode> stages, int limit})>[];

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

  final List<({String cardId, DateTime learnedAt, DateTime dueAt, int? box})>
  completed =
      <({String cardId, DateTime learnedAt, DateTime dueAt, int? box})>[];

  final List<StudyMode> advancedTo = <StudyMode>[];

  StudySessionEntity? openSession_;

  @override
  Future<StudyDeckContextModel> deckContext(String deckId) async =>
      StudyDeckContextModel(
        deckId: deckId,
        deckName: 'Korean',
        rootDeckId: 'root',
        schedulerType: schedulerType,
        schedulerGeneration: 1,
      );

  /// Whether [effectiveOptions] reports the values as a root override
  /// (BR-184). Drives whether `Use app defaults` is offered at all.
  bool isRootOverride = false;

  @override
  Future<StudyOptionsModel> effectiveOptions(String rootDeckId) async =>
      StudyOptionsModel(
        cardLimit: cardLimit,
        newCardOrder: newCardOrder,
        isRootOverride: isRootOverride,
      );

  @override
  Future<StudyScheduleModel?> scheduleOf(String cardId) async => schedule;

  List<StudyCardModel> cards = const <StudyCardModel>[];

  @override
  Future<List<StudyCardModel>> sessionCards(String sessionId) async => cards;

  @override
  Future<List<String>> cardsFinishedInSession(String sessionId) async =>
      finishedCardIds;

  @override
  Future<StudySessionEntity> openSession({
    required String deckId,
    required StudySessionKind kind,
    required List<StudyMode> stageSequence,
    required int cardLimit,
    required NewCardOrder newCardOrder,
    required DateTime now,
  }) async {
    if (openSessionFails) {
      throw const ConflictFailure(
        message: 'Nothing to study',
        reason: StudyRefusalReason.nothingDueToReview,
      );
    }

    opened.add((kind: kind, stages: stageSequence, limit: cardLimit));

    return StudySessionEntity(
      id: 'session-1',
      deckId: deckId,
      rootDeckId: 'root',
      schedulerGeneration: 1,
      kind: kind,
      currentMode: stageSequence.first,
      status: StudySessionStatus.inProgress,
      endReason: null,
      cursor: 0,
      cardLimit: cardLimit,
      startedAt: now,
      endedAt: null,
    );
  }

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

  @override
  Future<void> completeLearning({
    required String cardId,
    required DateTime learnedAt,
    required DateTime dueAt,
    int? box,
    int? intervalDays,
  }) async {
    completed.add((
      cardId: cardId,
      learnedAt: learnedAt,
      dueAt: dueAt,
      box: box,
    ));
  }

  @override
  Future<void> advanceStage({
    required String sessionId,
    required StudyMode mode,
    required DateTime now,
  }) async {
    advancedTo.add(mode);
  }

  /// Set to hold [nextTurn] open until the test completes it.
  ///
  /// **On `nextTurn`, not on `advanceStage`.** A stage that is not exhausted
  /// never reaches `advanceStage` — `AdvanceStudyStageUseCase` returns the
  /// current mode and stops — so a gate there is a gate the fetch walks past.
  /// Every advance goes through `nextTurn`, which is the window the screen
  /// calls `isAdvancing`.
  Completer<void>? nextTurnGate;

  @override
  Future<StudySessionEntity?> openSessionFor(String deckId) async =>
      openSession_;

  /// What was saved, and against which deck.
  ///
  /// The deck is recorded because BR-147 is about *where* the write lands: the
  /// repository resolves to the root, and only the argument shows whether a
  /// caller was allowed to skip that.
  final List<({String deckId, int cardLimit, NewCardOrder order})>
  savedOptions = <({String deckId, int cardLimit, NewCardOrder order})>[];

  @override
  Future<void> saveStudyOptions({
    required String deckId,
    required StudyCardLimit cardLimit,
    required NewCardOrder newCardOrder,
  }) async => savedOptions.add((
    deckId: deckId,
    cardLimit: cardLimit.value,
    order: newCardOrder,
  ));

  /// Every deck whose override was cleared (BR-184), in call order.
  final List<String> clearedOverrides = <String>[];

  @override
  Future<void> clearStudyOptionsOverride(String deckId) async =>
      clearedOverrides.add(deckId);

  /// What the summary read returns, and what it was asked.
  ///
  /// The actions are recorded because they are the whole point of the
  /// parameter: a summary that asked for `forgotten` on an `sm2` deck would
  /// report a clean sheet, and only the argument shows that.
  StudySessionSummaryModel? summary_;
  List<StudyAction>? summaryWrongActions;

  /// How many times the summary was read.
  ///
  /// Counted because the rule is about the number of reads, not their content:
  /// four statements would return four correct numbers from four different
  /// instants (AD-13).
  int summaryReads = 0;

  @override
  Future<StudySessionSummaryModel> sessionSummary({
    required String sessionId,
    required List<StudyAction> wrongActions,
  }) async {
    summaryReads += 1;
    summaryWrongActions = wrongActions;

    return summary_ ??
        const StudySessionSummaryModel(
          kind: StudySessionKind.learning,
          status: StudySessionStatus.completed,
          endReason: null,
          finishedCards: 0,
          answeredCards: 0,
          wrongTurns: 0,
          totalTurns: 0,
        );
  }

  /// Answers for successive `isStageExhausted` calls, consumed in order.
  ///
  /// One boolean is not enough now that advancing walks past every exhausted
  /// stage (BR-99): "this stage is done and the next one is not" takes two
  /// answers, and a single flag can only say "every stage is done", which ends
  /// the session.
  final List<bool> exhaustedAnswers = <bool>[];
  int _exhaustedCalls = 0;

  @override
  Future<bool> isStageExhausted(String sessionId) async {
    final index = _exhaustedCalls++;

    return index < exhaustedAnswers.length
        ? exhaustedAnswers[index]
        : stageExhausted;
  }

  @override
  Future<StudyTurnModel?> nextTurn(String sessionId) async {
    nextTurnCalls++;
    final gate = nextTurnGate;
    if (gate != null) await gate.future;

    return nextTurn_;
  }

  StudyTurnModel? nextTurn_;

  /// Holds every write open: the window between the tap and the commit that
  /// BR-157 is about.
  Completer<void>? submitGate;

  /// How many times a turn has been read. **A count, because the change under
  /// test is an absence:** `match` reads once a board, and counting is the only
  /// way to catch a reload creeping back between two taps.
  int nextTurnCalls = 0;

  final List<({String cardId, int? remainingMs, bool isRevealed})> progress =
      <({String cardId, int? remainingMs, bool isRevealed})>[];

  @override
  Future<void> saveTurnProgress({
    required String sessionId,
    required StudyMode mode,
    required String cardId,
    int? remainingMs,
    bool isRevealed = false,
  }) async => progress.add((
    cardId: cardId,
    remainingMs: remainingMs,
    isRevealed: isRevealed,
  ));

  final List<String> browsed = <String>[];

  @override
  Future<void> markBrowsed({
    required String sessionId,
    required String cardId,
  }) async => browsed.add(cardId);

  @override
  Future<bool> buildNextRound(String sessionId) async => false;

  @override
  Stream<StudyEntrySummaryModel> watchStudyEntry(
    String deckId, {
    required DateTime now,
  }) => Stream<StudyEntrySummaryModel>.value(
    const StudyEntrySummaryModel(
      newCount: 3,
      dueCount: 4,
      fillableCount: 1,
      distinctMeanings: 4,
    ),
  );
}
