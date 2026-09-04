import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../../core/theme/foundations/app_durations.dart';
import '../../../../../core/theme/foundations/app_motion_policy.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';

/// How far a drag must travel before it counts as a swipe.
///
/// **Well above the slop that starts the gesture and well below the card.** A
/// short threshold turns a scroll of a long meaning into a card change; a long
/// one makes the gesture feel like it did not take. 70 is the design kit's
/// figure and it survives a 320-wide screen, where it is still under a quarter
/// of the width.
// off-grid: the kit's figure for a committed drag — a gesture distance, not a laid-out size
const double kStudySwipeThreshold = 70;

/// The distance over which a dragged card fades, and the most it may fade.
const double _kFadeOverDistance = 400;
const double _kMaxDragFade = 0.5;

/// Radians of tilt per logical pixel of drag — the card pivots as it is pushed.
const double _kTiltPerPixel = 0.025 * math.pi / 180;

/// Drag left and right to move between cards (BR-155).
///
/// **It wraps the card rather than living inside it.** The card face is shared
/// with `self_assess`, which has no swipe at all — a gesture built into it would
/// have to be switched off from the outside, and a gesture that is sometimes
/// live is how a mode ends up navigable that no rule says is navigable.
///
/// **The card always settles back to centre, and the content changes under it.**
/// The design throws the card off screen and swaps after it lands. That needs
/// the outgoing card to be held somewhere while it flies, and if the move is
/// then refused — a locked write, a trail with nothing behind it — the card is
/// left off screen with nothing to bring it back. Settling and letting the new
/// content arrive at rest cannot strand it, and it costs the throw, not the
/// gesture.
///
/// **The swipe is one path, not the only one** (A20.1-P0-01, WCAG 2.5.7). A
/// 70 dp horizontal drag cannot be performed by everyone who holds a phone —
/// a tremor, one hand, a stylus, a head pointer — and until the Design System
/// V1 closure this mode had no other input: the custom semantics actions below
/// serve TalkBack and Switch Access, and nobody else. The deck therefore draws
/// a Previous / Next pair under the card: two 48 dp icon buttons, a visible,
/// enabled, single-pointer path that a screen reader also meets as ordinary
/// buttons. The swipe stays; the buttons are an addition, and the closure test
/// (`study_browse_pointer_path_test.dart`) finds them by their semantics, not
/// by their widget, so the affordance's form is free to change.
class StudySwipeDeckWidget extends StatefulWidget {
  const StudySwipeDeckWidget({
    required this.cardKey,
    required this.onForward,
    required this.onBack,
    required this.canGoBack,
    required this.child,
    this.isLocked = false,
    super.key,
  });

  /// Identifies the card on screen, so an incoming card can be put at rest
  /// whichever way the outgoing one was pushed.
  final String cardKey;

  final VoidCallback onForward;
  final VoidCallback onBack;

  /// False at the front of a round, where there is no trail behind.
  final bool canGoBack;

  /// True while an answer is being written. The card still moves under the
  /// finger — refusing to move reads as a dropped gesture — but it commits
  /// nothing (BR-25).
  final bool isLocked;

  final Widget child;

  @override
  State<StudySwipeDeckWidget> createState() => _StudySwipeDeckWidgetState();
}

