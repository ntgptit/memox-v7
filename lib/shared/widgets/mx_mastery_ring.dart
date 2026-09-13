import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_stroke.dart';

/// Handoff MasteryRing (section E): a 40 ring with a 3px arc. The arc is
/// `primary` until [isComplete], then `mastery` — BR-88 decides "complete" and
/// the caller passes it (D8); the handoff's percentage steps name no colours.
class MxMasteryRing extends StatelessWidget {
  const MxMasteryRing({
    required this.value,
    required this.isComplete,
    required this.semanticsLabel,
    this.semanticsValue,
    super.key,
  }) : assert(value >= 0 && value <= 1, 'value is a fraction');

  /// The learned fraction, `0..1`.
  final double value;

  /// Whether every card is learned (BR-88) — the only thing that turns the arc
  /// to `mastery`. A value that rounds to 100% is not complete.
  final bool isComplete;

  /// Already-localized. Announced as the ring's name.
  final String semanticsLabel;

  /// Already-localized, e.g. "62%". Announced as the ring's value.
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return Semantics(
      label: semanticsLabel,
      value: semanticsValue,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: AppSizing.masteryRing,
        child: CustomPaint(
          painter: MxMasteryRingPainter(
            value: value,
            track: semantic.progressTrack,
            fill: isComplete ? semantic.mastery : context.colors.primary,
            stroke: AppStroke.ring,
          ),
        ),
      ),
    );
  }
}

/// The ring's paint. Public so a test can read the resolved colours; not a
/// component — callers build [MxMasteryRing].
class MxMasteryRingPainter extends CustomPainter {
  const MxMasteryRingPainter({
    required this.value,
    required this.track,
    required this.fill,
    required this.stroke,
  });

  final double value;
  final Color track;
  final Color fill;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      paint..color = fill,
    );
  }

  @override
  bool shouldRepaint(MxMasteryRingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.fill != fill ||
      oldDelegate.track != track ||
      oldDelegate.stroke != stroke;
}
