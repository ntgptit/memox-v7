import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/app_well_fill.dart';
import 'mx_icon.dart';

/// The small icon well a metric anchors on: same size, same radius, same
/// padding, so metrics on different screens read as entries of one grammar and
/// only the glyph and the tint differ.
///
/// **Shared because it was already written twice** — privately in the deck
/// summary and privately in Progress's metric grid, identical line for line —
/// and a third screen was about to do without it, which is the version of the
/// same problem that shows up as three tabs looking like three apps (M99.26).
///
/// **Both colours were `required Color` until M100.5, which made this the only
/// shared widget that asked a caller to pick one.** Four of the five call sites
/// passed the same `surfaceMuted`, so the real default lived in four places;
/// and every one of the five already wrote [tint] as `<AppInk>.resolve(context)`
/// — the vocabulary, spelled out longhand at each site.
///
/// So [tint] is an `AppInk` and [fill] is an `AppWellFill` that defaults to
/// the muted well (A20.1 P2-07, owner decision 2: structural closure). The
/// deck hero still moves the fill with the deck's state — it just picks a
/// named fill rather than a colour. What must not vary is still the shape.
class MxMetricWell extends StatelessWidget {
  const MxMetricWell({
    required this.icon,
    required this.tint,
    this.fill = AppWellFill.muted,
    super.key,
  });

  final IconData icon;

  /// The glyph's ink, named rather than picked.
  final AppInk tint;

  /// The well behind it, named rather than picked.
  final AppWellFill fill;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill.resolve(context),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: MxIcon(icon, ink: tint, size: MxIconSize.sm),
      ),
    );
  }
}
