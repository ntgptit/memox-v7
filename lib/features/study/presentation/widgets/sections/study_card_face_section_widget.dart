import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/foundations/app_stroke.dart';
import '../../../../../core/theme/typography/app_typography.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/study_answer_commit_model.dart';
import '../../../domain/models/study_action_model.dart';
import '../../../domain/models/study_direction_model.dart';
import '../../../domain/models/study_turn_model.dart';
import '../support/study_labels_widget.dart';
import '../../../../../shared/widgets/mx_section_label.dart';

part 'study_card_face_pieces_widget.dart';

/// Which face is the focal one, which is what decides both faces' roles.
///
/// **A named contract rather than a second reading of
/// [StudyCardFaceSectionWidget.shouldShowBackImmediately].** The two happen to
/// move together today, but they are different questions, and a widget that
/// inferred one from the other would silently pick a hierarchy the next mode
/// never asked for.
enum StudyFaceEmphasis {
  /// The front is what the eye should land on and the back explains it.
  ///
  /// `browse` (BR-112). **BR-08 is what settles the direction, and it settled
  /// it long before this widget existed:** the front is capped at 60 characters
  /// because it is the prompt a phone draws on one line, and the back at 240
  /// because "một nghĩa chứa nhiều hơn một từ — hai ngôn ngữ, ngăn bằng dấu
  /// phẩy". A term on the front, its meaning on the back.
  ///
  /// Two earlier attempts got here the long way. The first gave the front the
  /// prompt role and a real meaning swallowed the card; the second called the
  /// faces peers, which fixed that and left two equal blocks saying nothing
  /// about where to look. Both were reasoning from a fixture whose front was 67
  /// characters — data BR-08 forbids and the app would refuse to save.
  ///
  /// So: the front takes the title role at w500, and the back a body role,
  /// which is what carries 240 characters without shouting. Both are a step
  /// under [promptFirst], because here they are read together rather than one
  /// at a time.
  backSupportingFront,

  /// The front is the prompt and the back is the answer it is checked against.
  /// `self_assess`: the front is the largest thing on screen until the flip.
  promptFirst,
}

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
    this.onFeedbackShown,
    this.viewedCard,
    this.shouldShowBackImmediately = false,
    this.emphasis = StudyFaceEmphasis.promptFirst,
    this.direction = StudyRecallDirection.koreanToMeaning,
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

  /// Empty for `browse`, which produces no action (BR-111).
  final List<StudyAction> actions;

  /// Writes the action and hands back what the transaction did (BR-157).
  ///
  /// **A `ValueChanged` here silently threw the receipt away.** Dart lets a
  /// function returning a value stand in for a `void` one, so this compiled
  /// while dropping the only thing that says the write happened — and
  /// `self_assess` stopped moving to the next card at all, because nothing was
  /// left to call [onFeedbackShown] with.
  final Future<StudyAnswerCommitModel?> Function(StudyAction) onAction;

  /// Called once the answer has committed; completes when the session has moved
  /// on (BR-158). `self_assess` has no verdict to read — the user just gave it —
  /// so `studyModeFeedback` holds it for zero and this is simply the advance.
  final Future<void> Function({required bool isCorrect})? onFeedbackShown;

  /// Used by `browse`, which has nothing to grade and only moves on.
  final VoidCallback onContinue;

  /// `browse` sets this; `self_assess` leaves it false and reveals on tap.
  final bool shouldShowBackImmediately;

  /// Whether the two faces are peers or a prompt and its answer. See
  /// [StudyFaceEmphasis].
  final StudyFaceEmphasis emphasis;

  /// Which face is the prompt and which is the reveal (BR-204).
  ///
  /// **It swaps the two halves' content, and nothing else.** The card's own
  /// columns are untouched (BR-209), and the corner labels move with their
  /// text, which is what tells the two directions apart without relying on
  /// colour.
  ///
  /// **The type role travels with the face, not with the half** — see
  /// `_selfAssessRole`. Position was right while the prompt was always the
  /// ≤60-character front; reversed, it sized a 240-character meaning as one.
  ///
  /// Defaults to the direction every build before BR-203 used, so `browse` and
  /// the learning chain draw exactly as they did.
  final StudyRecallDirection direction;

  /// True while an answer is being written. The card **stays** visible and only
  /// the controls stop responding (BR-25).
  final bool isLocked;

  @override
  Widget build(BuildContext context) => _StudyCardFaceView(
    turn: turn,
    actions: actions,
    onAction: onAction,
    onFeedbackShown: onFeedbackShown,
    onContinue: onContinue,
    viewedCard: viewedCard,
    shouldShowBackImmediately: shouldShowBackImmediately,
    emphasis: emphasis,
    direction: direction,
    isLocked: isLocked,
  );
}

