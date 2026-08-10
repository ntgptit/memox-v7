import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';

import '../../../../core/time/clock_provider.dart';
import '../../../../core/time/time_zone_provider.dart';
import '../../di/study_repository_provider.dart';
import '../../domain/entities/study_session_entity.dart';
import '../../domain/models/study_answer_commit_model.dart';
import '../../domain/models/study_action_model.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_outcome_reason_model.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../../domain/models/study_session_status_model.dart';
import '../../domain/usecases/end_study_session_use_case.dart';
import '../../domain/usecases/get_next_stage_turn_use_case.dart';
import '../../domain/usecases/mark_browsed_use_case.dart';
import '../../domain/usecases/resume_study_session_use_case.dart';
import '../../domain/usecases/save_turn_progress_use_case.dart';
import '../../domain/usecases/start_study_session_use_case.dart';
import '../../domain/usecases/submit_study_answer_use_case.dart';
import '../states/study_session_state.dart';

part 'study_session_controller.g.dart';

/// Drives one study session.
///
/// **It holds no rule.** Which card comes next, whether a forgotten one comes
/// back, when a round ends — all decided inside a transaction and read back
/// through `nextTurn`. A controller with its own queue would keep a second copy
/// of the rules, and the copy is the one the user sees.
///
/// What it owns is what nothing below it can see: that a person can tap twice
/// before the first write returns, and can leave inside one.
@riverpod
class StudySessionController extends _$StudySessionController {
  @override
  StudySessionState build(String deckId) => const StudySessionState();

  /// Opens a session and pulls the first turn.
  ///
  /// **[shouldResume] picks up the open one instead of opening a new one**
  /// (BR-103). A parameter rather than a second method: everything after the
  /// first line is identical, and a `resume()` would be a second copy of the
  /// failure handling — which is where the two would drift.
  Future<void> start({
    required StudySessionKind kind,
    StudyMode? reviewMode,
    bool shouldResume = false,
  }) async {
    state = state.copyWith(isOpening: true, error: null);

    try {
      final repository = ref.read(studyRepositoryProvider);
      final opened = shouldResume
          ? await ResumeStudySessionUseCase(repository).call(deckId)
          : await StartStudySessionUseCase(repository).call(
              deckId: deckId,
              kind: kind,
              reviewMode: reviewMode,
              now: ref.read(clockProvider)(),
              utcOffset: ref.read(utcOffsetProvider)(),
            );

      if (!ref.mounted) return;
      state = state.copyWith(
        session: opened.session,
        schedulerType: opened.schedulerType,
        actions: opened.actions,
        sessionCards: opened.cards,
        isOpening: false,
      );

      await advance();
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(isOpening: false, error: error);
    }
  }

  /// Which run of the session the writes in flight belong to.
  ///
  /// **`ref.mounted` is not enough.** A write and a read both take long enough
  /// for the user to press ✕ inside them, and the notifier is still mounted
  /// afterwards — so a stale future set a turn or an error on a session that had
  /// ended. Nothing is cancelled: the transaction still commits, because BR-25
  /// wants it to; what changes is whether its result reaches the screen.
  int _epoch = 0;

  /// Whether an operation begun at [epoch] may still write to state.
  bool _isCurrent(int epoch) => ref.mounted && epoch == _epoch;

