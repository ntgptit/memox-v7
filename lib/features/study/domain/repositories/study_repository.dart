import '../entities/study_session_entity.dart';
import '../models/new_card_order_model.dart';
import '../models/study_action_model.dart';
import '../models/study_card_limit_model.dart';
import '../models/study_deck_context_model.dart';
import '../models/study_entry_summary_model.dart';
import '../models/study_schedule_model.dart';
import '../models/study_mode.dart';
import '../models/study_options_model.dart';
import '../models/study_outcome_reason_model.dart';
import '../models/study_session_kind_model.dart';
import '../models/study_session_summary_model.dart';
import '../models/study_turn_model.dart';
import '../models/study_session_status_model.dart';

/// Contract the study feature's use cases depend on.
///
/// Pure Dart: no Flutter, no Drift. AD-01 keeps the planned Spring Boot backend
/// cheap only while that stays true, and the cost of breaking it does not show
/// up until the backend lands.
///
/// **The queue lives behind this contract, not above it.** Every rule it carries
/// — the ordering of BR-23, the comeback of BR-26, the round-building of BR-115
/// and BR-116 — needs the data *as it stands at the moment of writing*. Lifting
/// any of them into a use case would put the check outside the transaction,
/// which is a race between the check and the write: the rule would be in a
/// tidier place and be wrong.
///
/// **What the repository deliberately does not know:** which stages an algorithm
/// runs, or in what order. [openSession] is *given* the sequence (BR-97). The
/// alternative — the repository asking a scheduler — would put algorithm
/// knowledge in the data layer and make a new algorithm a change in two places.
abstract interface class StudyRepository {
  /// The counts the entry point needs, from one statement (AD-13).
  ///
  /// Facts only — how many cards a given mode can take is that mode's policy and
  /// belongs to its handler (AD-18), not to the layer that counted the rows.
  /// Watching rather than reading once: the badge has to fall to zero the moment
  /// the last card is answered.
  Stream<StudyEntrySummaryModel> watchStudyEntry(
    String deckId, {
    required DateTime now,
  });

  /// The root, the algorithm and the generation of one deck, in one read.
  ///
  /// A use case needs all three before it can open a session, and reading them
  /// separately lets a session be opened against a root that was reset between
  /// two of the reads (AD-13).
  Future<StudyDeckContextModel> deckContext(String deckId);

  /// The schedule numbers of one card, for the scheduler to work from.
  ///
  /// Null when the card has no study state — broken data rather than a card
  /// that has never been studied, since BR-09 creates the state with the card.
  Future<StudyScheduleModel?> scheduleOf(String cardId);

  /// Cards of this session with no `pending` row left in any stage.
  ///
  /// **"Every stage it took part in", not "every stage in the sequence"**
  /// (BR-144, BR-114). A card the `fill` stage skipped for want of an `example`
  /// has no row there to be pending, so it finishes with the others — which is
  /// what stops most of the deck from being frozen forever.
  Future<List<String>> cardsFinishedInSession(String sessionId);

  /// The options in force for [rootDeckId], with the deck's override applied
  /// over the app-wide default (BR-147).
  Future<StudyOptionsModel> effectiveOptions(String rootDeckId);

  /// Stores a root deck's override of the study options (BR-147).
  ///
  /// **[deckId] may be any deck in the tree; the write lands on its root.**
  /// Options belong to the root the same way the scheduler does, and resolving
  /// here rather than asking the caller to is what makes invariant 20 —
  /// "no sub-deck carries a `study_config`" — unbreakable by a screen that
  /// happened to be opened one level down.
  ///
  /// Takes a [StudyCardLimit] rather than an `int`: the bounds are the type-s,
  /// so this signature says the value has already been through them.
  Future<void> saveStudyOptions({
    required String deckId,
    required StudyCardLimit cardLimit,
    required NewCardOrder newCardOrder,
  });

  /// Opens a session and builds every stage's queue in one transaction.
  ///
  /// [stageSequence] comes from the algorithm (BR-97): the whole sequence for a
  /// [StudySessionKind.learning] session, a single user-chosen mode for a
  /// [StudySessionKind.reviewing] one (BR-109).
  ///
  /// The card set is chosen once, here, and shared by every stage (BR-113) — the
  /// stages differ only in their shuffle. It never mixes the two sets (BR-142),
  /// never exceeds [StudyOptionsModel.cardLimit] distinct cards (BR-24), and
  /// takes **what is actually available**: eight due cards make an eight-card
  /// session, not a twenty-card one padded with new material.
  ///
  /// Throws a refusal when the set is empty — for a review session that is
  /// BR-145, and it must leave no session row behind (BR-101).
  Future<StudySessionEntity> openSession({
    required String deckId,
    required StudySessionKind kind,
    required List<StudyMode> stageSequence,
    required int cardLimit,
    required NewCardOrder newCardOrder,
    required DateTime now,
  });

  /// The next card to serve, or null when the current stage has nothing left to
  /// serve right now.
  ///
  /// Null does not mean the stage is finished: it also means every remaining
  /// card is waiting out BR-26's three-card gap. [isStageExhausted] is the
  /// question that distinguishes them, and keeping them apart is what stops a
  /// session ending three cards early.
  Future<StudyTurnModel?> nextTurn(String sessionId);

  /// Whether the current stage has no `pending` rows left at all.
  Future<bool> isStageExhausted(String sessionId);

