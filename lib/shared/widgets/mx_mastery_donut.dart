import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/typography/app_typography.dart';
import 'mx_mastery_ramp.dart';

/// A read-only 56dp mastery percentage ring.
class MxMasteryDonut extends StatelessWidget {
  static const double _boxSize = 56;
  static const double _labelSize = 9;
  MxMasteryDonut({required this.progress, super.key}) {
    if (progress < 0 || progress > 1) {
      throw ArgumentError.value(progress, 'progress', 'must be from 0 to 1');
    }
  }

  final double progress;

  @override
  Widget build(BuildContext context) {
    final String percentage = '${(progress * 100).round()}%';
    final Color color = MxMasteryRamp.colorFor(context, progress);
    return Semantics(
      label: '$percentage mastery',
      child: ExcludeSemantics(
        child: SizedBox(
          width: _boxSize,
          height: _boxSize,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: const Size.square(_boxSize),
                painter: _MasteryDonutPainter(
                  progress: progress,
                  track: context.colors.surfaceContainer,
                  fill: color,
                ),
              ),
              Text(
                percentage,
                style: AppTypography.withWeight(
                  context.texts.labelSmall!.copyWith(
                    color: color,
                    fontSize: _labelSize,
                  ),
                  FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MasteryDonutPainter extends CustomPainter {
  static const double _stroke = 3;
  static const double _radius = 17;
  const _MasteryDonutPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Rect arcRect = rect.deflate((size.width - (_radius * 2)) / 2);
    final Paint base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, base);
    if (progress == 0) return;
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      base..color = fill,
    );
  }

  @override
  bool shouldRepaint(_MasteryDonutPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      track != oldDelegate.track ||
      fill != oldDelegate.fill;
}
