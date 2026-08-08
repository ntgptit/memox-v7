import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';

import '../../../../core/time/clock_provider.dart';
import '../../../../core/time/time_zone_provider.dart';
import '../../di/study_repository_provider.dart';
import '../../domain/models/study_action_model.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_outcome_reason_model.dart';
import '../../domain/models/study_scheduler.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../../domain/models/study_session_status_model.dart';
import '../../domain/usecases/advance_study_stage_use_case.dart';
import '../../domain/usecases/end_study_session_use_case.dart';
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
  Future<void> start({
    required StudySessionKind kind,
    StudyMode? reviewMode,
  }) async {
    state = state.copyWith(isOpening: true, error: null);

    final repository = ref.read(studyRepositoryProvider);
    try {
      final session = await StartStudySessionUseCase(repository).call(
        deckId: deckId,
        kind: kind,
        reviewMode: reviewMode,
        now: ref.read(clockProvider)(),
      );

      final context = await repository.deckContext(deckId);
      final actions = schedulerFor(context.schedulerType)?.supportedActions;

      // A guard rather than a fallback: an empty action list means a screen with
      // no way to answer, and showing that is worse than failing to open.
      if (actions == null) {
        throw StateError('Deck has no scheduler this build understands');
      }

      final cards = await repository.sessionCards(session.id);

      if (!ref.mounted) return;
      state = state.copyWith(
        session: session,
        actions: actions,
        schedulerType: context.schedulerType,
        sessionCards: cards,
        isOpening: false,
      );

      await _pullTurn();
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(isOpening: false, error: error);
    }
  }

  /// Records an answer for the card on screen, then pulls the next turn.
  ///
  /// **The double-tap guard is the first line, and it has to be.** BR-25 and
  /// BR-126 both say one question yields at most one turn, and the window is
  /// real: a write takes long enough for a second tap to land inside it. The
  /// check reads [StudySessionState.isSubmitting] rather than a private flag so
  /// the buttons and the guard cannot disagree about whether input is open.
  Future<void> answer(
    StudyAction action, {
    StudyOutcomeReason? outcomeReason,
    int? comparisonVersion,
    bool? usedHint,
  }) async {
    if (!state.canAnswer) return;

    final session = state.session;
    final turn = state.turn;
    if (session == null || turn == null) return;

    state = state.copyWith(isSubmitting: true, error: null);

    final repository = ref.read(studyRepositoryProvider);
    try {
      // `browse` produces no action, so there is nothing to submit — it is
      // shown and moved past (BR-111, BR-28). The schema cannot even hold
      // `browse` as an answer mode, so this is a branch rather than a value.
      if (session.currentMode == StudyMode.browse) {
        await repository.markBrowsed(
          sessionId: session.id,
          cardId: turn.cardId,
        );

        if (!ref.mounted) return;
        state = state.copyWith(isSubmitting: false);

        return _pullTurn();
      }

      await SubmitStudyAnswerUseCase(repository).call(
        session: session,
        cardId: turn.cardId,
        mode: session.currentMode,
        action: action,
        now: ref.read(clockProvider)(),
        utcOffset: ref.read(utcOffsetProvider)(),
        outcomeReason: outcomeReason,
        comparisonVersion: comparisonVersion,
        usedHint: usedHint,
      );

      if (!ref.mounted) return;
      state = state.copyWith(isSubmitting: false);

      await _pullTurn();
    } on ConflictFailure catch (error) {
      // A refusal is recoverable: the card stays on screen and the user can try
      // again. A failed write must not look like a card that was answered and
      // moved past.
      if (!ref.mounted) return;
      state = state.copyWith(isSubmitting: false, error: error);
    } on Object catch (error) {
      // Anything else is a write that did not happen and cannot be retried into
      // working — BR-85's `persistence_error`. The session ends rather than
      // pretending, because a session that keeps taking answers it cannot store
      // is worse than one that stops and says so.
      //
      // Turns already written stay written (BR-86): ending a session never
      // touches `study_answers`.
      await _failSession();

      if (!ref.mounted) return;
      state = state.copyWith(
        isSubmitting: false,
        isFinished: true,
        error: error,
      );
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

    await ref
        .read(studyRepositoryProvider)
        .saveTurnProgress(
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
  }

  /// Reads the next turn, advancing the stage when this one has run dry.
  ///
  /// **A null turn is not the end of the session.** It can also mean every
  /// remaining card is waiting out BR-26's three-card gap, and the stage decides
  /// which of the two it is. Treating null as "finished" ends a session with
  /// cards still unanswered.
  Future<void> _pullTurn() async {
    final session = state.session;
    if (session == null) return;

    state = state.copyWith(isAdvancing: true);

    final repository = ref.read(studyRepositoryProvider);
    try {
      final mode = await AdvanceStudyStageUseCase(repository).call(
        session: session,
        now: ref.read(clockProvider)(),
        utcOffset: ref.read(utcOffsetProvider)(),
      );

      if (!ref.mounted) return;

      if (mode == null) {
        state = state.copyWith(
          isAdvancing: false,
          isFinished: true,
          turn: null,
        );

        return;
      }

      final turn = await repository.nextTurn(session.id);
      if (!ref.mounted) return;

      state = state.copyWith(
        session: session.copyWith(currentMode: mode),
        turn: turn,
        isAdvancing: false,
      );
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(isAdvancing: false, error: error);
    }
  }
}
