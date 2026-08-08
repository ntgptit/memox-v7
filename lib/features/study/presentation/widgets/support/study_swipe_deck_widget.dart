import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_durations.dart';
import '../../../../../core/theme/app_motion_policy.dart';

/// How far a drag must travel before it counts as a swipe.
///
/// **Well above the slop that starts the gesture and well below the card.** A
/// short threshold turns a scroll of a long meaning into a card change; a long
/// one makes the gesture feel like it did not take. 70 is the design kit's
/// figure and it survives a 320-wide screen, where it is still under a quarter
/// of the width.
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