class _StudyCardFaceView extends StatefulWidget {
  const _StudyCardFaceView({
    required this.turn,
    required this.actions,
    required this.onAction,
    required this.onContinue,
    this.onFeedbackShown,
    required this.viewedCard,
    required this.shouldShowBackImmediately,
    required this.emphasis,
    required this.direction,
    required this.isLocked,
  });

  final StudyTurnModel turn;
  final List<StudyAction> actions;
  final Future<StudyAnswerCommitModel?> Function(StudyAction) onAction;
  final Future<void> Function({required bool isCorrect})? onFeedbackShown;
  final VoidCallback onContinue;
  final StudyCardModel? viewedCard;
  final bool shouldShowBackImmediately;
  final StudyFaceEmphasis emphasis;
  final StudyRecallDirection direction;
  final bool isLocked;

  @override
  State<_StudyCardFaceView> createState() => _StudyCardFaceViewState();
}

class _StudyCardFaceViewState extends State<_StudyCardFaceView> {
  bool _isRevealed = false;

  /// True while an action's transaction is open.
  ///
  /// **Local, because the parent cannot be quick enough.** The controller's
  /// `isSubmitting` reaches this widget on the next rebuild, and a second tap
  /// fits inside that gap — BR-126 says one question yields at most one turn.
  bool _isSubmitting = false;

  /// Writes the action, then moves on — in that order (BR-157, BR-158).
  ///
  /// A null receipt is a write that did not happen, or one belonging to a
  /// session the user has already left. Either way the card stays and the
  /// buttons come back if there is still a session to answer.
  Future<void> _grade(StudyAction action) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final commit = await widget.onAction(action);
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (commit == null) return;

