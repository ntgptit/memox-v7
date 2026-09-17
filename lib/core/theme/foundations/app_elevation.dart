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

/// The depth a [level] paints, in the mode's own idiom — the v3 shadow tiers
/// declared as `--memox-shadow-soft` / `-card` / `-fab` in
/// `design_system/MemoX Design System/colors_and_type.css` (owner decision 6,
/// 2026-09-13; GC-6). `card` reads `soft`, `raised` reads `card`, `overlay`
/// reads `fab` — see [_Shadow]. Dark still cannot use a shade (M100.35: the
/// dark page sits at L\* 4.11 against a darkest ink of L\* 1.18, under three
/// L\* of headroom), so it takes [_darkDepth] instead.
List<BoxShadow> shadowsFor(double level, ColorScheme scheme) {
  if (level <= AppElevation.none) return const <BoxShadow>[];
  if (scheme.brightness == Brightness.dark) return _darkDepth(level, scheme);

  final _Shadow shade = switch (level) {
    AppElevation.card => _Shadow.soft,
    AppElevation.raised => _Shadow.card,
    _ => _Shadow.floating,
  };
  return <BoxShadow>[shade.paint(scheme.shadow, isDark: false)];
}

/// Dark depth: the hairline rim at every level, and above `card` the v3
/// block's own drop underneath it.
///
/// The rim is a crisp `outlineVariant` hairline, painted as a zero-blur
/// `BoxShadow` rather than a `Border` — the border box belongs to *state*
/// (selection, option, focus), and a depth cue that shared it would make one
/// channel carry two facts again (M100.33). `card` alone stays rim-only: the
/// dark block's `--memox-shadow-soft` is `none`, so [_Shadow.soft] is never
/// asked to paint dark.
List<BoxShadow> _darkDepth(double level, ColorScheme scheme) {
  final BoxShadow rim = BoxShadow(
    color: scheme.outlineVariant,
    spreadRadius: AppStroke.hairline,
  );
  if (level <= AppElevation.card) return <BoxShadow>[rim];

  final _Shadow drop = level <= AppElevation.raised
      ? _Shadow.card
      : _Shadow.floating;
  return <BoxShadow>[rim, drop.paint(scheme.shadow, isDark: true)];
}

/// One `--memox-shadow-*` pair per tier — its light rule and its dark-block
/// rule, both read from `colors_and_type.css` (owner decision 6, 2026-09-13;
/// GC-6). No spread on a drop; the rim in [_darkDepth] is the only shadow
/// that carries one.
enum _Shadow {
  /// `--memox-shadow-soft` — the card level: `0 1px 2px rgba(15,22,56,.04)`
  /// light, `none` dark.
  soft(
    lightY: 1,
    lightBlur: 2,
    lightAlpha: 0.04,
    darkY: 0,
    darkBlur: 0,
    darkAlpha: 0,
  ),

  /// `--memox-shadow-card` — the raised level: `0 12px 32px
  /// rgba(15,22,56,.10)` light, `0 16px 40px rgba(0,0,0,.42)` dark.
  card(
    lightY: 12,
    lightBlur: 32,
    lightAlpha: 0.10,
    darkY: 16,
    darkBlur: 40,
    darkAlpha: 0.42,
  ),

  /// `--memox-shadow-fab` — the overlay level: `0 8px 24px
  /// rgba(15,22,56,.12)` light, `0 10px 28px rgba(0,0,0,.5)` dark.
  floating(
    lightY: 8,
    lightBlur: 24,
    lightAlpha: 0.12,
    darkY: 10,
    darkBlur: 28,
    darkAlpha: 0.5,
  );

  const _Shadow({
    required this.lightY,
    required this.lightBlur,
    required this.lightAlpha,
    required this.darkY,
    required this.darkBlur,
    required this.darkAlpha,
  });

  final double lightY;
  final double lightBlur;
  final double lightAlpha;
  final double darkY;
  final double darkBlur;
  final double darkAlpha;

  /// This tier's [BoxShadow] at [shadow], picking the light or dark offset,
  /// blur and alpha for [isDark].
  BoxShadow paint(Color shadow, {required bool isDark}) => BoxShadow(
    color: shadow.withValues(alpha: isDark ? darkAlpha : lightAlpha),
    blurRadius: isDark ? darkBlur : lightBlur,
    offset: Offset(0, isDark ? darkY : lightY),
  );
}