  /// Records one turn, and everything that turn implies, in one transaction
  /// (BR-86).
  ///
  /// In a [StudySessionKind.reviewing] session that means: the history row, the
  /// queue row, the session cursor, and — only on the first turn of the card,
  /// the `scheduled` one — the schedule itself (BR-77, BR-78).
  ///
  /// In a [StudySessionKind.learning] session no schedule moves at all
  /// (BR-141, BR-144). [nextDueAt] and the box/interval arguments are the
  /// scheduler's output and are simply not passed there.
  ///
  /// Refuses, without writing anything, when the session's generation no longer
  /// matches the root's (BR-84) — and marks the session `invalidated` when it
  /// does not.
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
  });

  /// Moves past a card in a stage that grades nothing (BR-111, BR-28).
  ///
  /// **`browse` is the only mode that needs this, and it needs it because it
  /// produces no action at all.** It writes no `study_answers` row — the column
  /// enumeration in the schema cannot even hold `browse` — so without a way to
  /// say "shown, move on" its queue never empties and the session cannot end.
  Future<void> markBrowsed({required String sessionId, required String cardId});

  /// Marks a card as having finished the learning chain (BR-144).
  ///
  /// **Completion is an event, not an answer.** It sets `learned_at`, seeds the
  /// schedule at its lowest rung — box 1, or interval 1 — with [dueAt] at the
  /// start of the next study day, and writes **no** `scheduled` row. Both
  /// columns are set in the same statement, because a card holding one without
  /// the other is what invariants 24 and 28 exist to catch.
  ///
  /// The card finishes when it clears the last stage **it took part in** — a
  /// stage that skipped it for missing data does not count (BR-114). Deriving
  /// this from "reached the last stage in the sequence" instead is what would
  /// have frozen every card without an `example` forever.
  Future<void> completeLearning({
    required String cardId,
    required DateTime learnedAt,
    required DateTime dueAt,
    int? box,
    int? intervalDays,
  });

  /// Moves the session to its next stage and builds that stage's first round.
  Future<void> advanceStage({
    required String sessionId,
    required StudyMode mode,
    required DateTime now,
  });

  /// Builds the next round of the current stage from the cards that failed the
  /// one just finished (BR-115, BR-116).
  ///
  /// Returns false when the failed set is empty, which is what ends a
  /// round-based stage (BR-119). There is no round ceiling — BR-104's three is
  /// `self_assess`'s, and applying it here would end a stage with cards still
  /// unanswered.
  ///
  /// A card that failed at any point in the round belongs to the failed set even
  /// if it was later answered correctly to clear the board (BR-116).
  Future<bool> buildNextRound(String sessionId);

  /// Every card of a session, with content.
  ///
  /// `match` lays out a board and `guess` draws distractors, so both need the
  /// whole set rather than the one card being served (BR-121, BR-153). Read once
  /// when the session opens: the set is fixed for the session's whole life
  /// (BR-102), so re-reading it per turn would be the same answer at a cost.
  Future<List<StudyCardModel>> sessionCards(String sessionId);

  /// Everything a summary screen shows about a finished session, in one read.
  ///
  /// **One statement, not four** (AD-13). Cards finished, cards answered, wrong
  /// turns and the session's own outcome are four questions, and asking them
  /// separately is four snapshots: a summary can then report the counts of a
  /// completed session next to the status of one that failed a moment later.
  ///
  /// [wrongActions] are the algorithm's own lapse actions (BR-20), supplied by
  /// the caller rather than assumed here — `eight_box` says `forgotten` and
  /// `sm2` says `again`, and a query that named one would report a spotless
  /// session on every deck using the other. An empty list counts nothing.
  Future<StudySessionSummaryModel> sessionSummary({
    required String sessionId,
    required List<StudyAction> wrongActions,
  });

  /// Stores what is left of a turn in flight (BR-133).
  ///
  /// **Resume continues a turn, it does not restart one.** A `recall` turn
  /// interrupted at four seconds comes back at four seconds; handing the user a
  /// fresh twenty would give back time they already spent, and hiding an answer
  /// they had already seen would ask them to un-know it.
  ///
  /// Only the turn in flight is written. A turn of the same card in a later
  /// round is a different turn and starts whole.
  Future<void> saveTurnProgress({
    required String sessionId,
    required StudyMode mode,
    required String cardId,
    int? remainingMs,
    bool isRevealed = false,
  });

  /// Invalidates every open session of one root deck (BR-83).
  ///
  /// Reset learning progress moves a whole tree to a new generation, and a
  /// session opened before it can no longer write anything (BR-84). Closing
  /// those sessions here rather than leaving them to fail on the next answer is
  /// what stops the app offering to continue something that cannot continue.
  ///
  /// Returns how many were closed.
  Future<int> invalidateSessionsForRoot({
    required String rootDeckId,
    required DateTime endedAt,
  });

  /// Closes a session with a [status] and [reason] the matrix allows.
  ///
  /// Turns already written stay written, in every ending (BR-86): changing the
  /// status never deletes history.
  Future<void> endSession({
    required String sessionId,
    required StudySessionStatus status,
    required StudySessionEndReason? reason,
    required DateTime endedAt,
  });

  /// Closes any session left `in_progress` by an earlier study day (BR-103).
  ///
  /// `abandoned`/`interrupted`, never `user_exit`: the user did not leave, the
  /// app did. Returns how many were closed.
  Future<int> abandonStaleSessions({required DateTime dayStart});

  /// The session currently open for [deckId], if any.
  Future<StudySessionEntity?> openSessionFor(String deckId);
}
