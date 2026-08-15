import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/entities/study_session_entity.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_card_limit_model.dart';
import 'package:memox/features/study/domain/models/study_deck_context_model.dart';
import 'package:memox/features/study/domain/models/study_entry_summary_model.dart';
import 'package:memox/features/study/domain/models/study_answer_commit_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_options_model.dart';
import 'package:memox/features/study/domain/models/study_outcome_reason_model.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_schedule_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_summary_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';
import 'package:memox/features/study/domain/models/study_day_model.dart';
import 'package:memox/features/study/domain/models/study_home_deck_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/models/study_home_resume_model.dart';
import 'package:memox/features/study/domain/repositories/study_home_repository.dart';
import 'package:memox/features/study/domain/repositories/study_repository.dart';

/// The states of the Study screens worth putting in front of somebody.
enum StudyCatalogScenario {
  learningBrowse('learning · browse', StudyMode.browse),
  learningMatch('learning · match', StudyMode.match),
  learningGuess('learning · guess', StudyMode.guess),
  learningRecall('learning · recall', StudyMode.recall),
  learningFill('learning · fill', StudyMode.fill),
  reviewSelfAssess('review · self-assess (sm2)', StudyMode.selfAssess),
  nothingDue('entry · nothing due', StudyMode.browse),
  nothingLeft('entry · everything learned', StudyMode.browse),
  longContent('long Vietnamese content', StudyMode.browse);

  const StudyCatalogScenario(this.label, this.mode);

  final String label;
  final StudyMode mode;

  bool get isReview => this == StudyCatalogScenario.reviewSelfAssess;

  SchedulerType get scheduler =>
      isReview ? SchedulerType.sm2 : SchedulerType.eightBox;

  int get newCount => switch (this) {
    StudyCatalogScenario.nothingLeft => 0,
    StudyCatalogScenario.reviewSelfAssess => 0,
    _ => 5,
  };

  int get dueCount => switch (this) {
    StudyCatalogScenario.reviewSelfAssess => 7,
    StudyCatalogScenario.nothingLeft => 3,
    _ => 0,
  };
}

/// Enough of [StudyRepository] to drive the three Study screens in the catalog.
///
/// **The app's test doubles live under `test/`, which another package cannot
/// reach** — that is the whole reason the Study screens sat outside this catalog
/// while Deck's screen sat inside it. This is the catalog's own double, and it
/// stays deliberately dumb: reads are deterministic per scenario, writes are
/// no-ops. The catalog shows states; it does not simulate a session.
///
/// Nothing here re-implements a rule. Which stages exist, which actions a deck
/// offers and what a wrong answer does are all decided above this by the real
/// use cases and the real scheduler — a fake that decided any of them would be a
/// second copy of the rules, and the copy is what the catalog would then show.
class StudyCatalogRepository implements StudyRepository {
  StudyCatalogRepository(this.scenario);

  final StudyCatalogScenario scenario;

  static final DateTime _t0 = DateTime.utc(2026, 8, 8, 2);

  static const List<(String, String, String?)> _plain =
      <(String, String, String?)>[
        ('사과', 'apple', 'I ate an apple.'),
        ('물', 'water', 'A glass of water.'),
        ('책', 'book', 'She read the book.'),
        ('산', 'mountain', 'We climbed the mountain.'),
        ('바다', 'sea', 'The sea was calm.'),
      ];

  static const List<(String, String, String?)> _long =
      <(String, String, String?)>[
        (
          '학술적 어휘 평가 시험',
          'Bộ từ vựng học thuật dành cho kỳ thi đánh giá năng lực chuyên sâu',
          'Câu ví dụ dài để kiểm tra cách thẻ xuống dòng ở màn hình hẹp.',
        ),
        ('물', 'nước uống hằng ngày', null),
        ('책', 'quyển sách giáo khoa', null),
        ('산', 'ngọn núi cao phía bắc', null),
        ('바다', 'biển cả mênh mông', null),
      ];

  List<(String, String, String?)> get _source =>
      scenario == StudyCatalogScenario.longContent ? _long : _plain;

  List<StudyCardModel> get _cards => <StudyCardModel>[
    for (final (index, entry) in _source.indexed)
      StudyCardModel(
        id: 'c$index',
        front: entry.$1,
        back: entry.$2,
        example: entry.$3,
        hint: index == 0 ? 'Starts with a.' : null,
        pronunciation: null,
        frontFolded: entry.$1.toLowerCase(),
        backFolded: entry.$2.toLowerCase(),
      ),
  ];

