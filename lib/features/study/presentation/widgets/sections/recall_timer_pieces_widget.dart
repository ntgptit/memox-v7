// The two pieces `recall` draws around its clock: the covered answer area and
// the countdown figure. A `part` of `recall_timer_section_widget.dart` so they
// keep access to the library's private members — the split exists to satisfy
// the file-size guard, not to change anything about how they are used.
part of 'recall_timer_section_widget.dart';

/// The panel the answer sits behind, and then in.
///
/// It carries a label while it is covered: an empty box is nothing at all to a
/// screen reader, and "there is an answer here and it is hidden" is a fact about
/// the turn rather than decoration.
///
/// **One step down from the prompt, and flat** (§8.10). Two raised cards read as
/// two prompts; the step is what says one of them is waiting to be filled. No
/// shadow either — a shadow under a card that is already inside a shadowed one
/// reads as a rendering fault rather than as depth.
class _AnswerArea extends StatelessWidget {
  const _AnswerArea({required this.answer, required this.hiddenLabel});

  final String? answer;
  final String hiddenLabel;

  @override
  Widget build(BuildContext context) {
    final revealed = answer;

    return MxCard(
      elevation: AppElevation.none,
      radius: AppRadius.xl,
      color: context.colors.surfaceContainerLow,
      child: Center(
        child: revealed == null
            ? _HiddenBar(label: hiddenLabel)
            : Text(
                revealed,
                style: context.texts.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}

/// What stands in for the answer while it is covered.
///
/// **A bar, not a sentence.** The panel used to write "the answer is hidden" in
/// the place the answer will appear — a line of text a learner reads instead of
/// recalling. A blurred bar is the same fact with nothing to read, and the
/// sentence survives where it was always doing the work: in `Semantics`.
class _HiddenBar extends StatelessWidget {
  const _HiddenBar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: ImageFiltered(
      // Blur rather than a lower opacity: a faint bar reads as a control that
      // has been switched off, a soft one reads as something not yet in focus.
      imageFilter: ImageFilter.blur(
        sigmaX: AppRecallAnswer.hiddenBlur,
        sigmaY: AppRecallAnswer.hiddenBlur,
      ),
      child: SizedBox(
        width: AppRecallAnswer.hiddenBarWidth,
        height: AppRecallAnswer.hiddenBarHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            // **Drawn from `borderControl`, not from a surface step.** A step
            // between two neighbouring surfaces is by construction a small one:
            // this bar measured 1.09:1 against the panel in light and 1.16:1 in
            // dark, which is the one graphical object on the screen carrying
            // "there is an answer here and it is hidden" — exactly what WCAG
            // 1.4.11 asks 3:1 of. The border token is the project's 3:1 value
            // and already the right hue.
            //
            // The token itself, not a blend of it: at 0.9 the bar measured
            // 2.75:1 against the panel because the blur eats the peak before
            // the alpha does. Solid either way — `color_source_rules_test` R7
            // fails a fill that composites at paint time, and this one does not.
            color: context.semanticColors.borderControl,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    ),
  );
}

/// The placeholder’s own numbers.
abstract final class AppRecallAnswer {
  /// Wide enough to read as a line of text that is coming, narrow enough not to
  /// read as an input field waiting to be typed in.
  static const double hiddenBarWidth = 140;
  static const double hiddenBarHeight = 14;

  /// Soft, not gone. Enough that the eye stops trying to resolve it.
  static const double hiddenBlur = 2;
}

/// What the two-card study screens agree on.
///
/// `recall` and `fill` ask the same thing in two directions, so they share a
/// skeleton: a prompt above, the space for an answer below, both `Expanded` and
/// both floored here. A screen that let one card shrink past this stopped being
/// a pair and started being a heading over a box.
abstract final class AppStudyPair {
  static const double cardMinHeight = 160;

  /// How wide one action in the row under the cards may get.
  ///
  /// Two buttons stretched across a phone read as a toolbar; capped and centred
  /// they read as a choice. One button on its own hugs its label instead.
  static const double ctaMaxWidth = 160;
}
