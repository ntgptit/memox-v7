import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';

/// The one lifecycle-colour mapping used by mastery visualizations.
///
/// It owns only fixed threshold-to-role mapping; callers own the percentage
/// and the geometry that displays it.
abstract final class MxMasteryRamp {
  static Color colorFor(BuildContext context, double progress) {
    final double value = progress.clamp(0, 1);
    final semantic = context.semanticColors;
    if (value < .34) return semantic.statusLearning;
    if (value < .67) return semantic.statusReviewing;
    return semantic.statusMastered;
  }

  static Color trackFor(BuildContext context) =>
      context.semanticColors.progressTrack;
}
