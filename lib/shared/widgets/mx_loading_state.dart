import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';

/// The loading state, centred in whatever space it is given.
///
/// Takes an already-localized [semanticsLabel] because a bare spinner is
/// invisible to a screen reader — it announces nothing at all, so the user is
/// told neither that something is happening nor when it stops.
class MxLoadingState extends StatelessWidget {
  const MxLoadingState({required this.semanticsLabel, super.key});

  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        // The indicator animates for as long as it is on screen, and a
        // `markNeedsPaint` travels up to the nearest repaint boundary — without
        // one that is the enclosing layer, so *everything* sharing it repaints
        // on every frame of the spin.
        //
        // Measured: a sibling `CustomPaint` beside this widget was painted once
        // more per animation frame (10 extra paints over 10 frames). With the
        // boundary the spinner gets its own layer and the sibling is painted
        // once. The cost is one render object; the alternative is the whole
        // loading screen repainting at 60fps to move one arc.
        child: RepaintBoundary(
          child: CircularProgressIndicator(
            semanticsLabel: semanticsLabel,
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }
}
