import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_stroke.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
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
class StudyCardFaceSectionWidget extends StatelessWidget {
  const StudyCardFaceSectionWidget({
    required this.turn,
    required this.actions,
    required this.onAction,
    required this.onContinue,
    this.viewedCard,
    this.onBack,
    this.shouldShowBackImmediately = false,
    this.isLocked = false,
    super.key,
  });

  final StudyTurnModel turn;

  /// The card to draw, when it is not the turn's own.
  ///
  /// `browse` puts an earlier card back on screen while the user looks back
  /// (BR-155). The **turn** still governs the flip state and the identity of
  /// the answerable card, because those belong to the turn rather than to
  /// whatever is being looked at.
  final StudyCardModel? viewedCard;

  /// Steps back along the trail of cards already seen (BR-155).
  ///
  /// **Null when there is nothing behind**, which is also what hides the
  /// control. It exists because the gesture alone would make the trail
  /// unreachable to anyone who cannot make a 70px horizontal drag — a screen
  /// reader in particular has no way to perform one.
  final VoidCallback? onBack;

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
    viewedCard: viewedCard,
    onBack: onBack,
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
    required this.viewedCard,
    required this.onBack,
    required this.shouldShowBackImmediately,
    required this.isLocked,
  });

  final StudyTurnModel turn;
  final List<StudyAction> actions;
  final ValueChanged<StudyAction> onAction;
  final VoidCallback onContinue;
  final StudyCardModel? viewedCard;
  final VoidCallback? onBack;
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

  /// What is on screen, which is the turn's card unless the user is looking
  /// back along the trail (BR-155).
  StudyCardModel get _card => widget.viewedCard ?? widget.turn.card;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;

    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // **One card taking the whole height, split in two by a hairline** —
        // `m5-study-modes.md` §3. It hugged its content until now, which left a
        // card of 188px in a frame of 852 and four hundred pixels of nothing
        // under the controls. The halves are also what say "these are the two
        // sides of one thing"; two paragraphs in a column read as two facts
        // about it.
        Expanded(
          child: MxCard(
            // **The card pads its sides; each half pads its own ends.** One
            // uniform inset put as much air either side of the rule as at the
            // card's outer edge, and the halves then read as two cards stacked
            // rather than the two faces of one (§3). The rule itself runs the
            // full width between the side insets, which is what makes it a
            // fold rather than a separator dropped between two blocks.
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _CardHalf(
                    label: l10n.studyCardFaceTerm,
                    text: _card.front,
                    // The token whose own doc calls it "the card prompt", and
                    // this is that card: largest on screen (§3).
                    style: texts.headlineMedium,
                    // **The tight end is the one facing the rule, so it is only
                    // tight when there is a rule to face.** Before the flip
                    // `self_assess` is a single half filling the card, and the
                    // short inset then had nothing under it — the term sat off
                    // centre in its own card for no reason the user could see.
                    padding: _showsBack
                        ? const EdgeInsets.only(
                            top: AppSpacing.lg,
                            bottom: AppSpacing.sm,
                          )
                        : const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  ),
                ),
                if (_showsBack) ...<Widget>[
                  Divider(
                    // The rule and nothing else: the space around it belongs to
                    // the halves, so a change of padding moves one thing.
                    height: AppStroke.hairline,
                    color: context.semanticColors.borderSubtle,
                  ),
                  Expanded(
                    child: _CardHalf(
                      label: l10n.studyCardFaceMeaning,
                      text: _card.back,
                      style: texts.headlineSmall,
                      padding: const EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.lg,
                      ),
                    ),
                  ),
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
      final onBack = widget.onBack;

      return <Widget>[
        Row(
          children: <Widget>[
            // **The gesture is not the only way back** (BR-155). A 70px
            // horizontal drag is unavailable to anyone driving the app with a
            // screen reader or a switch, so the trail would exist and be
            // unreachable. Absent — not disabled — at the front of a round,
            // where a disabled control would advertise a place to go that
            // there is no way to get to.
            if (onBack != null) ...<Widget>[
              MxIconButton(
                icon: Icons.arrow_back,
                semanticLabel: context.l10n.studyBrowsePreviousCard,
                onPressed: widget.isLocked ? null : onBack,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: MxActionButton(
                label: context.l10n.studyContinueAction,
                onPressed: widget.isLocked ? null : widget.onContinue,
              ),
            ),
          ],
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

/// One side of the card: a small muted label in the corner, and the text it
/// names centred in what is left.
///
/// **The label is in the corner and the content is in the middle** (§3). Both
/// halves are the same shape, so the eye reads them as two sides of one card
/// rather than as a heading and a paragraph — and the centre is where the eye
/// lands when a card flips.
///
/// The label is `Term`/`Meaning` rather than the design's `KOREAN`: no deck and
/// no card carries a language, and printing one would put a field in the UI
/// that does not exist in the data.
class _CardHalf extends StatelessWidget {
  const _CardHalf({
    required this.label,
    required this.text,
    required this.style,
    required this.padding,
  });

  final String label;
  final String text;
  final TextStyle? style;

  /// Asymmetric on purpose — see the card above. Vertical only; the sides
  /// belong to the card so that the rule between the halves can reach them.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
            letterSpacing: AppTypography.sectionLabelTracking,
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              // The half is a fixed share of the card, so at a large text scale
              // a long meaning has to be able to move rather than overflow.
              child: Text(text, style: style, textAlign: TextAlign.center),
            ),
          ),
        ),
      ],
    ),
  );
}
