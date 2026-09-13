import 'package:flutter/material.dart';

import 'app_stroke.dart';

/// How far a surface sits above the one behind it.
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

  /// A sheet, a dialog or a floating action over the whole screen.
  static const double overlay = 8;

  /// Every level, for the test that checks the scale climbs.
  static const List<double> scale = <double>[none, card, raised, overlay];
}

/// The shadow colour a **Material component** paints at a non-zero elevation.
///
/// [shadowsFor] is for surfaces this app draws itself; a `PopupMenuThemeData`
/// or a `Card` takes an `elevation` and paints its own shadow, so the only
/// place to answer "which mode paints one" is the colour. Transparent in dark:
/// the handoff's dark card separates by a hairline, not a shade.
///
/// **This is the only channel allowed to depend on brightness** (M100.35). The
/// level travels unchanged in both modes; what varies is whether the paint is
/// visible. In Flutter 3.44.8 `Material` puts `elevation` through
/// `ElevationOverlay.applySurfaceTint`, which returns the colour untouched when
/// `surfaceTint` is null or transparent, so a non-zero elevation has exactly one
/// visual effect here — the shadow — and suppressing the colour suppresses all
/// of it.
Color materialShadowColor(ColorScheme scheme) =>
    scheme.brightness == Brightness.dark ? Colors.transparent : scheme.shadow;

/// The depth a [level] paints — the Tokyo handoff's shadows, one per level
/// (M100.87).
///
/// The handoff states three, in two places: its Card spec gives a card in a
/// list `shadow-soft`, and its Foundations give a lifted surface `shadow-card`
/// and a floating one `shadow-fab`. Each level takes one of them verbatim, so
/// no number here is interpolated or chosen:
///
/// | level | light | dark |
/// |---|---|---|
/// | [AppElevation.card] | `0 1px 2px` @ 4% | hairline rim only |
/// | [AppElevation.raised] | `0 12px 32px` @ 10% | rim + `0 16px 40px` @ 42% |
/// | [AppElevation.overlay] | `0 8px 24px` @ 12% | rim + `0 10px 28px` @ 50% |
///
/// **Dark's card is a rim, not a shade**, as the Card spec says: "the dark
/// surface ladder is too near-adjacent for a shadow alone to separate the
/// card". The rim is a crisp `outlineVariant` hairline painted as a zero-blur
/// `BoxShadow` rather than a `Border`, because the border box belongs to
/// *state* — selection, option, focus — and a depth cue sharing it would make
/// one channel carry two facts (M100.33).
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

/// Dark depth: the hairline rim at every level, and above `card` the
/// handoff's own dark drop underneath it.
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

/// The handoff's named shadows, as geometry and alpha per mode.
enum _Shadow {
  /// `shadow-soft` — the Card spec's list card. Light only; dark has a rim.
  soft(
    lightY: 1,
    lightBlur: 2,
    lightAlpha: 0.04,
    darkY: 0,
    darkBlur: 0,
    darkAlpha: 0,
  ),

  /// `shadow-card` — a lifted surface.
  card(
    lightY: 12,
    lightBlur: 32,
    lightAlpha: 0.10,
    darkY: 16,
    darkBlur: 40,
    darkAlpha: 0.42,
  ),

  /// `shadow-fab` — a floating surface.
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

  BoxShadow paint(Color shadow, {required bool isDark}) => BoxShadow(
    color: shadow.withValues(alpha: isDark ? darkAlpha : lightAlpha),
    blurRadius: isDark ? darkBlur : lightBlur,
    offset: Offset(0, isDark ? darkY : lightY),
  );
}
