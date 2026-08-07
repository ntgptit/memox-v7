import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_list_tile.dart';
import '../../../domain/models/guess_mode.dart';

/// One term and five meanings (BR-121).
///
/// **The widget never assembles the question.** Which five options appear, and
/// that no two of them mean the same thing, is the handler's rule (BR-123) — a
/// screen that picked its own distractors would be a second place the rule
/// lives, and the two would disagree.
///
/// **A choice is reported by identity, never by its text** (BR-125). Two cards
/// can display the same string; comparing text grades whichever matched first.
class GuessQuestionSectionWidget extends StatefulWidget {
  const GuessQuestionSectionWidget({
    required this.question,
    required this.onChosen,
    this.isLocked = false,
    super.key,
  });

  final GuessQuestion question;
  final ValueChanged<GuessOption> onChosen;

  /// True while the answer is being written: the question stays visible and the
  /// options stop responding (BR-25).
  final bool isLocked;

  @override
  State<GuessQuestionSectionWidget> createState() =>
      _GuessQuestionSectionWidgetState();
}

class _GuessQuestionSectionWidgetState
    extends State<GuessQuestionSectionWidget> {
  /// The option already taken for this question.
  ///
  /// **One question, at most one turn** (BR-126). Repeated taps are not a
  /// hypothetical: the write takes long enough for a second one to land, and a
  /// second turn would grade the same card twice in the same round.
  String? _chosenCardId;

  @override
  void didUpdateWidget(GuessQuestionSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A new question is a new turn. Without this the guard survives the card
    // change and the next question cannot be answered at all.
    if (oldWidget.question.term.id != widget.question.term.id) {
      _chosenCardId = null;
    }
  }

  bool get _canChoose => !widget.isLocked && _chosenCardId == null;

  void _choose(GuessOption option) {
    if (!_canChoose) return;

    setState(() => _chosenCardId = option.cardId);
    widget.onChosen(option);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      MxCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            widget.question.term.front,
            style: context.texts.headlineSmall,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      for (final option in widget.question.options)
        MxListTile(
          title: option.text,
          onTap: _canChoose ? () => _choose(option) : null,
        ),
    ],
  );
}
