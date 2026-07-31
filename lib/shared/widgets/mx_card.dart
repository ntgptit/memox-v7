import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';

/// The app's one raised surface: a bordered panel.
///
/// **Flat today, not flat by rule.** This doc used to say "flat by design" and
/// argue it from the review screen, which does not exist yet; two later
/// milestones then cited that sentence as a constraint. It never was one — there
/// is no AD, no BR and no test behind it, and `docs/checklist.md` actually asks
/// for an Elevation token that was never built.
///
/// The project owner has since said the app needs real elevation to separate
/// elements. Until that lands the card is bordered and unshadowed, and the
/// border is doing the whole job at 1.82:1 — heavier than it should have to be.
/// When a shadow arrives, this is where it goes and the border should come
/// down.
///
/// [onTap] makes the whole surface one target rather than requiring a nested
/// button. That is a generic capability, not a feature one: any card that stands
/// for a thing the user can open wants it, and building the ink by hand at each
/// call site is how two call sites end up with different splash radii.
///
/// The ripple is clipped to the same [AppRadius.lg] the border uses, and the card
/// keeps its exact unshadowed look when [onTap] is null — the `Material` layer is
/// transparent and exists only to host the ink.
class MxCard extends StatelessWidget {
  const MxCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Makes the whole card a target. Null leaves it a plain surface.
  ///
  /// No accompanying `semanticLabel`. The `InkWell` below already announces the
  /// card as a button and its children supply the name — a card whose content is
  /// readable text does not need a second one, and an override would *hide* that
  /// content from a screen reader rather than adding to it. If a caller ever has
  /// a card whose contents genuinely do not name it, that is the point to add it,
  /// with the caller in hand to check the announcement against.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.semanticColors.borderSubtle),
      ),
      child: Padding(padding: padding, child: child),
    );

    final tap = onTap;
    if (tap == null) return surface;

    // `button: true` and nothing else. An `InkWell` contributes a tap action and
    // focusability but **not** the button flag — a screen reader would read the
    // card's text and never say it can be activated. Annotating rather than
    // labelling is the whole point: adding a `label` here would replace the
    // children's text instead of naming the control, which is the mistake the
    // first version of this made.
    return Semantics(
      button: true,
      child: Material(
        // Transparency rather than a colour: the `DecoratedBox` above already
        // paints the surface, and a second opaque layer would double the border
        // radius' antialiasing seam.
        type: MaterialType.transparency,
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: surface,
        ),
      ),
    );
  }
}
