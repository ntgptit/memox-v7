import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/study_answer_commit_model.dart';
import '../../../domain/models/recall_mode.dart';
import '../../../domain/models/study_turn_model.dart';
import '../../states/recall_phase_state.dart';

part 'recall_timer_pieces_widget.dart';

/// One card, twenty seconds, and **one** answer — given by the learner, not by
/// the act of looking (BR-128 … BR-133).
///
/// **Revealing the back is not an answer, and it used to be.** *Show answer*
/// wrote the scheduler's *correct* action and pulled the next card: a learner
/// who gave up at four seconds had the card promoted a box for giving up, and
/// the screen never asked them anything. 8-box needs one bit of evidence per
/// turn and only the learner has it, so the reveal now opens a question —
/// *Forgot* or *Remembered* — and that is what gets written.
///
/// **The clock counts interactive time.** It stops when the app leaves the
/// foreground and resumes when it comes back, so a phone call does not fail a
/// card. It also starts when this widget is built with content already in hand,
/// which is what keeps load time out of the count.
///
/// **Exactly one outcome per turn** (BR-129). A tap and the final tick can land
/// in the same instant; [RecallPhase] is the claim, it moves one way only, and
/// every transition below checks the phase it is leaving. Letting both through
/// writes two turns for one question; letting neither through hangs the session.
///
/// **The two endings are not the same shape, and that is deliberate.** An
/// assessment the learner gave advances the moment it commits — they have
/// already read the back, so a held verdict would be the app pausing on
/// something they are done with. A timeout has to be *read*: the card was lost
/// to a clock, the back is new text, and there is nothing to rush them past it
/// for. So the timeout ends at a *Next* the learner presses, and
/// `studyModeFeedback(recall)` carries no duration for either.
class RecallTimerSectionWidget extends StatefulWidget {
  const RecallTimerSectionWidget({
    required this.turn,
    required this.onOutcome,
    this.onFeedbackShown,
    this.initialRemaining,
    this.onRemainingChanged,
    this.onSuspended,
    this.onResolved,
    this.isLocked = false,
    super.key,
  });

  final StudyTurnModel turn;

  /// Writes the outcome and hands back what the transaction did (BR-157).
  ///
  /// Called at most once per turn, and never for a reveal.
  final Future<StudyAnswerCommitModel?> Function(RecallOutcome outcome)
  onOutcome;

  /// Called once the turn is done being looked at, and completes when the
  /// session has moved on (BR-158).
  ///
  /// **For `recall` this is the *end* of the reading, not the start of it.**
  /// Every other mode says "my verdict is now on screen, hold it for the
  /// budget"; here there is no budget to hold, because the two endings time
  /// themselves — an assessment is done being read before it is even given, and
  /// a timeout is done when the learner presses *Next*.
  final Future<void> Function({required bool isCorrect})? onFeedbackShown;

  /// What was left of a turn interrupted earlier (BR-133).
  ///
  /// Null starts a full turn. A turn of the same card in a **later round** is a
  /// different turn and passes null, which is why this is an argument rather
  /// than something read off the card.
  final Duration? initialRemaining;

  /// Reports what is left on every tick, so the frame can draw the countdown.
  ///
  /// **Display only.** It fires ten times a second; persisting on it would be
  /// ten writes a second for a number nobody reads until the app comes back.
  final ValueChanged<Duration>? onRemainingChanged;

  /// Fires once, when the app leaves the foreground with this turn still
  /// unanswered.
  ///
  /// **This is the moment BR-133 is about**, and the only one: the clock stops
  /// (BR-128), so what is left has to be written down or the turn restarts at
  /// twenty seconds the next time it is served. `isRevealed` is no longer a
  /// constant with a hopeful comment attached — a turn suspended between the
  /// reveal and the assessment is a real state now, and resuming it has to put
  /// the back back on screen rather than start the clock again.
  final void Function({required Duration remaining, required bool isRevealed})?
  onSuspended;

