import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_spacing.dart';

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
          // **No `color:` here on purpose.** It used to pass
          // `context.colors.primary`, which quietly overrode
          // `buildProgressIndicatorTheme` — the theme M4.10j introduced *because*
          // dark `primary` measures 2.81:1 against the surface it spins on,
          // under the 3.0 floor a graphic needs. The theme therefore reached
          // every spinner in the app except the one screen whose whole job is to
          // be a spinner. Letting the theme supply the colour is the fix, and it
          // is the same rule the repo applies everywhere else: correct it at the
          // rule, not at the call site.
          child: CircularProgressIndicator(semanticsLabel: semanticsLabel),
        ),
      ),
    );
  }
}
