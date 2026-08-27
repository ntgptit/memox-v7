// The pieces `recall` draws around its clock: the covered answer area, and the
// row of controls that changes with the phase. A `part` of
// `recall_timer_section_widget.dart` so they keep access to the library's
// private members — the split exists to satisfy the file-size guard, not to
// change anything about how they are used.
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

/// The controls under the two cards, which ask a different question in every
/// phase.
///
/// **One row, one height, whatever it is asking.** The phase changes what the
/// learner is offered — reveal, then a verdict, then a way out of a turn the
/// clock took — and a screen that resized between those three would move the
/// answer they are reading. So every branch below is one row of buttons at the
/// same height, and only the line above it comes and goes.
class _RecallActionArea extends StatelessWidget {
  const _RecallActionArea({
    required this.phase,
    required this.isLocked,
    required this.onReveal,
    required this.onAssess,
    required this.onNext,
    required this.onRetry,
  });

  final RecallPhase phase;
  final bool isLocked;
  final VoidCallback onReveal;
  final ValueChanged<RecallOutcome> onAssess;
  final VoidCallback onNext;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = _messageOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (message != null) ...<Widget>[
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium!.inked(context, AppInk.danger),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _controls(context),
      ],
    );
  }

  /// What the screen says about a turn the clock decided.
  ///
  /// **Nothing at all until the row exists** (BR-157). The verdict is drawn from
  /// the write, not from the tick that started it: "counted as forgotten"
  /// printed while the transaction is still open is a claim the session cannot
  /// back up, and a refused write would leave it standing.
  String? _messageOf(BuildContext context) => switch (phase) {
    RecallPhase.timedOutReview =>
      '${context.l10n.studyRecallTimedOut} · '
          '${context.l10n.studyRecallCountedForgotten}',
    RecallPhase.timedOutUnrecorded => context.l10n.studyRecallTimedOutUnsaved,
    RecallPhase.countdownRunning ||
    RecallPhase.selfAssessment ||
    RecallPhase.submittingAssessment ||
    RecallPhase.timedOutSubmitting ||
    RecallPhase.advancing => null,
  };

  Widget _controls(BuildContext context) {
    final l10n = context.l10n;

    return switch (phase) {
      // Hugs rather than fills: one action centred under two cards reads as the
      // way on, where a full-width bar reads as the screen floor.
      RecallPhase.countdownRunning => Align(
        child: MxActionButton(
          label: l10n.studyRevealAnswer,
          onPressed: isLocked ? null : onReveal,
        ),
      ),

      // **Forgot on the left, Remembered on the right.** The one that admits a
      // miss is the secondary and sits where a Cancel sits; they are not a pair
      // of equals dressed the same, because only one of them is what the learner
      // presses when the card worked.
      RecallPhase.selfAssessment ||
      RecallPhase.submittingAssessment => StudyCtaRowWidget(
        children: <Widget>[
          MxActionButton(
            label: l10n.studyActionForgotten,
            variant: MxActionButtonVariant.secondary,
            onPressed: _canAssess
                ? () => onAssess(RecallOutcome.forgotten)
                : null,
          ),
          MxActionButton(
            label: l10n.studyActionRemembered,
            onPressed: _canAssess
                ? () => onAssess(RecallOutcome.remembered)
                : null,
          ),
        ],
      ),

      RecallPhase.timedOutReview => Align(
        child: MxActionButton(
          label: l10n.studyContinueAction,
          onPressed: isLocked ? null : onNext,
        ),
      ),

      RecallPhase.timedOutUnrecorded => Align(
        child: MxActionButton(
          label: l10n.retryAction,
          onPressed: isLocked ? null : onRetry,
        ),
      ),

      // The write is in flight, or the next turn is being fetched. Same shape,
      // no target: the card stays on screen (BR-158) and stops answering.
      //
      // **Disabled, not spinning.** The transaction is a local SQLite write and
      // the fetch is one query; a spinner that exists for eight milliseconds is
      // a flicker rather than information, and an indefinite one is a widget
      // that never settles.
      RecallPhase.timedOutSubmitting || RecallPhase.advancing => Align(
        child: MxActionButton(label: l10n.studyContinueAction, onPressed: null),
      ),
    };
  }

  bool get _canAssess => !isLocked && phase == RecallPhase.selfAssessment;
}

/// The row of actions under a pair of study cards.
///
/// Centred and capped rather than stretched: one or two buttons under two cards
/// read as the way on, where a full-width bar reads as the screen floor. Shared
/// with `fill`, which asks the same two questions in the other direction and
/// held an identical private copy of this.
///
/// **When there are two, they are the same size — the row's whole job.** They
/// used to be `Flexible` around their own labels, so `Forgotten` came out
/// narrower than `Remembered` and `Show hint` narrower than `Check`: two verdict
/// buttons at two widths, on the screen a learner presses more than any other,
/// with the size difference reading as a recommendation the app never meant to
/// make. Each half now fills its share up to [AppStudyPair.ctaMaxWidth] — the
/// cap survives, and both halves get the same share — and
/// [CrossAxisAlignment.stretch] under an [IntrinsicHeight] gives them one
/// height when a label wraps at a large text scale.
///
/// A lone action still hugs its label: it is not next to anything, so there is
/// nothing for it to match, and stretching it to the cap would draw a
/// half-width bar under the cards.
class StudyCtaRowWidget extends StatelessWidget {
  const StudyCtaRowWidget({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final isPair = children.length > 1;

    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final (index, child) in children.indexed) ...<Widget>[
            if (index > 0) const SizedBox(width: AppSpacing.md),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppStudyPair.ctaMaxWidth,
                ),
                // `Flexible` hands every child the same loose share; filling it
                // is what turns "the same room" into "the same width".
                child: isPair
                    ? SizedBox(width: double.infinity, child: child)
                    : child,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
