import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import 'recall_timer_section_widget.dart';
import '../../../domain/models/study_answer_commit_model.dart';
import '../../../domain/models/fill_mode.dart';
import '../../../domain/models/study_turn_model.dart';

part 'fill_answer_pieces_widget.dart';

/// Read the meaning, type the term (BR-134 … BR-138).
///
/// **The prompt is the card's back and the answer is its front**, and that is
/// the mode rather than a layout choice: `front` holds the Korean term and
/// `back` holds the English/Vietnamese gloss (BR-08). `fill` shows the gloss and
/// asks for the term, so the string an answer is graded against is
/// `card.frontFolded`. It ran the other way round for as long as the prompt was
/// the example sentence, which marked a learner typing the Korean word wrong and
/// a learner echoing the gloss right.
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
    this.onFeedbackShown,
    this.isLocked = false,
    super.key,
  });

  final StudyTurnModel turn;

  /// Called with the outcome only. The typed string is not a parameter, and
  /// that is the design.
  /// Writes the outcome and hands back what the transaction did (BR-157).
  final Future<StudyAnswerCommitModel?> Function(FillOutcome) onGraded;

  /// Called once the verdict is on screen; completes when the session has moved
  /// on (BR-158).
  final Future<void> Function({required bool isCorrect})? onFeedbackShown;

  final bool isLocked;

  @override
  State<FillAnswerSectionWidget> createState() =>
      _FillAnswerSectionWidgetState();
}

class _FillAnswerSectionWidgetState extends State<FillAnswerSectionWidget> {
  static const FillModeHandler _handler = FillModeHandler();

  final TextEditingController _input = TextEditingController();

  /// Owned here, so the card below can be focused from anywhere inside it and
  /// so the next turn can pick the keyboard back up.
  final FocusNode _focus = FocusNode();

  bool _hasUsedHint = false;
  bool _isGraded = false;
  bool? _wasCorrect;

  /// Whether the learner was still in the field when the turn was submitted.
  ///
  /// **`fill` is the one mode that is answered by typing, several cards in a
  /// row.** The field unmounts when the verdict is drawn, so the focus is gone
  /// by the time the next card arrives, and a learner who was mid-flow has to
  /// reach for the card again on every turn. This remembers the one fact that
  /// decides whether taking the keyboard back is help or an ambush: somebody who
  /// dismissed the keyboard themselves before checking is not asking for it
  /// again (§6).
  bool _wasTypingOnSubmit = false;

  @override
  void didUpdateWidget(FillAnswerSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // The round too, not the id alone: a card answered wrongly comes back in
    // the next round with the same id, and a field still holding the last
    // attempt is a turn the user cannot start clean (`isSameTurnAs`).
    if (oldWidget.turn.isSameTurnAs(widget.turn)) return;

    final shouldResumeTyping = _wasTypingOnSubmit;

    // A new card starts clean: empty field, hint unused, gradable again.
    _input.clear();
    _hasUsedHint = false;
    _isGraded = false;
    _isSubmitting = false;
    _wasCorrect = null;
    _wasTypingOnSubmit = false;

    if (!shouldResumeTyping) return;

    // **After the frame that builds the new field, not after a delay.** The
    // field for this turn does not exist yet — `didUpdateWidget` runs before the
    // rebuild — so a focus request now lands on a node with no editable
    // attached. A guessed duration would work on the machine it was measured on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// The submission being written, before there is anything to show for it.
  ///
  /// **Separate from [_isGraded], which is what paints the verdict** (BR-157).
  /// They were one field, so Check turned the field green on the tap and left
  /// it green when the write was refused.
  bool _isSubmitting = false;

  /// Whether there is an answer to submit at all (BR-137).
  ///
  /// Read by the button and by [_submit], so a disabled Check and a refused
  /// submit cannot disagree about what "empty" means.
  bool _hasAnswer(String value) => value.trim().isNotEmpty;

  void _submit() {
    if (widget.isLocked || _isGraded || _isSubmitting) return;

    final outcome = _handler.grade(
      input: _input.text,
      // The **front**: the Korean term is the answer, the meaning above is the
      // question (BR-134).
      frontFolded: widget.turn.card.frontFolded,
      hasUsedHint: _hasUsedHint,
    );

    // Null is an empty answer: no turn, no checkpoint (BR-137). Recording it as
    // wrong would bury a card the user never actually got wrong.
    if (outcome == null) return;

    // Read before the field can be unmounted by the verdict.
    _wasTypingOnSubmit = _focus.hasFocus;
    setState(() => _isSubmitting = true);
    unawaited(_grade(outcome));
  }

  /// Writes the outcome, then shows the verdict — in that order (BR-157).
  ///
  /// A null receipt leaves the field as it was, still typed in and still
  /// submittable: a graded screen the session has no answer for would ask the
  /// user to move on from a turn that never happened. The caret goes back where
  /// it was, too — a retry that needs the card tapped again reads as the screen
  /// having given up.
  Future<void> _grade(FillOutcome outcome) async {
    final commit = await widget.onGraded(outcome);
    if (!mounted) return;

    if (commit == null) {
      setState(() => _isSubmitting = false);
      if (_wasTypingOnSubmit) _focus.requestFocus();

      return;
    }

    setState(() {
      _isSubmitting = false;
      _isGraded = true;
      _wasCorrect = outcome.isCorrect;
    });

    await widget.onFeedbackShown?.call(isCorrect: outcome.isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.turn.card;
    final hint = card.hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // **The same skeleton as `recall`, because it is the same question in
        // the other direction** (§8.10): a prompt above, the answer below, both
        // `Expanded` and both floored at the same height. Two `Expanded` are
        // also what keeps the pair balanced when the keyboard takes half the
        // screen — they shrink together, and the row below stays above it.
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppStudyPair.cardMinHeight,
            ),
            child: _PromptCard(
              meaning: card.back,
              hint: _hasUsedHint ? hint : null,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppStudyPair.cardMinHeight,
            ),
            child: _AnswerCard(
              controller: _input,
              focusNode: _focus,
              term: card.front,
              verdict: _wasCorrect,
              // `readOnly`, never `enabled: false`: disabling drops the focus
              // and greys what the learner just typed, and the content has to
              // survive a refused write intact.
              isReadOnly: widget.isLocked || _isSubmitting,
              onSubmitted: _submit,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        StudyCtaRowWidget(
          children: <Widget>[
            // **The slot stays even once the hint is spent.** Removing it let
            // Check slide into the middle of the row the moment somebody used a
            // hint, which moves the primary action under a finger already on its
            // way down.
            if (hint != null)
              MxActionButton(
                label: context.l10n.studyShowHint,
                variant: MxActionButtonVariant.secondary,
                // Recorded on the turn, and with no effect on the action or the
                // schedule (BR-136).
                onPressed:
                    _hasUsedHint ||
                        _isGraded ||
                        _isSubmitting ||
                        widget.isLocked
                    ? null
                    : () => setState(() => _hasUsedHint = true),
              ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _input,
              builder: (context, value, _) => MxActionButton(
                label: context.l10n.studyFillSubmit,
                // Disabled rather than silently refusing: an empty answer is not
                // a turn (BR-137), and a button that accepts a tap and does
                // nothing is the same screen as one that dropped the write.
                onPressed:
                    widget.isLocked ||
                        _isGraded ||
                        _isSubmitting ||
                        !_hasAnswer(value.text)
                    ? null
                    : _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
