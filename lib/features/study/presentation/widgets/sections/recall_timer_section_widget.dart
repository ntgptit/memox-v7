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
import '../../../domain/models/recall_mode.dart';
import '../../../domain/models/study_turn_model.dart';

/// One card, twenty seconds, one outcome (BR-128 … BR-131).
///
/// **The clock counts interactive time.** It stops when the app leaves the
/// foreground and resumes when it comes back, so a phone call does not fail a
/// card. It also starts when this widget is built with content already in hand,
/// which is what keeps load time out of the count.
///
/// **Exactly one outcome per turn** (BR-129). A tap and the final tick can land
/// in the same instant; `_outcome` is claimed once and whichever arrives first
/// wins. Letting both through writes two turns for one question; letting neither
/// through hangs the session.
class RecallTimerSectionWidget extends StatefulWidget {
  const RecallTimerSectionWidget({
    required this.turn,
    required this.onOutcome,
    this.initialRemaining,
    this.onRemainingChanged,
    this.onSuspended,
    super.key,
  });

  final StudyTurnModel turn;

  /// Called once, with the outcome that was claimed.
  final void Function(RecallOutcome outcome) onOutcome;

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

  /// Fires once, when the app leaves the foreground with this turn still open.
  ///
  /// **This is the moment BR-133 is about**, and the only one: the clock stops
  /// (BR-128), so what is left has to be written down or the turn restarts at
  /// twenty seconds the next time it is served. It carries `isRevealed` as well
  /// — true is unreachable today, because revealing *is* the outcome (BR-129),
  /// but the widget reports what it actually holds rather than a constant, so a
  /// design that ever separates the two needs no second wiring.
  final void Function({required Duration remaining, required bool isRevealed})?
  onSuspended;

  @override
  State<RecallTimerSectionWidget> createState() =>
      _RecallTimerSectionWidgetState();
}

class _RecallTimerSectionWidgetState extends State<RecallTimerSectionWidget>
    with WidgetsBindingObserver {
  static const Duration _tick = Duration(milliseconds: 100);

  late Duration _remaining;
  Timer? _timer;
  RecallOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remaining = widget.initialRemaining ?? kRecallTurnLimit;
    _start();
  }

  @override
  void didUpdateWidget(RecallTimerSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // **The card *and* the round** — see `StudyTurnModel.isSameTurnAs`. A recall
    // turn that runs out of time is enrolled into the next round, which serves
    // the same `cardId`; comparing ids alone kept `_outcome` claimed and drew
    // "this turn is settled" over a live question, with no way forward. It only
    // appeared once a turn actually timed out, which is why the integration
    // suite found it on a slow device and never on a fast one.
    if (oldWidget.turn.isSameTurnAs(widget.turn)) return;

    // A new turn: full limit, and the outcome claim released.
    _outcome = null;
    _remaining = widget.initialRemaining ?? kRecallTurnLimit;
    _start();
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

  void _start() {
    _timer?.cancel();
    if (_outcome != null) return;

    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    widget.onRemainingChanged?.call(_remaining);

    // A turn that already has an outcome has nothing to resume: it was answered
    // the instant it was revealed (BR-129), and the row it would be written
    // against is no longer pending.
    if (_outcome != null) return;

    widget.onSuspended?.call(remaining: _remaining, isRevealed: _isRevealed);
  }

  void _onTick() {
    final elapsed = kRecallTurnLimit - _remaining + _tick;

    // The handler decides which side of the mark this is (BR-129), rather than
    // the widget re-deriving `<= zero` and getting the inclusive boundary
    // subtly different from the rule.
    setState(
      () => _remaining = const RecallModeHandler().remainingAfter(elapsed),
    );
    // Reported on every tick, not only when the clock stops: the frame draws
    // the countdown in its top bar (§7.3), and a value that only arrives at the
    // end is a bar that shows twenty seconds for twenty seconds.
    widget.onRemainingChanged?.call(_remaining);

    if (const RecallModeHandler().outcomeFor(elapsed: elapsed) !=
        RecallOutcome.timedOut) {
      return;
    }

    _claim(RecallOutcome.timedOut);
  }

  /// Takes the single outcome, or does nothing if it is already taken.
  void _claim(RecallOutcome outcome) {
    if (_outcome != null) return;

    _timer?.cancel();
    setState(() => _outcome = outcome);
    widget.onOutcome(outcome);
  }

  bool get _isRevealed => _outcome != null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = context.semanticColors;

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
                  style: context.texts.headlineMedium,
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
              answer: _isRevealed ? widget.turn.card.back : null,
              hiddenLabel: l10n.studyRecallAnswerHidden,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // **The second state of this screen, which the design has no image
        // for.** Drawn from BR-129 and BR-130 rather than guessed: the turn has
        // exactly one outcome and it cannot be changed, so there is no button
        // left to offer — and a screen with the answer showing and no control
        // is indistinguishable from one that stopped responding unless it says
        // why. The handout’s `Forgot` / `Got it` pair is that same ruling seen
        // from the other side, and was refused for the same reason.
        if (_isRevealed)
          Text(
            _outcome == RecallOutcome.timedOut
                ? '${l10n.studyRecallTimedOut} · ${l10n.studyRecallLocked}'
                : l10n.studyRecallLocked,
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium?.copyWith(
              color: _outcome == RecallOutcome.timedOut
                  ? semantic.danger
                  : context.colors.onSurfaceVariant,
            ),
          )
        else
          // Hugs rather than fills: one action centred under two cards reads as
          // the way on, where a full-width bar reads as the screen floor.
          Align(
            child: MxActionButton(
              label: l10n.studyRevealAnswer,
              onPressed: () => _claim(RecallOutcome.revealed),
            ),
          ),
      ],
    );
  }
}

