import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../core/theme/app_elevation.dart';
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

    if (oldWidget.turn.cardId == widget.turn.cardId) return;

    // A new card is a new turn: full limit, and the outcome claim released.
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
        // The prompt on top, the answer area under it, the action at the
        // bottom — the layout `fill` uses too, because the two turns ask the
        // same thing in two ways.
        MxCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            widget.turn.card.front,
            style: context.texts.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _AnswerArea(
          answer: _isRevealed ? widget.turn.card.back : null,
          hiddenLabel: l10n.studyRecallAnswerHidden,
        ),
        const SizedBox(height: AppSpacing.lg),
        // **The second state of this screen, which the design has no image
        // for.** Drawn from BR-129 and BR-130 rather than guessed: the turn has
        // exactly one outcome and it cannot be changed, so there is no button
        // left to offer — and a screen with the answer showing and no control
        // is indistinguishable from one that stopped responding unless it says
        // why.
        if (_isRevealed)
          Text(
            _outcome == RecallOutcome.timedOut
                ? '${l10n.studyRecallTimedOut} · ${l10n.studyRecallLocked}'
                : l10n.studyRecallLocked,
            style: context.texts.bodyMedium?.copyWith(
              color: _outcome == RecallOutcome.timedOut
                  ? semantic.danger
                  : context.colors.onSurfaceVariant,
            ),
          )
        else
          MxActionButton(
            label: l10n.studyRevealAnswer,
            onPressed: () => _claim(RecallOutcome.revealed),
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
class _AnswerArea extends StatelessWidget {
  const _AnswerArea({required this.answer, required this.hiddenLabel});

  final String? answer;
  final String hiddenLabel;

  @override
  Widget build(BuildContext context) {
    final revealed = answer;

    return MxCard(
      elevation: AppElevation.none,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: revealed == null
          ? Text(
              hiddenLabel,
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            )
          : Text(revealed, style: context.texts.titleMedium),
    );
  }
}
