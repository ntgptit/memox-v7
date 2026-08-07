import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
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

  /// Reports what is left, so an interrupted turn can be resumed rather than
  /// restarted.
  final ValueChanged<Duration>? onRemainingChanged;

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
  }

  void _onTick() {
    final elapsed = kRecallTurnLimit - _remaining + _tick;

    // The handler decides which side of the mark this is (BR-129), rather than
    // the widget re-deriving `<= zero` and getting the inclusive boundary
    // subtly different from the rule.
    setState(
      () => _remaining = const RecallModeHandler().remainingAfter(elapsed),
    );

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          _outcome == RecallOutcome.timedOut
              ? l10n.studyRecallTimedOut
              : l10n.studyRecallSecondsLeft(_remaining.inSeconds),
          style: context.texts.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        MxCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.turn.card.front,
                  style: context.texts.headlineSmall,
                ),
                // Running out reveals the answer as well, so the user still
                // learns something from the card they just lost (BR-130).
                if (_isRevealed) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  Text(widget.turn.card.back, style: context.texts.bodyLarge),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (!_isRevealed)
          MxActionButton(
            label: l10n.studyRevealAnswer,
            onPressed: () => _claim(RecallOutcome.revealed),
          ),
      ],
    );
  }
}
