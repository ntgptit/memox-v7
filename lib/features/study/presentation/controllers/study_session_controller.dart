import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';

import '../../../../core/time/clock_provider.dart';
import '../../../../core/time/time_zone_provider.dart';
import '../../di/study_repository_provider.dart';
import '../../domain/models/study_answer_commit_model.dart';
import '../../domain/models/study_action_model.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_outcome_reason_model.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../../domain/models/study_session_status_model.dart';
import '../../domain/usecases/end_study_session_use_case.dart';
import '../../domain/usecases/get_next_stage_turn_use_case.dart';
import '../../domain/usecases/get_session_summary_use_case.dart';
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
/// back, when a round ends — all of that is decided inside a transaction and
/// read back through `nextTurn`. A controller that kept its own queue would be
/// keeping a second copy of the rules, and the copy would be the one the user
/// sees.
///
/// The one thing it does own is what nothing below it can see: that a person can
/// tap twice before the first write returns.
@riverpod
class StudySessionController extends _$StudySessionController {
  @override
  StudySessionState build(String deckId) => const StudySessionState();

  /// Opens a session and pulls the first turn.
  ///
  /// **[shouldResume] picks up the open one instead of opening a new one**
  /// (BR-103). It is a parameter rather than a second method because everything
  /// after the first line is identical — both end with a session, a scheduler
  /// and a card set — and a `resume()` that duplicated the rest is a second copy
  /// of the failure handling, which is where the two would drift.
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

  /// Records an answer. **Writes only — it fetches nothing.**
  ///
  /// **The double-tap guard is the first line, and it has to be.** BR-25 and
  /// BR-126 both say one question yields at most one turn, and a write takes
  /// long enough for a second tap to land inside it. It reads
  /// [StudySessionState.isSubmitting] rather than a private flag so the buttons
  /// and the guard cannot disagree.
  ///
  /// **Writing and advancing used to be one call, and that is what made the
  /// feedback unreachable.** [advance] re-reads the session, the queue, the card
  /// and the progress and swaps the body while it does; running it the moment a
  /// write landed meant every mode's verdict — the green option, the revealed
  /// back, the ticked pair — was drawn into a widget that was already being
  /// unmounted. Now the mode decides how long its answer stays on screen and
  /// calls [advance] itself.
  ///
  /// **The status comes back from the transaction, never from the action.**
  /// `isLapse` is what the user did; what happened to the row is the mode's
  /// [StudyLapsePolicy], and two modes turn the same lapse into different rows.
  /// A `completed` receipt clears the card from the round's progress in memory,
  /// which is what lets `match` answer five pairs on one board without a read
  /// between them. A `pending` one moves nothing (BR-118).
  ///
  /// [cardId] names the card when it is not the one the queue is serving —
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

      if (!ref.mounted) return null;

      state = state.copyWith(
        isSubmitting: false,
        turn: commit.isCleared
            ? turn.copyWith(progress: turn.progress.withCleared(commit.cardId))
            : turn,
      );

