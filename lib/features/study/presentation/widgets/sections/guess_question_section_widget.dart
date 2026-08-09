import 'package:flutter/material.dart';

import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
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
    this.onResolved,
    this.isLocked = false,
    super.key,
  });

  final GuessQuestion question;
  final ValueChanged<GuessOption> onChosen;

  /// Fired once, when the question stops asking and starts telling.
  ///
  /// **The frame owns the hint line, and only this widget knows the answer is
  /// in.** Reported from the tap handler rather than from `build` — a parent
  /// `setState` during a build is the one way this plumbing can go wrong, and
  /// there is no reason to run it from there.
  final VoidCallback? onResolved;

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
    widget.onResolved?.call();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      // **The card takes what the options leave, and never a fixed height.**
      // Five rows are a known height; the prompt is not, because a term can be
      // one word or four. Sizing the card instead and letting the options take
      // the rest is what pushed the fifth option off the screen — the handout
      // calls that out by name.
      Expanded(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppGuessPrompt.cardMinHeight,
          ),
          child: _PromptCard(term: widget.question.term.front),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      for (final (index, option)
          in widget.question.options.indexed) ...<Widget>[
        if (index > 0) const SizedBox(height: AppSpacing.sm),
        GuessOptionItemWidget(
          badge: _badgeFor(index),
          text: option.text,
          state: _stateOf(option),
          onTap: _canChoose ? () => _choose(option) : null,
        ),
      ],
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

/// The prompt: what is being asked, then the thing being asked about.
///
/// **An overline rather than nothing.** A term alone on a card is a word with no
/// question attached, and the mode chip in the top bar says `GUESS` — which
/// names the exercise, not the task. The line is the same shape as the context
/// line above it: small, uppercase, tracked, and quiet.
class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.term});

  final String term;

  @override
  Widget build(BuildContext context) => MxCard(
    // `raised` and a 20 corner: this is the focal surface of the screen, and it
    // is read against five rows that carry neither.
    elevation: AppElevation.raised,
    radius: AppRadius.xl,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xl,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          context.l10n.studyGuessOverline.toUpperCase(),
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
            letterSpacing: AppTypography.sectionLabelTracking,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Flexible(
          child: Text(
            term,
            // `headlineMedium` is documented as *the card prompt* — 30 with
            // −0.5 tracking, which is the handout's 32/−0.5 landing on a step
            // this scale already has.
            style: context.texts.headlineMedium,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
      ],
    ),
  );
}

/// `A`. The badges run from here in display order, and go no further than the
/// five options BR-121 allows.
const int _firstBadgeLetter = 0x41;

/// What the prompt card decides for itself.
abstract final class AppGuessPrompt {
  /// The card gives way to the options, but only so far.
  ///
  /// Below this the term stops being the focus of the screen and starts being a
  /// caption over a list — which is the opposite of what the mode asks.
  static const double cardMinHeight = 180;
}