  StudySessionEntity get _session => StudySessionEntity(
    id: 'catalog-session',
    deckId: 'catalog-deck',
    rootDeckId: 'catalog-root',
    schedulerGeneration: 1,
    kind: scenario.isReview
        ? StudySessionKind.reviewing
        : StudySessionKind.learning,
    currentMode: scenario.mode,
    status: StudySessionStatus.inProgress,
    endReason: null,
    cursor: 0,
    cardLimit: 20,
    startedAt: _t0,
    endedAt: null,
  );

  @override
  Stream<StudyEntrySummaryModel> watchStudyEntry(
    String deckId, {
    required DateTime now,
  }) => Stream<StudyEntrySummaryModel>.value(
    StudyEntrySummaryModel(
      newCount: scenario.newCount,
      dueCount: scenario.dueCount,
      fillableCount: scenario.dueCount,
      distinctMeanings: scenario.dueCount,
    ),
  );

  @override
  Future<StudyDeckContextModel> deckContext(String deckId) async =>
      StudyDeckContextModel(
        deckId: deckId,
        deckName: 'Chapter 1',
        rootDeckId: 'catalog-root',
        schedulerType: scenario.scheduler,
        schedulerGeneration: 1,
      );

  @override
  Future<StudySessionEntity> openSession({
    required String deckId,
    required StudySessionKind kind,
    required List<StudyMode> stageSequence,
    required int cardLimit,
    required NewCardOrder newCardOrder,
    required DateTime now,
  }) async => _session;

  @override
  Future<StudyTurnModel?> nextTurn(String sessionId) async => StudyTurnModel(
    item: StudyQueueItemEntity(
      sessionId: sessionId,
      mode: scenario.mode,
      round: 1,
      cardId: 'c0',
      position: 0,
      status: StudyQueueItemStatus.pending,
      availableAt: 0,
      answersInSession: 0,
      remainingMs: null,
      isRevealed: false,
    ),
    card: _cards.first,
    progress: const StudyStageProgressModel(
      round: 1,
      done: 2,
      total: 5,
      completedCardIds: <String>[],
    ),
  );

  @override
  Future<List<StudyCardModel>> sessionCards(String sessionId) async => _cards;

  @override
  Future<bool> isStageExhausted(String sessionId) async => false;

  @override
  Future<StudyOptionsModel> effectiveOptions(String rootDeckId) async =>
      StudyOptionsModel(
        cardLimit: StudyCardLimit.parse('20').limit!.value,
        newCardOrder: NewCardOrder.created,
      );

  @override
  Future<StudySessionSummaryModel> sessionSummary({
    required String sessionId,
    required List<StudyAction> wrongActions,
  }) async => StudySessionSummaryModel(
    kind: _session.kind,
    status: StudySessionStatus.completed,
    endReason: null,
    finishedCards: 4,
    answeredCards: 5,
    wrongTurns: 2,
    totalTurns: 11,
  );

  @override
  Future<StudySessionEntity?> openSessionFor(String deckId) async => null;

  /// Null for the same reason [openSessionFor] is: the catalog never resumes,
  /// it opens a fresh scenario every time the dropdown changes.
  @override
  Future<StudySessionEntity?> sessionById(String sessionId) async => null;

  @override
  Future<StudyScheduleModel?> scheduleOf(String cardId) async =>
      const StudyScheduleModel(box: 3);

  @override
  Future<List<String>> cardsFinishedInSession(String sessionId) async =>
      const <String>[];

  @override
  Future<bool> buildNextRound(String sessionId) async => false;

  @override
  Future<int> abandonStaleSessions({required DateTime dayStart}) async => 0;

  @override
  Future<int> invalidateSessionsForRoot({
    required String rootDeckId,
    required DateTime endedAt,
    required StudySessionEndReason reason,
  }) async => 0;

  // --- Writes: no-ops, so a control can be pressed without a database. ---

