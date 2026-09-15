import 'package:flutter/material.dart';

import 'app_stroke.dart';

/// How far a surface sits above the one behind it.
///
/// **The token `docs/checklist.md` has always asked for and nobody built.** Its
/// absence was read as a rule — two doc comments said the surface ladder worked
/// "without a shadow being asked to carry the hierarchy", and two milestones
/// cited that as a ban. It never was one, and the project owner has since said
/// the app needs real elevation to separate elements.
///
/// **The values are dp, not shadows.** A `BoxShadow` is what a level *renders
/// as*, and it renders differently in each mode — see [shadowsFor]. Keeping the
/// scale separate from the paint is what lets dark opt out of shadows without
/// opting out of the scale.
abstract final class AppElevation {
  /// Flush with the surface behind it. The default for everything.
  static const double none = 0;

  /// A card in a list. The lowest step that reads as a step at all.
  static const double card = 1;

  /// A surface deliberately lifted above its neighbours — the Library's Today
  /// card, the study answer pieces, the recall timer panel all sit here.
  static const double raised = 3;

  /// A sheet or dialog over the whole screen.
  static const double overlay = 8;

  /// Every level, for the test that checks the scale climbs.
  static const List<double> scale = <double>[none, card, raised, overlay];
}

/// The shadow colour a **Material component** paints at a non-zero elevation.
///
/// [shadowsFor] is for surfaces this app draws itself; a `PopupMenuThemeData` or
/// a `Card` takes an `elevation` and paints its own shadow, so the only place to
/// answer "which mode paints one" is the colour. Transparent in dark, because
/// the page there is at L\* 4.11 and the darkest ink available is L\* 1.18 —
/// under three L\* of headroom, so a Material shadow in dark is paint with
/// nowhere to land.
///
/// **This is the only channel allowed to depend on brightness, and that is the
/// point** (M100.35). The level travels unchanged in both modes; what varies is
/// whether the paint is visible. Until this milestone `overlayElevationFor`
/// answered the same question by returning `AppElevation.none` in dark, which
/// made the *semantic* depth of a FAB depend on the theme — a component saying
/// it is flush with the page in one mode and six dp above it in the other.
///
/// The SDK is what makes the separation safe, and it was read rather than
/// assumed: in Flutter 3.44.8 `Material` puts `elevation` through
/// `ElevationOverlay.applySurfaceTint`, which returns the colour untouched when
/// `surfaceTint` is null or transparent. `_CardDefaultsM3.surfaceTintColor` is
/// `Colors.transparent` and neither `_FABDefaultsM3` nor `_SnackbarDefaultsM3`
/// sets one, so a non-zero elevation has exactly one visual effect in this app
/// — the shadow — and suppressing the colour suppresses all of it.
Color materialShadowColor(ColorScheme scheme) =>
    scheme.brightness == Brightness.dark ? Colors.transparent : scheme.shadow;

/// The depth a [level] paints, in the mode's own idiom.
///
/// **Light draws Tokyo's two-layer shade** — see [_lightShadows], which carries
/// the shape and the reason the alpha stopped being a solved number.
///
/// **Dark cannot use a shade, and measured rather than assumed: the dark page
/// sits at L\* 4.11 and the darkest ink in the palette is L\* 1.18, so under
/// three L\* of headroom exists below it.** Material 3 drops the shadow in dark
/// for the same reason. What replaces it is [_darkDepth].
List<BoxShadow> shadowsFor(double level, ColorScheme scheme) {
  if (level <= AppElevation.none) return const <BoxShadow>[];
  if (scheme.brightness == Brightness.dark) return _darkDepth(level, scheme);

  return _lightShadows(level, scheme.shadow);
}

