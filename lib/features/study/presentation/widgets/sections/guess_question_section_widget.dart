import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/study_turn_model.dart';
import '../../../domain/models/study_answer_commit_model.dart';
import '../../../domain/models/guess_mode.dart';
import '../items/guess_option_item_widget.dart';
import '../../../../../shared/widgets/mx_section_label.dart';

/// One term and five meanings (BR-121).
///
/// **The widget never assembles the question.** Which five options appear, and
/// that no two of them mean the same thing, is the handler's rule (BR-123) — a
/// screen that picked its own distractors would be a second place the rule
/// lives, and the two would disagree.
///
/// **A choice is reported by identity, never by its text** (BR-125). Two cards
/// can display the same string; comparing text grades whichever matched first.
/// A row therefore carries no seat letter at all — see
/// `guess_option_item_widget.dart` for why the handout's A–E circles are gone.
///
/// **After an answer the question stays on screen and stops taking input**
/// (BR-126). The right option is marked right whether or not it was picked — a
/// screen that only marks your choice leaves you knowing you were wrong and not
/// what was right.
class GuessQuestionSectionWidget extends StatefulWidget {
  const GuessQuestionSectionWidget({
    required this.question,
    required this.turn,
    required this.onChosen,
    this.onFeedbackShown,
    this.onResolved,
    this.isLocked = false,
    super.key,
  });

  final GuessQuestion question;

  /// The turn this question belongs to, and the only sound thing to reset on.
  ///
  /// **A card id does not identify a turn.** A card answered wrongly comes back
  /// in the next round (BR-116), and `question.term.id` is then the same string
  /// it was — so the guard survived, the chosen row stayed marked, and the
  /// question could not be answered a second time at all. `isSameTurnAs`
  /// compares the round as well, which is what makes two visits to one card two
  /// different questions.
  final StudyTurnModel turn;

  /// Writes the answer and hands back what the transaction did (BR-157).
  final Future<StudyAnswerCommitModel?> Function(GuessOption) onChosen;

  /// Called once the graded rows are on screen; completes when the session has
  /// moved on (BR-158).
  final Future<void> Function({required bool isCorrect})? onFeedbackShown;

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