  @override
  Future<void> saveStudyOptions({
    required String deckId,
    required StudyCardLimit cardLimit,
    required NewCardOrder newCardOrder,
  }) async {}

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
  }) async => StudyAnswerCommitModel(
    cardId: cardId,
    round: 1,
    // The catalog never advances a session, so any status is a lie of the same
    // size; `completed` is the one that reads as "this went through".
    currentItemStatus: StudyQueueItemStatus.completed,
  );

  @override
  Future<void> markBrowsed({
    required String sessionId,
    required String cardId,
  }) async {}

  @override
  Future<void> completeLearning({
    required String cardId,
    required DateTime learnedAt,
    required DateTime dueAt,
    int? box,
    int? intervalDays,
  }) async {}

  @override
  Future<void> advanceStage({
    required String sessionId,
    required StudyMode mode,
    required DateTime now,
  }) async {}

  @override
  Future<void> saveTurnProgress({
    required String sessionId,
    required StudyMode mode,
    required String cardId,
    int? remainingMs,
    bool isRevealed = false,
  }) async {}

  @override
  Future<void> endSession({
    required String sessionId,
    required StudySessionStatus status,
    required StudySessionEndReason? reason,
    required DateTime endedAt,
  }) async {}
}

/// Enough of [StudyHomeRepository] to show the Study tab's own screen (UC-14).
///
/// **The read-only contract, separate from the one above** — that split is what
/// makes Study Home unable to open a session (BR-200), and a catalog double that
/// merged the two would show a screen with a wider surface than production has.
///
/// Deterministic per scenario, like everything else here. The ordering is *not*
/// re-implemented: the rows are handed over unsorted and `compareStudyHomeDecks`
/// — the production comparator — puts them in order, so the catalog shows the
/// ranking the app actually applies rather than one written twice.
class StudyHomeCatalogRepository implements StudyHomeRepository {
  StudyHomeCatalogRepository(this.scenario);

  final StudyCatalogScenario scenario;

  @override
  Stream<StudyHomeModel> watchStudyHome(StudyDayModel day) {
    final decks = scenario.homeDecks..sort(compareStudyHomeDecks);

    return Stream<StudyHomeModel>.value(
      StudyHomeModel(
        resume: scenario.homeResume,
        decks: decks,
        nextDueAt: null,
        nextOverdueTickAt: null,
      ),
    );
  }
}

/// The library each Study Home scenario shows.
extension StudyHomeCatalogScenario on StudyCatalogScenario {
  /// The session offered back, when the scenario has one open.
  ///
  /// Only the review scenario does. A Resume card on every state would make the
  /// screen's most conditional element look unconditional.
  StudyHomeResumeModel? get homeResume =>
      this != StudyCatalogScenario.reviewSelfAssess
      ? null
      : const StudyHomeResumeModel(
          sessionId: 'catalog-session',
          deckId: 'catalog-deck',
          deckName: 'Tiếng Hàn giao tiếp',
          kind: StudySessionKind.reviewing,
          currentMode: StudyMode.selfAssess,
        );

  List<StudyHomeDeckModel> get homeDecks => switch (this) {
    // The first-run screen: no deck at all, so the catalog can show the starter
    // call to action rather than only the populated list.
    StudyCatalogScenario.nothingDue => <StudyHomeDeckModel>[],
    StudyCatalogScenario.longContent => <StudyHomeDeckModel>[
      _homeDeck(
        id: 'catalog-long',
        name: 'Từ vựng chuyên ngành công nghệ thông tin và truyền thông',
        overdue: 128,
        dueToday: 64,
        newCount: 256,
      ),
    ],
    _ => <StudyHomeDeckModel>[
      _homeDeck(id: 'catalog-deck', name: 'Tiếng Hàn giao tiếp', dueToday: 7),
      _homeDeck(
        id: 'catalog-kanji',
        name: 'Kanji cơ bản',
        scheduler: SchedulerType.sm2,
        overdue: 3,
        newCount: 12,
      ),
      _homeDeck(id: 'catalog-idioms', name: 'Thành ngữ'),
    ],
  };
}

StudyHomeDeckModel _homeDeck({
  required String id,
  required String name,
  SchedulerType scheduler = SchedulerType.eightBox,
  int overdue = 0,
  int dueToday = 0,
  int newCount = 0,
}) => StudyHomeDeckModel(
  deckId: id,
  deckName: name,
  schedulerType: scheduler,
  // Enough cards to hold the workload and then some, so a deck with nothing
  // waiting still renders as a studiable deck rather than as the empty-library
  // state (BR-202).
  totalCardCount: overdue + dueToday + newCount + 20,
  overdueCount: overdue,
  dueTodayCount: dueToday,
  newCount: newCount,
);