/// Dark depth: a crisp hairline, and above `card` a real drop.
///
/// **The rim used to glow, and that is what this replaces** (M100.35). It was
/// Tokyo's `shadows.card` taken literally — `#6A7199` at `blurRadius: 2` with a
/// `spreadRadius` that climbed 1 → 2 → 3 by level. Three things were wrong with
/// it, and only the third is a matter of taste:
///
/// * the colour reads **3.74:1 against the card it outlines**. That is the
///   contrast of a *control* boundary, not of a decorative one, so a resting
///   neutral card was wearing an edge as loud as a focus ring;
/// * the blur turned that edge into a halo, and a halo on a 16 or 20 px corner
///   is a smear rather than a corner;
/// * the spread grew with the level, so the way to say "higher" was "brighter
///   and thicker" — which on a phone, where ten cards stack in one column,
///   prints as neon stripes rather than as depth.
///
/// Tokyo is a desktop dashboard with three panels on a wide canvas; this is a
/// phone with a scrolling list. The effect did not survive the move, and the
/// exact blur and spread were never a contract — they were one implementation
/// of "dark needs an edge".
///
/// **What replaces it.** A **crisp** ring, one hairline wide, in
/// `outlineVariant` — M3's own role for a boundary that is decorative and
/// explicitly not required to reach 3:1. It measures **1.30:1 against the card
/// and 1.41:1 against the page**: present as an edge, absent as a glow. It is
/// painted as a zero-blur `BoxShadow` rather than as a `Border` on purpose —
/// the border box belongs to *state* (selection, option, focus), and a depth
/// cue that shared it would make one channel carry two facts again, which is
/// the defect M100.33 spent itself removing.
///
/// The ring never thickens. `raised` says "higher" with a **drop** instead —
/// `scheme.shadow` under the surface, offset and blurred, no spread, so nothing
/// lightens. It is quiet by arithmetic rather than by choice: at alpha 0.8 it
/// moves the page by ΔL\* 2.34, a little over half the 4.31 the page-to-card
/// surface step already carries. That is the whole budget dark has.
///
/// Selection and focus stay far louder than either, which is the property that
/// matters: `borderSelected` is 5.27:1 against the card and `borderOption`
/// 3.33:1, against the rim's 1.30:1.
List<BoxShadow> _darkDepth(double level, ColorScheme scheme) {
  final BoxShadow rim = BoxShadow(
    color: scheme.outlineVariant,
    spreadRadius: AppStroke.hairline,
  );
  if (level <= AppElevation.card) return <BoxShadow>[rim];

  // A switch and not a formula, for [_lightShadows]' reason: `overlay` has no
  // production caller, so its numbers are derived by doubling rather than
  // measured, and writing them out keeps that visible.
  final (double dropY, double dropBlur) = switch (level) {
    AppElevation.raised => (4, 12),
    _ => (8, 24),
  };

  return <BoxShadow>[
    rim,
    BoxShadow(
      color: scheme.shadow.withValues(alpha: _darkDropAlpha),
      blurRadius: dropBlur,
      offset: Offset(0, dropY),
    ),
  ];
}

/// **Two layers, and the second is not the one this file rejected** (M100.30).
///
/// Until now light drew one shadow, and the comment beside it turned down a
/// second: Material's *ambient* layer, "a full-size blur per surface" moving
/// the result by under half an L\* step. That rejection stands and is not what
/// Tokyo's second layer is. Tokyo pairs a wide float — `0 9px 16px` at 18% —
/// with a tight **contact** layer at `0 2px 2px` and 32%: a 2 px blur, not a
/// full-size one, and it moves the ground by 9.27 L\* rather than by half a
/// step. The float says the card is above the page; the contact says where it
/// touches. One layer can only say one of those, which is why a single tight
/// dark drop reads as a cut-out rather than as a panel.
///
/// **The two painting levels are Tokyo's two tiers, verbatim in dp.** Level
/// [AppElevation.card] is `shadows.cardSm` and level [AppElevation.raised] is
/// `shadows.card`; those are the only levels `MxCard` ever hands this function,
/// so neither is an interpolation. [AppElevation.overlay] has no production
/// caller — every overlay in the app states `elevation: 0` and separates itself
/// with a barrier, or takes Material's own shadow through
/// [materialShadowColor] — so it is derived by doubling `raised` rather than
/// measured, and it is written as a switch instead of a formula precisely so
/// that stays visible.
///
/// A formula would have had to extrapolate through both Tokyo tiers and lands
/// on a 48 px blur at level 8 — a value nobody chose, for a surface nobody
/// draws.
List<BoxShadow> _lightShadows(double level, Color shadow) {
  final (
    double floatY,
    double floatBlur,
    double seatY,
    double seatBlur,
  ) = switch (level) {
    AppElevation.card => (2, 3, 1, 1),
    AppElevation.raised => (9, 16, 2, 2),
    _ => (18, 32, 4, 4),
  };

  return <BoxShadow>[
    BoxShadow(
      color: shadow.withValues(alpha: _floatAlpha),
      blurRadius: floatBlur,
      offset: Offset(0, floatY),
    ),
    BoxShadow(
      color: shadow.withValues(alpha: _seatAlpha),
      blurRadius: seatBlur,
      offset: Offset(0, seatY),
    ),
  ];
}

/// The drop a dark surface casts, at the top of the range it can use.
///
/// Not a tuned number: `scheme.shadow` is L\* 1.18 against a page at 4.11, so
/// even a fully opaque drop moves the ground by ΔL\* 2.93. 0.8 spends most of
/// that (2.34) and keeps the falloff from banding on the blur.
const double _darkDropAlpha = 0.8;

/// Tokyo's own two alphas, and they do not climb with the level.
///
/// Depth is carried by how far the float travels and how wide it spreads, not
/// by how dark it gets — which is what keeps a raised card from reading as a
/// *darker* card. The old single layer climbed its alpha instead (`0.06 + 0.01
/// * level`), because with one tight layer that was the only handle it had.
const double _floatAlpha = 0.18;
const double _seatAlpha = 0.32;