    // **The turn, not the card.** A card answered wrongly comes back next round
    // with the same id, so comparing ids let the previous visit's verdict — and
    // its answered-already guard — carry straight over into a question that had
    // not been asked yet. Comparing the turn means a rebuild inside one question
    // resets nothing and a new round resets everything.
    if (!oldWidget.turn.isSameTurnAs(widget.turn)) {
      _chosenCardId = null;
      _isSubmitting = false;
    }
  }

  /// The tap being written, before there is anything to show for it.
  ///
  /// **Separate from [_chosenCardId], which is what paints the verdict.** They
  /// were one field, so the green row appeared on the tap and stayed there even
  /// when the write was refused — BR-157 exists for exactly that. This one only
  /// closes the question to further taps.
  bool _isSubmitting = false;

  bool get _canChoose =>
      !widget.isLocked && !_isSubmitting && _chosenCardId == null;

  void _choose(GuessOption option) {
    if (!_canChoose) return;

    setState(() => _isSubmitting = true);
    unawaited(_grade(option));
  }

  /// Writes the choice, then shows what it was worth — in that order (BR-157).
  ///
  /// A null receipt is a write that did not happen, so the question goes back to
  /// accepting a tap: refusing one *and* showing nothing would leave a screen
  /// that has stopped responding for no stated reason.
  Future<void> _grade(GuessOption option) async {
    final commit = await widget.onChosen(option);
    if (!mounted) return;

    if (commit == null) {
      setState(() => _isSubmitting = false);

      return;
    }

    setState(() {
      _isSubmitting = false;
      _chosenCardId = option.cardId;
    });
    widget.onResolved?.call();

    await widget.onFeedbackShown?.call(
      isCorrect: widget.question.isCorrect(option),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _body);

  /// The band split, decided once from the height the screen actually has.
  ///
  /// **Neither half is `Expanded` any more, and that is the whole fix.** Two
  /// equal flex children split the body down the middle, so capping the card at
  /// 320 left the rest of its half as a band of nothing between the question and
  /// the answers — the card got smaller and the hole got bigger. Measuring
  /// first gives the card exactly its height and hands every remaining point to
  /// the rows.
  ///
  /// The rule: **the card takes its ceiling, unless that would push the rows
  /// off the bottom — then it gives way, down to its own floor.**
  ///
  /// **What the rows need is measured, not assumed.** Sizing the card against a
  /// flat 48pt per row is right until a meaning wraps, and then the card kept
  /// its full 320 while the options ran off into a scroll — the one thing this
  /// screen should not do, because the five options are the question. Asking
  /// each row how tall its text actually is lets the card yield by exactly the
  /// wrap's cost: a three-line meaning takes 40pt off the card instead of 40pt
  /// off the bottom of the list.
  ///
  /// So a phone with short meanings gets a 320pt card over five roomy rows; the
  /// same phone with one three-line meaning gets a smaller card and still no
  /// scroll; and only when even a 180pt card cannot free enough — a very small
  /// screen, or several long meanings at double text — does the band scroll.
  Widget _body(BuildContext context, BoxConstraints constraints) {
    final rows = widget.question.options.length;
    final gaps = AppSpacing.sm * (rows - 1);
    final needed =
        gaps +
        widget.question.options.fold<double>(
          0,
          (total, option) =>
              total +
              AppGuessOption.naturalHeightOf(
                context,
                option.text,
                width: constraints.maxWidth,
              ),
        );
    final cardHeight = (constraints.maxHeight - AppSpacing.md - needed).clamp(
      AppGuessPrompt.cardMinHeight,
      AppGuessPrompt.cardMaxHeight,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: cardHeight,
          child: _PromptCard(term: widget.question.term.front),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(child: LayoutBuilder(builder: _options)),
      ],
    );
  }

  /// The five rows: an equal share of the band each, and more when their text
  /// needs it.
  ///
  /// **A floor, never a ceiling, and that distinction is the whole method.**
  /// Five `Expanded` rows was tried first and it divides the band whatever the
  /// band is — at 320x568 with double text they came out 26pt tall with a 10pt
  /// line inside, a row nobody can read. That failure is worse than the overflow
  /// it replaced, because an overflow paints a warning stripe and a crushed row
  /// paints a normal-looking screen.
  ///
  /// So each row is given `share` as a *minimum*. With room, every row is the
  /// same size and the list runs from the card down to the last row with nothing
  /// left over. When a meaning wraps — and real ones do, "Deep sleep / Giấc ngủ
  /// sâu (Danh từ, …)" is three lines — that row grows past its share and the
  /// band scrolls. Five options that must all be shown (BR-121) are not
  /// something to shrink until they fit, and a meaning the learner is choosing
  /// between is not something to ellipsize.
  Widget _options(BuildContext context, BoxConstraints constraints) {
    final rows = widget.question.options.length;
    final gaps = AppSpacing.sm * (rows - 1);
    final natural = <double>[
      for (final option in widget.question.options)
        AppGuessOption.naturalHeightOf(
          context,
          option.text,
          width: constraints.maxWidth,
        ),
    ];

    // **The surplus is shared, the shortfall is not taken back.** An earlier
    // version handed every row the same `share` of the band, which inflated the
    // four short rows straight back over whatever the long one needed — the
    // card had already given way and the list scrolled anyway. Growing each row
    // by the *same amount* instead keeps the long row long, fills the band
    // exactly, and leaves nothing to scroll.
    final surplus =
        constraints.maxHeight - gaps - natural.fold<double>(0, (a, b) => a + b);
    final bonus = surplus > 0 ? surplus / rows : 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final (index, option)
              in widget.question.options.indexed) ...<Widget>[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: natural[index] + bonus),
              child: GuessOptionItemWidget(
                text: option.text,
                state: _stateOf(option),
                onTap: _canChoose ? () => _choose(option) : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

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
  Widget build(BuildContext context) => MxCard.focal(
    // The focal recipe carries the depth and the corner; the prompt's own
    // rhythm — tighter sides than ends — is this card's content area.
    padding: MxCardPadding.none,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: MxSectionLabel(
              label: context.l10n.studyGuessOverline,
              rung: MxSectionLabelRung.small,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: Text(
              term,
              // The card prompt style — 30 with −0.5 tracking, which is the
              // handout's 32/−0.5 landing on the metric the prompt already owns.
              style: context.textStyles.cardPrompt,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    ),
  );
}

/// What the prompt card decides for itself.
abstract final class AppGuessPrompt {
  /// The card gives way to the options, but only so far.
  ///
  /// Below this the term stops being the focus of the screen and starts being a
  /// caption over a list — which is the opposite of what the mode asks.
  static const double cardMinHeight = 180;

  /// And a ceiling, so the card stops absorbing every point the options leave.
  ///
  /// **320 is `recall` and `fill`'s prompt, rounded to the 8pt step.** Those two
  /// settle their card at 312 on the 393x852 reference because they split the
  /// body into a pair; `guess` has five rows instead of a second card, so it
  /// cannot reach the same number by the same mechanism — it has to be told.
  /// The remaining 8pt is under a third of a line and keeps the value on the
  /// grid every other spacing token sits on.
  static const double cardMaxHeight = 320;
}