/// The panel the answer sits behind, and then in.
///
/// It carries a label while it is covered: an empty box is nothing at all to a
/// screen reader, and "there is an answer here and it is hidden" is a fact about
/// the turn rather than decoration.
///
/// **One step down from the prompt, and flat** (§8.10). Two raised cards read as
/// two prompts; the step is what says one of them is waiting to be filled. No
/// shadow either — a shadow under a card that is already inside a shadowed one
/// reads as a rendering fault rather than as depth.
class _AnswerArea extends StatelessWidget {
  const _AnswerArea({required this.answer, required this.hiddenLabel});

  final String? answer;
  final String hiddenLabel;

  @override
  Widget build(BuildContext context) {
    final revealed = answer;

    return MxCard(
      elevation: AppElevation.none,
      radius: AppRadius.xl,
      color: context.colors.surfaceContainerLow,
      child: Center(
        child: revealed == null
            ? _HiddenBar(label: hiddenLabel)
            : Text(
                revealed,
                style: context.texts.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}

/// What stands in for the answer while it is covered.
///
/// **A bar, not a sentence.** The panel used to write "the answer is hidden" in
/// the place the answer will appear — a line of text a learner reads instead of
/// recalling. A blurred bar is the same fact with nothing to read, and the
/// sentence survives where it was always doing the work: in `Semantics`.
class _HiddenBar extends StatelessWidget {
  const _HiddenBar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: ImageFiltered(
      // Blur rather than a lower opacity: a faint bar reads as a control that
      // has been switched off, a soft one reads as something not yet in focus.
      imageFilter: ImageFilter.blur(
        sigmaX: AppRecallAnswer.hiddenBlur,
        sigmaY: AppRecallAnswer.hiddenBlur,
      ),
      child: SizedBox(
        width: AppRecallAnswer.hiddenBarWidth,
        height: AppRecallAnswer.hiddenBarHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Blended, never translucent: `color_source_rules_test` R7 fails a
            // fill that composites at paint time.
            color: Color.alphaBlend(
              context.colors.surfaceContainerHigh.withValues(
                alpha: AppRecallAnswer.hiddenBarAlpha,
              ),
              context.colors.surfaceContainerLow,
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    ),
  );
}

/// The placeholder’s own numbers.
abstract final class AppRecallAnswer {
  /// Wide enough to read as a line of text that is coming, narrow enough not to
  /// read as an input field waiting to be typed in.
  static const double hiddenBarWidth = 140;
  static const double hiddenBarHeight = 14;

  /// How much of `surfaceContainerHigh` the bar carries over the card under it.
  static const double hiddenBarAlpha = 0.7;

  /// Soft, not gone. Enough that the eye stops trying to resolve it.
  static const double hiddenBlur = 2;
}

/// What the two-card study screens agree on.
///
/// `recall` and `fill` ask the same thing in two directions, so they share a
/// skeleton: a prompt above, the space for an answer below, both `Expanded` and
/// both floored here. A screen that let one card shrink past this stopped being
/// a pair and started being a heading over a box.
abstract final class AppStudyPair {
  static const double cardMinHeight = 160;

  /// How wide one action in the row under the cards may get.
  ///
  /// Two buttons stretched across a phone read as a toolbar; capped and centred
  /// they read as a choice. One button on its own hugs its label instead.
  static const double ctaMaxWidth = 160;
}
