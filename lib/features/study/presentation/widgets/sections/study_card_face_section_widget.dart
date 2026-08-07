import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/study_action_model.dart';
import '../../../domain/models/study_turn_model.dart';
import '../support/study_labels_widget.dart';

/// The card in front of the user, in the two modes that only show it.
///
/// **`browse` and `self_assess` differ by exactly one thing, so they share a
/// widget** (BR-112): `browse` shows both sides at once and has no action at
/// all, while `self_assess` shows the front, waits for a flip, and only then
/// offers the actions. Two widgets for that would be two copies of the layout
/// and one real difference, and the copies would drift apart the first time the
/// typography changed.
///
/// [actions] comes from the scheduler (BR-30). This widget never decides how
/// many buttons there are — a hardcoded pair is wrong for every `sm2` deck and a
/// hardcoded four is wrong for every `eight_box` one.
class StudyCardFaceSection extends StatelessWidget {
  const StudyCardFaceSection({
    required this.turn,
    required this.actions,
    required this.onAction,
    required this.onContinue,
    this.shouldShowBackImmediately = false,
    this.isLocked = false,
    super.key,
  });

  final StudyTurnModel turn;

  /// Empty for `browse`, which produces no action (BR-111).
  final List<StudyAction> actions;

  final ValueChanged<StudyAction> onAction;

  /// Used by `browse`, which has nothing to grade and only moves on.
  final VoidCallback onContinue;

  /// `browse` sets this; `self_assess` leaves it false and reveals on tap.
  final bool shouldShowBackImmediately;

  /// True while an answer is being written. The card **stays** visible and only
  /// the controls stop responding (BR-25).
  final bool isLocked;

  @override
  Widget build(BuildContext context) => _StudyCardFaceView(
    turn: turn,
    actions: actions,
    onAction: onAction,
    onContinue: onContinue,
    shouldShowBackImmediately: shouldShowBackImmediately,
    isLocked: isLocked,
  );
}

class _StudyCardFaceView extends StatefulWidget {
  const _StudyCardFaceView({
    required this.turn,
    required this.actions,
    required this.onAction,
    required this.onContinue,
    required this.shouldShowBackImmediately,
    required this.isLocked,
  });

  final StudyTurnModel turn;
  final List<StudyAction> actions;
  final ValueChanged<StudyAction> onAction;
  final VoidCallback onContinue;
  final bool shouldShowBackImmediately;
  final bool isLocked;

  @override
  State<_StudyCardFaceView> createState() => _StudyCardFaceViewState();
}

class _StudyCardFaceViewState extends State<_StudyCardFaceView> {
  bool _isRevealed = false;

  @override
  void didUpdateWidget(_StudyCardFaceView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A new card arrives face down. Without this the flip state survives into
    // the next card, and every card after the first shows its answer already.
    if (oldWidget.turn.cardId != widget.turn.cardId) _isRevealed = false;
  }

  bool get _showsBack => widget.shouldShowBackImmediately || _isRevealed;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MxCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(widget.turn.card.front, style: texts.headlineSmall),
                if (_showsBack) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  Text(widget.turn.card.back, style: texts.bodyLarge),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ..._controls(context),
      ],
    );
  }

  List<Widget> _controls(BuildContext context) {
    // `browse` grades nothing, so it gets one way forward and no judgement to
    // make (BR-111). Showing it disabled action buttons would ask a question it
    // is not allowed to record an answer to.
    if (widget.actions.isEmpty) {
      return <Widget>[
        MxActionButton(
          label: context.l10n.studyContinueAction,
          onPressed: widget.isLocked ? null : widget.onContinue,
        ),
      ];
    }

    if (!_showsBack) {
      return <Widget>[
        MxActionButton(
          label: context.l10n.studyRevealAnswer,
          onPressed: widget.isLocked
              ? null
              : () => setState(() => _isRevealed = true),
        ),
      ];
    }

    return <Widget>[
      for (final action in widget.actions) ...<Widget>[
        MxActionButton(
          label: context.studyAction(action),
          onPressed: widget.isLocked ? null : () => widget.onAction(action),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    ];
  }
}
