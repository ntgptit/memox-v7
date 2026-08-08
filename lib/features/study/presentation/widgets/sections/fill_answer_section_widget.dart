import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/models/fill_mode.dart';
import '../../../domain/models/study_turn_model.dart';

/// Type the answer, and find out (BR-134 … BR-138).
///
/// **What the user types never leaves this widget** (BR-138, BR-51). The
/// controller receives an outcome, a policy version and a hint flag — not the
/// text. A wrong answer is the most private thing in the app, and the cheapest
/// way to keep it private is never to hand it anywhere.
///
/// Grading is the handler's (BR-134), including the part that matters most here:
/// diacritics count. `cong` is not `công`, and folding them together marks a
/// wrong answer right in the language this was built for.
class FillAnswerSectionWidget extends StatefulWidget {
  const FillAnswerSectionWidget({
    required this.turn,
    required this.onGraded,
    this.isLocked = false,
    super.key,
  });

  final StudyTurnModel turn;

  /// Called with the outcome only. The typed string is not a parameter, and
  /// that is the design.
  final ValueChanged<FillOutcome> onGraded;

  final bool isLocked;

  @override
  State<FillAnswerSectionWidget> createState() =>
      _FillAnswerSectionWidgetState();
}

class _FillAnswerSectionWidgetState extends State<FillAnswerSectionWidget> {
  static const FillModeHandler _handler = FillModeHandler();

  final TextEditingController _input = TextEditingController();
  bool _hasUsedHint = false;
  bool _isGraded = false;
  bool? _wasCorrect;

  @override
  void didUpdateWidget(FillAnswerSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.turn.cardId == widget.turn.cardId) return;

    // A new card starts clean: empty field, hint unused, gradable again.
    _input.clear();
    _hasUsedHint = false;
    _isGraded = false;
    _wasCorrect = null;
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isLocked || _isGraded) return;

    final outcome = _handler.grade(
      input: _input.text,
      backFolded: widget.turn.card.backFolded,
      hasUsedHint: _hasUsedHint,
    );

    // Null is an empty answer: no turn, no checkpoint (BR-137). Recording it as
    // wrong would bury a card the user never actually got wrong.
    if (outcome == null) return;

    setState(() {
      _isGraded = true;
      _wasCorrect = outcome.isCorrect;
    });
    widget.onGraded(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hint = widget.turn.card.hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MxCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.turn.card.example ?? widget.turn.card.front,
                  style: context.texts.headlineSmall,
                ),
                if (_hasUsedHint && hint != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(hint, style: context.texts.bodyMedium),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        MxTextField(
          controller: _input,
          label: l10n.studyFillInputLabel,
          isEnabled: !widget.isLocked && !_isGraded,
          onSubmitted: (_) => _submit(),
        ),
        if (hint != null && !_hasUsedHint)
          MxTextButton(
            label: l10n.studyShowHint,
            // Recorded on the turn, and with no effect on the action or the
            // schedule (BR-136).
            onPressed: widget.isLocked || _isGraded
                ? null
                : () => setState(() => _hasUsedHint = true),
          ),
        const SizedBox(height: AppSpacing.md),
        // **The second state of this screen, which the design has no image
        // for.** Drawn from BR-134 and BR-137 rather than guessed: the verdict
        // is what the turn recorded, the field is closed because a second
        // answer would be a second turn, and a wrong answer is shown the card's
        // own back — never what the learner typed, which is not stored and not
        // echoed (BR-138).
        if (_wasCorrect != null) ...<Widget>[
          Text(
            _wasCorrect! ? l10n.studyFillCorrect : l10n.studyFillIncorrect,
            style: context.texts.titleMedium?.copyWith(
              color: _wasCorrect!
                  ? context.semanticColors.success
                  : context.semanticColors.danger,
            ),
          ),
          if (!_wasCorrect!) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.studyFillTheAnswerWas(widget.turn.card.back),
              style: context.texts.bodyMedium,
            ),
          ],
        ] else
          MxActionButton(
            label: l10n.studyFillSubmit,
            onPressed: widget.isLocked ? null : _submit,
          ),
      ],
    );
  }
}
