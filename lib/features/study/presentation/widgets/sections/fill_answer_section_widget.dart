import 'package:flutter/material.dart';

import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import 'recall_timer_section_widget.dart';
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

    // The round too, not the id alone: a card answered wrongly comes back in
    // the next round with the same id, and a field still holding the last
    // attempt is a turn the user cannot start clean (`isSameTurnAs`).
    if (oldWidget.turn.isSameTurnAs(widget.turn)) return;

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
        // **The same skeleton as `recall`, because it is the same question in
        // the other direction** (§8.10): a prompt above, the space for an answer
        // below, both `Expanded` and both floored at the same height.
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppStudyPair.cardMinHeight,
            ),
            child: MxCard(
              elevation: AppElevation.raised,
              radius: AppRadius.xl,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        widget.turn.card.example ?? widget.turn.card.front,
                        style: context.texts.bodyLarge,
                        textAlign: TextAlign.center,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_hasUsedHint && hint != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        hint,
                        style: context.texts.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
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
            child: MxCard(
              elevation: AppElevation.none,
              radius: AppRadius.xl,
              color: context.colors.surfaceContainerLow,
              child: Center(child: _answerArea(context)),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _CtaRow(
          children: <Widget>[
            if (hint != null && !_hasUsedHint)
              MxActionButton(
                label: l10n.studyShowHint,
                variant: MxActionButtonVariant.secondary,
                // Recorded on the turn, and with no effect on the action or the
                // schedule (BR-136).
                onPressed: widget.isLocked || _isGraded
                    ? null
                    : () => setState(() => _hasUsedHint = true),
              ),
            if (!_isGraded)
              MxActionButton(
                label: l10n.studyFillSubmit,
                onPressed: widget.isLocked ? null : _submit,
              ),
          ],
        ),
      ],
    );
  }

  /// The field, or what the turn recorded once it is graded.
  ///
  /// **The verdict is a line and a block, and the block never holds what the
  /// learner typed.** BR-138 keeps the typed string out of storage and off the
  /// screen, so a wrong answer is shown the card's own back — which is the thing
  /// worth taking away — under its own label. The reference design puts the
  /// learner's attempt in a box of its own beside it; that box would be empty
  /// here, and drawing an empty one to match a picture is how a screen starts
  /// implying it kept something it did not.
  ///
  /// `Try again` and `Mark correct` are still held: each decides what a turn
  /// *writes*, which is a rule this screen does not get to invent (§8.10).
  Widget _answerArea(BuildContext context) {
    final l10n = context.l10n;
    final graded = _wasCorrect;

    if (graded == null) {
      return MxTextField(
        controller: _input,
        label: l10n.studyFillInputLabel,
        isEnabled: !widget.isLocked && !_isGraded,
        onSubmitted: (_) => _submit(),
      );
    }

    final semantic = context.semanticColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          graded ? l10n.studyFillCorrect : l10n.studyFillIncorrect,
          style: context.texts.titleMedium?.copyWith(
            color: graded ? semantic.success : semantic.danger,
          ),
        ),
        // **The block only appears after a wrong turn, and that is a rule, not
        // a layout choice.** It exists to tell somebody what they missed;
        // spelling the answer back to somebody who just typed it reads as a
        // correction of something they got right. A correct turn gets the line
        // and nothing else.
        //
        // The label sits above the block it names, the way the prompt sits
        // above the field.
        if (!graded) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.studyFillAnswerLabel,
            style: context.texts.labelMedium?.copyWith(color: semantic.success),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AnswerBlock(text: widget.turn.card.back, accent: semantic.success),
        ],
      ],
    );
  }
}

/// The card's back, framed in the verdict colour.
///
/// **Blended, never translucent** — `color_source_rules_test` R7 fails a fill
/// that composites at paint time, so the tint is resolved against the surface
/// the block actually sits on.
class _AnswerBlock extends StatelessWidget {
  const _AnswerBlock({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ground = context.colors.surface;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: AppFillAnswer.blockFillAlpha),
          ground,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Color.alphaBlend(
            accent.withValues(alpha: AppFillAnswer.blockOutlineAlpha),
            ground,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.check, size: AppIconSize.sm, color: accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: context.texts.bodyMedium)),
        ],
      ),
    );
  }
}

/// The numbers the graded block decides.
abstract final class AppFillAnswer {
  /// The same pair `guess` uses for an answered row: the fill carries the
  /// verdict quietly and the outline carries it at a strength a hairline needs.
  static const double blockFillAlpha = 0.14;
  static const double blockOutlineAlpha = 0.4;
}

/// The row of actions under the answer.
///
/// Centred and capped rather than stretched: one or two buttons under a pair of
/// cards read as the way on, where a full-width bar reads as the screen floor.
/// Empty when the turn is graded and there is nothing left to offer — the same
/// shape `recall` takes for the same reason (BR-129).
class _CtaRow extends StatelessWidget {
  const _CtaRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (final (index, child) in children.indexed) ...<Widget>[
          if (index > 0) const SizedBox(width: AppSpacing.md),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppStudyPair.ctaMaxWidth,
              ),
              child: child,
            ),
          ),
        ],
      ],
    );
  }
}
