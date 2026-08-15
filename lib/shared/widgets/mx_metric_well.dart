import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// The small icon well a metric anchors on: same size, same radius, same
/// padding, so metrics on different screens read as entries of one grammar and
/// only the glyph and the tint differ.
///
/// **Shared because it was already written twice** — privately in the deck
/// summary and privately in Progress's metric grid, identical line for line —
/// and a third screen was about to do without it, which is the version of the
/// same problem that shows up as three tabs looking like three apps (M99.26).
///
/// [wellColor] is a parameter rather than a fixed tint: the deck hero moves it
/// with the deck's state, and Progress holds it neutral. What must not vary is
/// the shape.
class MxMetricWell extends StatelessWidget {
  const MxMetricWell({
    required this.icon,
    required this.tint,
    required this.wellColor,
    super.key,
  });

  final IconData icon;

  /// The glyph's ink.
  final Color tint;

  /// The well behind it.
  final Color wellColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: wellColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(icon, size: AppIconSize.sm, color: tint),
      ),
    );
  }
}