  /// Fired once, when the turn stops asking the learner to recall and starts
  /// showing them the back (§8.11).
  ///
  /// **The frame owns the hint line, and only this widget knows the card is
  /// uncovered.** Reported from the handler rather than from `build` — a parent
  /// `setState` during a build is the one way this plumbing can go wrong.
  final VoidCallback? onResolved;

  /// True while the session is writing or fetching: the card stays on screen
  /// and its controls stop responding (BR-25, BR-158).
  final bool isLocked;

  @override
  State<RecallTimerSectionWidget> createState() =>
      _RecallTimerSectionWidgetState();
}

class _RecallTimerSectionWidgetState extends State<RecallTimerSectionWidget>
    with WidgetsBindingObserver {
  static const Duration _tick = Duration(milliseconds: 100);
  static const RecallModeHandler _handler = RecallModeHandler();

  late Duration _remaining;
  late RecallPhase _phase;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restart();
  }

  @override
  void didUpdateWidget(RecallTimerSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // **The card *and* the round** — see `StudyTurnModel.isSameTurnAs`. A recall
    // turn that runs out of time is enrolled into the next round, which serves
    // the same `cardId`; comparing ids alone kept the phase claimed and drew a
    // settled turn over a live question, with no way forward. It only appeared
    // once a turn actually timed out, which is why the integration suite found
    // it on a slow device and never on a fast one.
    if (oldWidget.turn.isSameTurnAs(widget.turn)) return;

    _restart();
  }

  /// Takes the turn as it stands: a full limit, or whatever was left of it.
  ///
  /// **Where the turn resumes is a fact about the queue row, not a default.**
  /// `isRevealed` with time still on the clock is a learner who pressed *Show
  /// answer* and was interrupted before saying which it was; giving them a
  /// running clock and a covered card back would ask them to un-know the answer
  /// (BR-133).
  void _restart() {
    _remaining = widget.initialRemaining ?? kRecallTurnLimit;
    _phase = _phaseFor(_remaining);
    _start();
  }

  RecallPhase _phaseFor(Duration remaining) {
    if (!widget.turn.item.isRevealed) return RecallPhase.countdownRunning;

    // Revealed with the clock spent is a turn whose timeout was already
    // written: it is being re-read, not re-answered, so it must not submit a
    // second time (BR-129).
    return _handler.didTimeOut(elapsed: kRecallTurnLimit - remaining)
        ? RecallPhase.timedOutReview
        : RecallPhase.selfAssessment;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // BR-128: interactive time only. Without this, twenty seconds of a phone
    // call is twenty seconds of failing a card the user never saw.
    if (state == AppLifecycleState.resumed) {
      _start();

      return;
    }

    _stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  /// Runs the clock, and **only** for the one phase that has a clock.
  void _start() {
    _timer?.cancel();
    _timer = null;
    if (_phase != RecallPhase.countdownRunning) return;

    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    widget.onRemainingChanged?.call(_remaining);

    // A turn with a write behind it has nothing to resume: the row it would be
    // saved against is no longer pending, and BR-85 has ended the session if
    // the write failed.
    if (!_phase.isUnanswered) return;

    widget.onSuspended?.call(
      remaining: _remaining,
      isRevealed: _phase == RecallPhase.selfAssessment,
    );
  }

  void _onTick() {
    // A timer that fires once more after the phase was claimed is not an event:
    // `Timer.periodic` can deliver a tick already queued when it was cancelled.
    if (_phase != RecallPhase.countdownRunning) return;

    final elapsed = kRecallTurnLimit - _remaining + _tick;

    setState(() => _remaining = _handler.remainingAfter(elapsed));
    // Reported on every tick, not only when the clock stops: the frame draws
    // the countdown in its top bar (§7.3), and a value that only arrives at the
    // end is a bar that shows twenty seconds for twenty seconds.
    widget.onRemainingChanged?.call(_remaining);

    if (!_handler.didTimeOut(elapsed: elapsed)) return;

    _timeOut();
  }

  /// Uncovers the back. **Writes nothing** (BR-159).
  ///
  /// The second guard is the race BR-129 names: a tap handled in the same frame
  /// the clock reaches zero. The mark is inclusive on the timeout side, so at
  /// exactly zero the timeout wins and this returns without stopping anything —
  /// the tick that is about to run claims the turn.
  void _reveal() {
    if (_phase != RecallPhase.countdownRunning) return;
    if (_handler.didTimeOut(elapsed: kRecallTurnLimit - _remaining)) return;

    _timer?.cancel();
    _timer = null;
    setState(() => _phase = RecallPhase.selfAssessment);
    widget.onResolved?.call();
  }

  /// The learner's own verdict, which is the only evidence this mode produces.
  void _assess(RecallOutcome outcome) {
    if (_phase != RecallPhase.selfAssessment) return;

    setState(() => _phase = RecallPhase.submittingAssessment);
    unawaited(_write(outcome));
  }

  void _timeOut() {
    if (_phase != RecallPhase.countdownRunning) return;

    _timer?.cancel();
    _timer = null;
    setState(() => _phase = RecallPhase.timedOutSubmitting);
    unawaited(_write(RecallOutcome.timedOut));
  }

  /// Writes the outcome, then shows what it was worth — in that order (BR-157).
  ///
  /// **A refused write puts the turn back where it can be answered, and the two
  /// endings put it back in different places.** An assessment returns to the
  /// choice, because the learner still has one to make. A timeout does not
  /// (BR-130): the clock is spent, and a screen that offered *Remembered* after
  /// a failed timeout would be turning a missed card into a correct one because
  /// the database was busy.
  Future<void> _write(RecallOutcome outcome) async {
    final commit = await widget.onOutcome(outcome);
    if (!mounted) return;

    if (commit == null) {
      setState(
        () => _phase = outcome == RecallOutcome.timedOut
            ? RecallPhase.timedOutUnrecorded
            : RecallPhase.selfAssessment,
      );

      return;
    }

    if (outcome == RecallOutcome.timedOut) {
      setState(() => _phase = RecallPhase.timedOutReview);
      widget.onResolved?.call();

      return;
    }

    setState(() => _phase = RecallPhase.advancing);
    await widget.onFeedbackShown?.call(isCorrect: outcome.isCorrect);
  }

  /// Leaves a turn the clock already settled. **No write** — the answer was
  /// recorded before this button existed.
  void _next() {
    if (_phase != RecallPhase.timedOutReview) return;

    setState(() => _phase = RecallPhase.advancing);
    unawaited(
      widget.onFeedbackShown?.call(isCorrect: false) ?? Future<void>.value(),
    );
  }

  /// One more attempt at the same wrong answer, and no other.
  void _retryTimeOut() {
    if (_phase != RecallPhase.timedOutUnrecorded) return;

    setState(() => _phase = RecallPhase.timedOutSubmitting);
    unawaited(_write(RecallOutcome.timedOut));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // **Two cards of equal weight, and the ratio is the layout** (§8.10).
        // The prompt and the space where the answer will be are the same size
        // because they are the same question seen twice — sizing the prompt to
        // its text made the answer area whatever was left, which is a different
        // shape on every card.
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppStudyPair.cardMinHeight,
            ),
            child: MxCard(
              elevation: AppElevation.raised,
              radius: AppRadius.xl,
              child: Center(
                child: Text(
                  widget.turn.card.front,
                  style: context.textStyles.cardPrompt,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppStudyPair.cardMinHeight,
            ),
            child: _AnswerArea(
              answer: _phase.isBackVisible ? widget.turn.card.back : null,
              hiddenLabel: l10n.studyRecallAnswerHidden,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _RecallActionArea(
          phase: _phase,
          isLocked: widget.isLocked,
          onReveal: _reveal,
          onAssess: _assess,
          onNext: _next,
          onRetry: _retryTimeOut,
        ),
      ],
    );
  }
}