    // `self_assess` has nothing new to read — the verdict is the user's own —
    // so `studyModeFeedback` holds it for zero and this is the advance.
    await widget.onFeedbackShown?.call(isCorrect: !action.isLapse);
  }

  @override
  void didUpdateWidget(_StudyCardFaceView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A new turn arrives face down. Without this the flip state survives into
    // the next card, and every card after the first shows its answer already —
    // including the same card coming back in a later round, which is what
    // `isSameTurnAs` is for.
    if (!oldWidget.turn.isSameTurnAs(widget.turn)) _isRevealed = false;
  }

  bool get _showsBack => widget.shouldShowBackImmediately || _isRevealed;

  /// What is on screen, which is the turn's card unless the user is looking
  /// back along the trail (BR-155).
  StudyCardModel get _card => widget.viewedCard ?? widget.turn.card;

  /// The type role a `self_assess` half takes, chosen by the **face** it
  /// shows: the front is at most 60 characters and the back up to 240 (BR-08),
  /// so the role follows the content rather than the card's upper/lower half.
  TextStyle? _selfAssessRole(BuildContext context, StudyCardFace face) =>
      face == StudyCardFace.front
      ? context.textStyles.cardPrompt
      : context.texts.headlineSmall;

  /// The text of one face of [_card].
  ///
  /// **A lookup, not an `if` at each of the four call sites.** The prompt half
  /// and the reveal half each need a string and a label, and spelling the
  /// direction out four times is four chances to spell one of them backwards —
  /// which renders a card whose two halves are the same text and looks like a
  /// data problem.
  String _textOf(StudyCardFace face) =>
      face == StudyCardFace.front ? _card.front : _card.back;

  /// The corner label of one face, which names the column it came from.
  ///
  /// The label follows the content rather than the position, which is what makes
  /// the two directions distinguishable without colour: the upper half of a
  /// Meaning→Korean card says `BACK`, and a screen reader reads it in that order.
  String _labelOf(BuildContext context, StudyCardFace face) =>
      face == StudyCardFace.front
      ? context.l10n.studyCardFaceFront
      : context.l10n.studyCardFaceBack;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;

    final controls = _controls(context);
    final promptFace = widget.direction.promptFace;
    final revealFace = widget.direction.revealFace;

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
          child: MxCard.focal(
            // **The card pads its sides; each half pads its own ends.** One
            // uniform inset put as much air either side of the rule as at the
            // card's outer edge, and the halves then read as two cards stacked
            // rather than the two faces of one (§3). The rule itself runs the
            // full width between the side insets, which is what makes it a
            // fold rather than a separator dropped between two blocks.
            padding: MxCardPadding.none,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: _CardHalf(
                      label: _labelOf(context, promptFace),
                      text: _textOf(promptFace),
                      // The focal face — the term (BR-08) — at the title role and
                      // one step down in weight so it leads without shouting.
                      //
                      // **`self_assess` sizes by which face this is, not by which
                      // half.** The prompt half used to be `headlineMedium`
                      // unconditionally, which was right while the prompt was
                      // always the front (≤60 characters, BR-08). Reversing the
                      // direction put a 240-character meaning there at 30dp — the
                      // very thing the supporting half below says a heading role
                      // is not for — and dropped the short Korean term to 24dp.
                      style:
                          widget.emphasis ==
                              StudyFaceEmphasis.backSupportingFront
                          ? AppTypography.withWeight(
                              texts.titleLarge!,
                              FontWeight.w500,
                            )
                          : _selfAssessRole(context, promptFace),
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
                        label: _labelOf(context, revealFace),
                        text: _textOf(revealFace),
                        // The supporting face. Under the graded modes it is
                        // always the meaning — 240 characters (BR-08), a body
                        // role's job. Under `self_assess` it is whichever face
                        // the prompt is not, so `_selfAssessRole` decides.
                        style:
                            widget.emphasis ==
                                StudyFaceEmphasis.backSupportingFront
                            ? texts.bodyLarge
                            : _selfAssessRole(context, revealFace),
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
        ),
        // **The gap belongs to the controls, so it goes when they do.** `browse`
        // draws none (BR-155), and a fixed gap under the card left a band of
        // nothing below it — the exact shape of the complaint this screen was
        // rebuilt to answer.
        //
        // **And it is `lg`, the frame's own band gap** (SC-C2-10). At `xl` this
        // was the widest of five spellings of one role on one screen — 8, 12,
        // 16, 16, 24 — where `study_session_frame_section_widget.dart` already
        // sets `lg` above and below the whole band.
        if (controls.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          ...controls,
        ],
      ],
    );
  }

  List<Widget> _controls(BuildContext context) {
    // `browse` grades nothing, so it gets one way forward and no judgement to
    // make (BR-111). Showing it disabled action buttons would ask a question it
    // is not allowed to record an answer to.
    // **`browse` has no grading controls, because it has nothing to ask**
    // (BR-111). Moving between cards belongs to `StudySwipeDeckWidget`, which
    // owns both paths — the swipe (BR-155) and, since A20.1-P0-01, the
    // Previous / Next pair a single pointer can use without dragging. This
    // face draws neither; it would be a second place deciding how the mode
    // moves.
    if (widget.actions.isEmpty) return const <Widget>[];

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

    // **One primary, and it is the grade the learner gives most** (M100.36
    // 4B). Every grade used to be a brand fill — four stacked for `sm2` — so
    // the face said nothing about which answer was the ordinary one, and
    // disagreed with the recall timer, which had already drawn Forgot as the
    // secondary beside Remembered. `secondary` for the rest rather than
    // `destructive`: a lapse is a legitimate grade, not an error to be warned
    // about, and red on a learning button says "you did something wrong".
    // **The gap sits between two buttons, so it leads rather than trails.** It
    // used to close the loop body, which meant it also ran after the *last*
    // grade: the revealed `self_assess` body ended in 8dp of dead space that
    // no other mode has — measured 8.0 at 393×600 against 0.0 for `browse`,
    // `recall` and `fill` — and the unrevealed branch above, which draws one
    // button and no trailing gap, changed the foot of the body across the
    // flip. `if (index > 0)` is the guard the two neighbouring lists already
    // use: `guess_question_section_widget.dart` and `match_board_grid_widget`.
    return <Widget>[
      for (final (index, action) in widget.actions.indexed) ...<Widget>[
        if (index > 0) const SizedBox(height: AppSpacing.sm),
        MxActionButton(
          label: context.studyAction(action),
          variant: action.isNormalGrade
              ? MxActionButtonVariant.primary
              : MxActionButtonVariant.secondary,
          onPressed: widget.isLocked || _isSubmitting
              ? null
              : () => _grade(action),
        ),
      ],
    ];
  }
}
