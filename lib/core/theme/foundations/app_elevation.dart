import 'package:flutter/material.dart';

import 'app_decorations.dart';
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

/// The depth a [level] paints, in the mode's own idiom — [AppDecorations]'
/// v3 shadow treatments, borrowed under **the level's mapping, not the
/// treatment's name**: `card` wears `cardWhisperShadow`, `raised` wears
/// `overlayShadow` and `overlay` wears `fabShadow` (owner decision 6,
/// 2026-09-13; GC-6), because that is what this app already paints today —
/// not because the names match. Whether `raised` should someday wear a
/// treatment actually called "raised" is a component contract's decision,
/// deferred; this function only names the values that call will choose
/// between. Dark still cannot use a shade (M100.35: the dark page sits at
/// L\* 4.11 against a darkest ink of L\* 1.18, under three L\* of headroom),
/// so it takes [_darkDepth] instead.
List<BoxShadow> shadowsFor(double level, ColorScheme scheme) {
  if (level <= AppElevation.none) return const <BoxShadow>[];
  if (scheme.brightness == Brightness.dark) return _darkDepth(level, scheme);

  return switch (level) {
    AppElevation.card => AppDecorations.cardWhisperShadow(scheme),
    AppElevation.raised => AppDecorations.overlayShadow(scheme),
    _ => AppDecorations.fabShadow(scheme),
  };
}

/// Dark depth: the hairline rim at every level, and above `card` the v3
/// block's own drop underneath it.
///
/// The rim is a `border-ghost` hairline — `AppDecorations.hairlineEdge`, the
/// role v3 names for this edge (M100.99). It was a crisp `outlineVariant`;
/// `primary` at 16% over the card's `#131A3A` composites to `#262E5A`, which
/// is 1.31:1 against that fill, so the rim is now a suggestion rather than a
/// line. It is painted as a zero-blur `BoxShadow` rather than a `Border` — the border box belongs to *state*
/// (selection, option, focus), and a depth cue that shared it would make one
/// channel carry two facts again (M100.33). `card` alone stays rim-only: the
/// dark block's `--memox-shadow-soft` is `none`, so
/// [AppDecorations.cardWhisperShadow] is never asked to paint dark here.
List<BoxShadow> _darkDepth(double level, ColorScheme scheme) {
  final BoxShadow rim = BoxShadow(
    color: AppDecorations.hairlineEdge(scheme).color,
    spreadRadius: AppStroke.hairline,
  );
  if (level <= AppElevation.card) return <BoxShadow>[rim];

  final BoxShadow drop = level <= AppElevation.raised
      ? AppDecorations.overlayShadow(scheme).single
      : AppDecorations.fabShadow(scheme).single;
  return <BoxShadow>[rim, drop];
}