class _StudySwipeDeckWidgetState extends State<StudySwipeDeckWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: AppDurations.normal,
  )..addListener(_onSettleTick);

  /// How far the card has been dragged from rest, in logical pixels.
  double _offset = 0;

  /// Where the settle started, so it can run from there back to zero.
  double _settleFrom = 0;

  @override
  void didUpdateWidget(StudySwipeDeckWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.cardKey != widget.cardKey) _resetToRest();
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onSettleTick() {
    setState(() => _offset = _settleFrom * (1 - _settle.value));
  }

  void _resetToRest() {
    _settle.stop();
    setState(() {
      _offset = 0;
      _settleFrom = 0;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _settle.stop();
    setState(() => _offset += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    final travelled = _offset;
    _settleBack();

    if (widget.isLocked) return;
    if (travelled.abs() < kStudySwipeThreshold) return;

    // Left is forward, the way the text runs. Right goes back along the trail,
    // and only when there is one — a swipe into nothing still settles, so the
    // gesture reads as refused rather than unheard.
    if (travelled < 0) {
      widget.onForward();

      return;
    }

    if (widget.canGoBack) widget.onBack();
  }

  void _settleBack() {
    _settleFrom = _offset;
    unawaited(_settle.forward(from: 0));
  }

  double get _fade =>
      1 - (_offset.abs() / _kFadeOverDistance).clamp(0.0, _kMaxDragFade);

  @override
  Widget build(BuildContext context) {
    // The settle decorates a state change, so it is one of the animations
    // `AppMotionPolicy` is for. Read here rather than in `initState` because
    // the platform flag can change while the session is open.
    _settle.duration = AppMotionPolicy.durationOf(context, AppDurations.normal);

    final l10n = context.l10n;

    // **The gesture is not the only way through** (BR-155). A 70dp horizontal
    // drag cannot be performed by a screen reader or a switch, so without this
    // the mode would have no way forward at all once its button was removed.
    // Custom actions put both moves in the reader's action menu and draw
    // nothing — which is the point: the card is the content of this mode, and a
    // button beside it was a band of screen doing what the swipe does.
    //
    // Back is offered only when there is somewhere to go, for the same reason a
    // disabled button would have been wrong: an action that does nothing is
    // worse than an action that is not there.
    // **Locked means locked for both paths.** `isLocked` guarded the drag and
    // not these, so while the previous step was still being written a reader
    // could invoke Continue again — the one way through the mode that a screen
    // reader has, and the one the gesture's own guard did not cover. Offered
    // rather than disabled-and-present: an action that does nothing is worse
    // than an action that is not there, which is the same reason Back appears
    // only when there is somewhere to go.
    return Semantics(
      // Its own node, with the two buttons as children: the custom actions
      // ride on the deck and the buttons announce themselves. Without
      // `container` the actions would merge into whatever node is above.
      container: true,
      explicitChildNodes: true,
      customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
        if (!widget.isLocked) ...<CustomSemanticsAction, VoidCallback>{
          CustomSemanticsAction(label: l10n.studyContinueAction):
              widget.onForward,
          if (widget.canGoBack)
            CustomSemanticsAction(label: l10n.studyBrowsePreviousCard):
                widget.onBack,
        },
      },
      // The card fills what the frame gives it — its halves are `Expanded`
      // and need a bounded height — and the pointer row takes its own 48
      // underneath.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: _gestureLayer()),
          _pointerRow(context),
        ],
      ),
    );
  }

  /// The single-pointer path (A20.1-P0-01): Previous on the leading edge, Next
  /// on the trailing one, in the order the swipe reads.
  ///
  /// **Previous keeps its room when it is not offered.** At the front of the
  /// trail there is nothing behind, and a button that does nothing is worse
  /// than one that is not there (the same rule the custom actions follow) —
  /// but a button that *appears* on the second card would slide Next across
  /// the row on every first step. `Visibility` with the maintain flags holds
  /// the slot and drops the control from the tree and from semantics.
  ///
  /// **Locked disables rather than hides.** `isLocked` is a moment — a write in
  /// flight — and a control that vanishes and returns within a second reads as
  /// a glitch; a disabled one reads as "wait". The custom actions above are
  /// absent while locked because an action menu has no disabled state to show.
  Widget _pointerRow(BuildContext context) {
    final l10n = context.l10n;
    final VoidCallback? forward = widget.isLocked ? null : widget.onForward;
    final VoidCallback? back = widget.isLocked || !widget.canGoBack
        ? null
        : widget.onBack;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Visibility(
            visible: widget.canGoBack,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: MxIconButton(
              // `navigate_before` / `navigate_next`, not `arrow_back`: the
              // arrow is the app bar's "leave this screen", and the same
              // glyph one row below it would say the wrong thing (P2-19).
              icon: Icons.navigate_before,
              semanticLabel: l10n.studyBrowsePreviousCard,
              tooltip: l10n.studyBrowsePreviousCard,
              onPressed: back,
            ),
          ),
          MxIconButton(
            icon: Icons.navigate_next,
            semanticLabel: l10n.studyContinueAction,
            tooltip: l10n.studyContinueAction,
            onPressed: forward,
          ),
        ],
      ),
    );
  }

  Widget _gestureLayer() {
    return GestureDetector(
      // Horizontal only: the card's halves scroll vertically at a large text
      // scale, and claiming the vertical axis here would take that away.
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _settleBack,
      child: Transform.translate(
        offset: Offset(_offset, 0),
        child: Transform.rotate(
          angle: _offset * _kTiltPerPixel,
          child: Opacity(opacity: _fade, child: widget.child),
        ),
      ),
    );
  }
}
