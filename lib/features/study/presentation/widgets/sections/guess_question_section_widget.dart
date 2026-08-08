import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/guess_mode.dart';
import '../items/guess_option_item_widget.dart';

/// One term and five meanings (BR-121).
///
/// **The widget never assembles the question.** Which five options appear, and
/// that no two of them mean the same thing, is the handler's rule (BR-123) — a
/// screen that picked its own distractors would be a second place the rule
/// lives, and the two would disagree.
///
/// **A choice is reported by identity, never by its text** (BR-125). Two cards
/// can display the same string; comparing text grades whichever matched first.
/// The A–E badges are the same rule seen from the other side: they are the
/// display order, rebuilt each shuffle, and nothing reads them back.
///
/// **After an answer the question stays on screen and stops taking input**
/// (BR-126). The right option is marked right whether or not it was picked — a
/// screen that only marks your choice leaves you knowing you were wrong and not
/// what was right.
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
      for (final (index, option) in widget.question.options.indexed)
        GuessOptionItemWidget(
          badge: _badgeFor(index),
          text: option.text,
          state: _stateOf(option),
          onTap: _canChoose ? () => _choose(option) : null,
        ),
    ],
  );

  /// A, B, C… from the row's position.
  ///
  /// Built here rather than stored on the option, because storing it would make
  /// it look like something a turn could be recorded against (BR-125).
  String _badgeFor(int index) => String.fromCharCode(_firstBadgeLetter + index);

  GuessOptionState _stateOf(GuessOption option) {
    final chosen = _chosenCardId;
    if (chosen == null) return GuessOptionState.open;

    if (widget.question.isCorrect(option)) return GuessOptionState.correct;
    if (option.cardId == chosen) return GuessOptionState.chosenWrong;

    return GuessOptionState.dimmed;
  }
}

/// `A`. The badges run from here in display order, and go no further than the
/// five options BR-121 allows.
const int _firstBadgeLetter = 0x41;
