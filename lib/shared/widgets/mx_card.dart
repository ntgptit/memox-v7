import 'package:flutter/material.dart';

import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';

/// The app's one raised surface: a bordered panel that carries elevation.
///
/// **It was flat, and that was never a rule.** Two doc comments said the surface
/// ladder worked without a shadow, and two milestones read that as a ban — no AD,
/// no BR, no test behind it, while `docs/checklist.md` asked for an Elevation
/// token nobody built. The project owner has since said the app needs real
/// elevation to separate elements, so it has one.
///
/// **The shadow appears in light and not in dark, by measurement.** The dark page
/// sits at the bottom of the lightness scale, so a shadow there moves it by
/// ΔL\* 0.26 where the surface step already moves it 7.70 — see [shadowsFor].
/// Dark keeps its ladder and its border; light gains a shadow and gives some
/// border back.
///
/// [onTap] makes the whole surface one target rather than requiring a nested
/// button. That is a generic capability, not a feature one: any card that stands
/// for a thing the user can open wants it, and building the ink by hand at each
/// call site is how two call sites end up with different splash radii.
///
/// **A tappable card may still hold its own controls.** The ink covers the whole
/// card and a nested button wins the gesture arena over it, so a card with a
/// trailing menu does not have to make a *region* of itself the target — which is
/// the arrangement that leaves the rest of the card looking tappable and inert.
/// The web kit had to be taught the same thing the hard way: a `<button>` cannot
/// contain a control, so `MxCard` there lays its target under the content rather
/// than becoming one.
///
/// **The ink layer sits inside the decoration, not around it.** An `InkWell`
/// paints its splash and its hover highlight *before* it paints its child, so a
/// card that wrapped the whole `DecoratedBox` in one drew every state underneath
/// an opaque surface colour — a tappable card with no visible feedback at all.
/// The `Material` is transparent and hosts only the ink; the ripple is clipped to
/// the same [AppRadius.lg] the border uses, and the card looks identical when
/// [onTap] is null.
class MxCard extends StatelessWidget {
  const MxCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.elevation = AppElevation.card,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// How far this card sits above the page. [AppElevation.none] returns it to a
  /// flat bordered panel, which is what a card *inside* another surface wants —
  /// a shadow stacked on a shadow reads as a rendering fault rather than depth.
  final double elevation;

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
    final decoration = BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: context.semanticColors.borderSubtle),
      boxShadow: shadowsFor(elevation, context.colors),
    );
    final content = Padding(padding: padding, child: child);

    final tap = onTap;
    if (tap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    // `button: true` and nothing else. An `InkWell` contributes a tap action and
    // focusability but **not** the button flag — a screen reader would read the
    // card's text and never say it can be activated. Annotating rather than
    // labelling is the whole point: adding a `label` here would replace the
    // children's text instead of naming the control, which is the mistake the
    // first version of this made.
    return DecoratedBox(
      decoration: decoration,
      child: Semantics(
        button: true,
        child: Material(
          // Transparency rather than a colour: the `DecoratedBox` around it
          // already paints the surface, and a second opaque layer would double
          // the border radius' antialiasing seam.
          type: MaterialType.transparency,
          child: InkWell(
            onTap: tap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: content,
          ),
        ),
      ),
    );
  }
}
