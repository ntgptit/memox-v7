import 'package:flutter/material.dart';

import '../../core/theme/extensions/theme_context_extension.dart';

/// The one lifecycle-colour mapping used by mastery visualizations.
///
/// It owns only fixed threshold-to-role mapping; callers own the percentage
/// and the geometry that displays it.
abstract final class MxMasteryRamp {
  static const double _reviewingThreshold = .34;
  static const double _masteredThreshold = .67;

  static Color colorFor(BuildContext context, double progress) {
    final double value = progress.clamp(0, 1);
    final semantic = context.semanticColors;
    if (value < _reviewingThreshold) return semantic.statusLearning;
    if (value < _masteredThreshold) return semantic.statusReviewing;
    return semantic.statusMastered;
  }

  static Color trackFor(BuildContext context) =>
      context.semanticColors.progressTrack;
}