      return commit;
    } on Object catch (error) {
      await _writeFailed(error);

      return null;
    }
  }

  /// Moves to the next turn, board, round or stage — **without taking the
  /// current one off screen first**.
  ///
  /// [minimumVisible] is how long the answer the user just gave has to stay
  /// readable. The read and the wait run together, so a slow fetch costs
  /// nothing extra and a fast one still leaves the verdict up: the swap happens
  /// when both are done. `Duration.zero` for a mode with nothing to read, which
  /// is `browse`.
  ///
  /// **The turn stays in state throughout.** It used to be cleared into a
  /// loading state, so every mode flashed a spinner between two cards that
  /// differ by one string — and the mode that suffered most was the one whose
  /// board the user was still looking at. A full-body loading state is now for
  /// one case only: a session that has no turn yet.
  Future<void> advance({Duration minimumVisible = Duration.zero}) async {
    final session = state.session;
    if (session == null || state.isAdvancing) return;

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

      if (!ref.mounted) return;

      if (mode == null) {
        state = state.copyWith(
          isAdvancing: false,
          isFinished: true,
          turn: null,
        );

        return _loadSummary();
      }

      state = state.copyWith(
        session: session.copyWith(currentMode: mode),
        turn: turn,
        isAdvancing: false,
        // **A new card arrives at the front of the trail** (BR-155). The offset
        // counts backwards from the live turn, so one left over from the last
        // card would put a card already walked past on screen in place of the
        // one just moved to — and nothing would say so.
        browseLookBack: 0,
      );
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(isAdvancing: false, error: error);
    }
  }

  /// What a refused or failed write does — one policy, because two copies drift
  /// and only one ends the session. A [ConflictFailure] is recoverable. Anything
  /// else is BR-85's `persistence_error`, so the session ends rather than taking
  /// answers it cannot store; turns already written stay written (BR-86).
  Future<void> _writeFailed(Object error) async {
    if (error is ConflictFailure) {
      if (!ref.mounted) return;
      state = state.copyWith(isSubmitting: false, error: error);

      return;
    }

    await _failSession();

    if (!ref.mounted) return;
    state = state.copyWith(isSubmitting: false, isFinished: true, error: error);
    await _loadSummary();
  }

  /// Moves `browse` one card along the round, either way (BR-155).
  ///
  /// **One name, because from the user's side it is one thing** — the same
  /// swipe with the sign flipped, and the same trail walked in two directions.
  /// Two methods would also put the "am I looking at history?" test in the
  /// screen, and the screen would then be what decides whether a card gets
  /// marked browsed, which is how a card already answered gets answered twice.
  ///
  /// **Going back writes nothing and moves nothing.** The card stays
  /// `completed`, the session's `cursor` stays where it is, and stepping
  /// forward again neither re-records the card nor advances past it a second
  /// time — the queue is not consulted at all, because looking is not
  /// answering. Only stepping forward *from the live turn* touches it.
  ///
  /// `browse` only. Every other mode takes an answer from the card on screen,
  /// so putting an already-answered card there would offer to grade something
  /// the session has already graded (BR-126).
  Future<void> browseStep(StudyBrowseStep step) {
    // **Every guard, before either branch.** They used to sit under the forward
    // shortcut, which is the one branch that writes: a second swipe arriving
    // while the first was still fetching went straight to `answer()` and marked
    // the same card browsed twice. `isAdvancing` covers exactly that window —
    // `submitAnswer` clears `isSubmitting` before `advance` sets `isAdvancing`,
    // so guarding only the first leaves the second wide open (BR-155: stepping
    // forward again writes no second turn and moves no cursor twice).
    if (state.session?.currentMode != StudyMode.browse) {
      return Future<void>.value();
    }
    if (state.isSubmitting || state.isAdvancing) return Future<void>.value();

    if (step == StudyBrowseStep.forward && !state.isLookingBack) {
      return _markBrowsed();
    }

    final next = step == StudyBrowseStep.back
        ? state.browseLookBack + 1
        : state.browseLookBack - 1;

    // Off either end is a step there is nowhere to take. Clamping silently
    // would make the gesture read as accepted; returning leaves the card where
    // it is, which is what "refused" looks like.
    if (next < 0 || next > state.seenCardIds.length) {
      return Future<void>.value();
    }

    state = state.copyWith(browseLookBack: next);

    return Future<void>.value();
  }

  /// Moves past the live `browse` card: mark it seen, then fetch the next.
  ///
  /// **Not [answer], which is where this used to go.** `browse` produces no
  /// action (BR-111), so it had to invent one for a grading method to discard.
  Future<void> _markBrowsed() async {
    final session = state.session;
    final turn = state.turn;
    if (session == null || turn == null) return;

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      await MarkBrowsedUseCase(
        ref.read(studyRepositoryProvider),
      ).call(sessionId: session.id, cardId: turn.cardId);

      if (!ref.mounted) return;
      state = state.copyWith(isSubmitting: false);

      await advance();
    } on Object catch (error) {
      await _writeFailed(error);
    }
  }

  /// Reads what the session came to, once it has ended.
  ///
  /// **Read back rather than accumulated.** A tally would be a second copy of
  /// numbers the database holds, and the two disagree the moment a write is
  /// refused — the tally counts the tap, the
  /// table counts the row. It also reads `status` from the same statement, so a
  /// session that ended by failing cannot be summarised as one that finished.
  ///
  /// A failure here leaves [StudySessionState.summary] null on purpose: the
  /// session has genuinely ended, and refusing to say so because the epilogue
  /// could not be read would be the worse answer.
  Future<void> _loadSummary() async {
    final session = state.session;
    if (session == null) return;

    try {
      final summary = await GetSessionSummaryUseCase(
        ref.read(studyRepositoryProvider),
      ).call(sessionId: session.id, schedulerType: state.schedulerType);

      if (!ref.mounted) return;
      state = state.copyWith(summary: summary);
    } on Object catch (_) {
      // Narrow by intent, not by type: every failure here has the same right
      // answer, which is to show the end of the session without counts.
    }
  }

  /// Ends the session as `failed`/`persistence_error` (BR-85).
  ///
  /// Best effort by necessity: the reason it is being called is that a write
  /// just failed, so this one may fail too. Letting that propagate would replace
  /// the real error with a second one and tell the user nothing.
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
      // Deliberately swallowed, and narrowly: the caller is already reporting a
      // failure, and a failure to record the failure is not a second thing to
      // show somebody.
    }
  }

  /// Stores what is left of the turn in flight (BR-133).
  ///
  /// **The counterpart of [leave], not another command.** `leave` ends the
  /// session; this suspends a turn so the app being taken away does not cost
  /// the user the seconds they had left. Nothing about the domain changes — the
  /// queue row keeps its status and its round.
  Future<void> pause({int? remainingMs, bool isRevealed = false}) async {
    final session = state.session;
    final turn = state.turn;
    if (session == null || turn == null || state.isFinished) return;

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
    if (session == null || state.isFinished) return;

    await EndStudySessionUseCase(ref.read(studyRepositoryProvider)).call(
      sessionId: session.id,
      status: StudySessionStatus.abandoned,
      // `user_exit`, never `interrupted`: the person pressed something.
      // BR-103's other reason belongs to the app being taken away.
      reason: StudySessionEndReason.userExit,
      now: ref.read(clockProvider)(),
    );

    if (!ref.mounted) return;
    state = state.copyWith(isFinished: true, turn: null);
    await _loadSummary();
  }
}