  /// Records an answer. **Writes only — it fetches nothing.**
  ///
  /// **The double-tap guard is first, and has to be** (BR-25, BR-126): a write
  /// takes long enough for a second tap to land inside it.
  ///
  /// **Writing and advancing used to be one call, and that is what made every
  /// mode's feedback unreachable** — running [advance] the moment a write landed
  /// drew each verdict into a widget already on its way out. The mode decides
  /// how long its answer stays up and calls [advance] itself.
  ///
  /// **The status comes back from the transaction, never from the action.**
  /// `isLapse` is what the user did; what happened to the row is the mode's
  /// [StudyLapsePolicy]. A `completed` receipt clears the card from the round's
  /// progress in memory — which lets `match` answer five pairs on one board
  /// without a read between them — and a `pending` one moves nothing (BR-118).
  /// [cardId] names the card when it is not the one the queue is serving:
  /// `match` alone, whose board lays out the whole round.
  Future<StudyAnswerCommitModel?> submitAnswer(
    StudyAction action, {
    String? cardId,
    StudyOutcomeReason? outcomeReason,
    int? comparisonVersion,
    bool? usedHint,
  }) async {
    if (!state.canAnswer) return null;

    final session = state.session;
    final turn = state.turn;
    if (session == null || turn == null) return null;

    final epoch = _epoch;
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final commit =
          await SubmitStudyAnswerUseCase(
            ref.read(studyRepositoryProvider),
          ).call(
            session: session,
            cardId: cardId ?? turn.cardId,
            mode: session.currentMode,
            action: action,
            now: ref.read(clockProvider)(),
            utcOffset: ref.read(utcOffsetProvider)(),
            outcomeReason: outcomeReason,
            comparisonVersion: comparisonVersion,
            usedHint: usedHint,
          );

      // A session that ended while this was open owns the terminal state. The
      // receipt is still returned — the row *was* written — and the caller's own
      // `mounted` check decides what to draw.
      // **A stale write returns null even though the row is there.** It stays
      // committed (BR-25, BR-86); what a receipt *means* is "carry on with the
      // lifecycle", and a session the user has left has none. Handing it back
      // let the widget draw its verdict and call `advance` over the top.
      if (!_isCurrent(epoch)) return null;

      state = state.copyWith(
        isSubmitting: false,
        turn: commit.isCleared
            ? turn.copyWith(progress: turn.progress.withCleared(commit.cardId))
            : turn,
      );

      return commit;
    } on Object catch (error) {
      await _writeFailed(error, epoch: epoch);

      return null;
    }
  }

  /// Moves to the next turn, board, round or stage — **without taking the
  /// current one off screen first**.
  ///
  /// [minimumVisible] is how long the answer just given has to stay readable.
  /// The read and the wait run together, so a slow fetch costs nothing extra and
  /// a fast one still leaves the verdict up. `Duration.zero` for a mode with
  /// nothing to read.
  ///
  /// **The turn stays in state throughout.** It used to be cleared into a
  /// loading state, so every mode flashed a spinner between two cards differing
  /// by one string. That state is now for one case only: a session with no turn.
  Future<void> advance({Duration minimumVisible = Duration.zero}) async {
    final session = state.session;
    if (session == null ||
        state.isAdvancing ||
        state.isLeaving ||
        state.isFinished) {
      return;
    }

    final epoch = _epoch;
    state = state.copyWith(isAdvancing: true);

    try {
      final read = GetNextStageTurnUseCase(ref.read(studyRepositoryProvider))
          .call(
            session: session,
            now: ref.read(clockProvider)(),
            utcOffset: ref.read(utcOffsetProvider)(),
          );
      final held = minimumVisible == Duration.zero
          ? Future<void>.value()
          : Future<void>.delayed(minimumVisible);
      final (mode, turn) = await read;
      await held;

      // Two awaits, and the user can leave inside either. Nothing below may run
      // for a session that has ended.
      if (!_isCurrent(epoch)) return;

      if (mode == null) {
        state = state.ended;

        return;
      }

      state = state.copyWith(
        session: session.copyWith(currentMode: mode),
        turn: turn,
        isAdvancing: false,
        // **A new card arrives at the front of the trail** (BR-155): the offset
        // counts backwards from the live turn, so one left over would put a card
        // already walked past on screen in place of the one just moved to.
        browseLookBack: 0,
      );
    } on Object catch (error) {
      // A stale failure is not this session's failure: writing it would put an
      // error over a summary the user is already reading.
      if (!_isCurrent(epoch)) return;
      state = state.copyWith(isAdvancing: false, error: error);
    }
  }

  /// What a refused or failed write does — one policy, because two copies drift
  /// and only one ends the session. A [ConflictFailure] is recoverable. Anything
  /// else is BR-85's `persistence_error`, so the session ends rather than taking
  /// answers it cannot store; turns already written stay written (BR-86).
  Future<void> _writeFailed(Object error, {required int epoch}) async {
    if (!_isCurrent(epoch)) return;

    if (error is ConflictFailure) {
      state = state.copyWith(isSubmitting: false, error: error);

      return;
    }

    await _failSession();

    if (!_isCurrent(epoch)) return;
    // **Not `ended`, and the difference is the turn.** BR-85 ends the session,
    // but the card that could not be stored stays on screen: a failed write must
    // not look like a card that was answered and passed.
    state = state.copyWith(isSubmitting: false, isFinished: true, error: error);
  }

  /// Moves `browse` one card along the round, either way (BR-155).
  ///
  /// **One name, because from the user's side it is one thing** — the same
  /// swipe with the sign flipped. Two would put the "am I looking at history?"
  /// test in the screen, and the screen would then decide whether a card gets
  /// marked browsed, which is how one gets answered twice.
  ///
  /// **Going back writes nothing and moves nothing:** the card stays
  /// `completed`, `cursor` stays put, and stepping forward again neither
  /// re-records it nor advances past it twice. `browse` only — every other mode
  /// answers the card on screen, so putting an already-answered card there
  /// would offer to grade what the session has graded (BR-126).
  Future<void> browseStep(StudyBrowseStep step) async {
    // **Every guard, before either branch.** They used to sit under the forward
    // shortcut — the one branch that writes — so a second swipe arriving during
    // the fetch marked the same card browsed twice. `isSubmitting` is cleared
    // before `isAdvancing` is set, so guarding only the first leaves that window
    // wide open (BR-155).
    final session = state.session;
    final turn = state.turn;
    if (session == null ||
        turn == null ||
        session.currentMode != StudyMode.browse ||
        state.isBusy) {
      return;
    }

    if (step == StudyBrowseStep.forward && !state.isLookingBack) {
      return _markBrowsed(session, turn.cardId);
    }

    final next = step == StudyBrowseStep.back
        ? state.browseLookBack + 1
        : state.browseLookBack - 1;

    // Off either end is a step there is nowhere to take. Clamping silently
    // would read as accepted; returning leaves the card where it is, which is
    // what "refused" looks like.
    if (next < 0 || next > state.seenCardIds.length) return;

    state = state.copyWith(browseLookBack: next);
  }

  /// Marks the live `browse` card seen, then fetches the next. Not
  /// `submitAnswer`: `browse` produces no action (BR-111), so going through
  /// there meant inventing one for a grading method to discard.
  Future<void> _markBrowsed(StudySessionEntity session, String cardId) async {
    final epoch = _epoch;
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      await MarkBrowsedUseCase(
        ref.read(studyRepositoryProvider),
      ).call(sessionId: session.id, cardId: cardId);

      if (!_isCurrent(epoch)) return;
      state = state.copyWith(isSubmitting: false);

      await advance();
    } on Object catch (error) {
      await _writeFailed(error, epoch: epoch);
    }
  }

  /// Ends the session as `failed`/`persistence_error` (BR-85), best effort:
  /// the reason it is called is that a write just failed, so this one may fail
  /// too — and letting that propagate would replace the real error with a
  /// second one that tells the user nothing.
  Future<void> _failSession() async {
    final session = state.session;
    if (session == null) return;

    try {
      await EndStudySessionUseCase(ref.read(studyRepositoryProvider)).call(
        sessionId: session.id,
        status: StudySessionStatus.failed,
        reason: StudySessionEndReason.persistenceError,
        now: ref.read(clockProvider)(),
      );
    } on Object catch (_) {
      // Swallowed narrowly: the caller is already reporting a failure, and a
      // failure to record it is not a second thing to show somebody.
    }
  }

  /// Stores what is left of the turn in flight (BR-133).
  ///
  /// **The counterpart of [leave], not another command.** `leave` ends the
  /// session; this suspends a turn so the app being taken away does not cost the
  /// seconds the user had left. The queue row keeps its status and its round.
  Future<void> pause({int? remainingMs, bool isRevealed = false}) async {
    final session = state.session;
    final turn = state.turn;
    if (session == null ||
        turn == null ||
        state.isFinished ||
        state.isLeaving) {
      return;
    }

    await SaveTurnProgressUseCase(ref.read(studyRepositoryProvider)).call(
      sessionId: session.id,
      mode: session.currentMode,
      cardId: turn.cardId,
      remainingMs: remainingMs,
      isRevealed: isRevealed,
    );
  }

  /// Closes the session because the user left (BR-82).
  Future<void> leave() async {
    final session = state.session;
    // Two presses land inside one write — ✕ and the back gesture can be the
    // same press (BR-82) — and each would end the session again.
    if (session == null || state.isFinished || state.isLeaving) return;

    // **It raises a flag rather than clearing two.** The epoch makes operations
    // already in flight stale; what it cannot do is stop a *new* one, because
    // anything starting after this line captures the new epoch and passes the
    // staleness check. That is what `isLeaving` refuses — clearing the busy
    // flags here, as this used to, unlocked the screen for the whole write.
    _epoch += 1;
    state = state.copyWith(isLeaving: true);

    try {
      await EndStudySessionUseCase(ref.read(studyRepositoryProvider)).call(
        sessionId: session.id,
        status: StudySessionStatus.abandoned,
        // `user_exit`, never `interrupted`: the person pressed something.
        // BR-103's other reason belongs to the app being taken away.
        reason: StudySessionEndReason.userExit,
        now: ref.read(clockProvider)(),
      );
    } on Object catch (error) {
      // **Not swallowed.** A session that could not be ended is still running,
      // and a screen locked on `isLeaving` forever is worse than one saying the
      // ✕ did not work: the user can try again, or answer the card in front of
      // them.
      if (!ref.mounted) return;
      state = state.copyWith(isLeaving: false, error: error);

      return;
    }

    if (!ref.mounted) return;
    state = state.ended;
  }
}
