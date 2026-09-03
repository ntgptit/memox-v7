import 'package:flutter/material.dart';

import 'app_colors.dart';

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

/// Material elevation for the components that keep a dp value instead of
/// `elevation: 0` + `shadowsFor` — the FAB and the SnackBar, whose theme slots
/// have nowhere to put a hand-painted shadow.
///
/// Zero in dark, matching `shadowsFor`: the dark page is at the bottom of the
/// lightness scale, so a shadow there is paint nobody can see.
double overlayElevationFor(ColorScheme scheme) =>
    scheme.brightness == Brightness.dark
    ? AppElevation.none
    : AppElevation.overlay;

/// The shadow colour a **Material component** paints at a non-zero elevation.
///
/// [shadowsFor] is for surfaces this app draws itself; a `PopupMenuThemeData` or
/// a `Card` takes an `elevation` and paints its own shadow, so the only place to
/// answer "which mode paints one" is the colour. Transparent in dark, for the
/// measurement in [shadowsFor]'s comment and not for a second reason.
///
/// **The level still travels in both modes.** AD-14 keeps the scale and the
/// paint apart precisely so dark can opt out of shadows without opting out of
/// depth — a component that dropped to `elevation: 0` in dark would be saying
/// it is flush with what is behind it, which is not what dark means.
Color materialShadowColor(ColorScheme scheme) =>
    scheme.brightness == Brightness.dark ? Colors.transparent : scheme.shadow;

/// The shadow a [level] paints, given the theme's own shadow colour.
///
/// **This doc block had drifted onto [overlayElevationFor] at M100.29** — the
/// split that moved that function up put it between the comment and the
/// function it describes, and nothing objects to a doc comment landing on the
/// wrong declaration. Restored here, and rewritten, because what it said is no
/// longer true either.
///
/// **Empty in dark, and that is measured rather than assumed.** The dark page is
/// at L\* 3.86 — the bottom of the scale — so there is no room below it for a
/// shadow to occupy. At alpha 0.10 a dark shadow moves the page by **ΔL\* 0.26**;
/// at 0.70, still only 2.04. The surface step already there is ΔL\* 7.70. A dark
/// shadow is paint nobody can see, and Material 3 drops it for the same reason.
/// Dark draws Tokyo's rim instead — see the branch below.
///
/// **Light draws Tokyo's two-layer shade since M100.30, and the alpha stopped
/// being a solved number.** It used to be one layer whose opacity was fitted to
/// a target: `0.06 + 0.01 * level`, solved so a card's total lift off the page
/// matched dark's. That produced a *tight, near-black* drop — the right total,
/// with the wrong character, and the reason a card read as stamped out of the
/// page rather than laid on it. The lift is still measured, and still by
/// `app_theme_test.dart`; it is now a floor the shape has to clear rather than a
/// number the alpha was tuned to hit. [_lightShadows] carries the shape.
List<BoxShadow> shadowsFor(double level, ColorScheme scheme) {
  if (level <= AppElevation.none) return const <BoxShadow>[];
  // **Dark paints a rim, not a shade (M100.27).** The measurement above still
  // holds — a dark shadow moves the page by under one L* — and with the card
  // fixed at Tokyo's `#111633` on Tokyo's `#070C27` the surface step is 4.3
  // L*, below the 6 the ladder used to carry alone. Tokyo's own answer is its
  // `shadows.card`: `0px 0px 2px #6A7199`, a one-pixel halo that reads 4.07:1
  // against the page and 3.74:1 against the card. Same colour at every level —
  // an edge does not change hue with depth — but the ring **thickens**, which
  // is what carries `none < card < raised` in a mode with no shadow. See
  // `_darkRimSpread`.
  //
  // **`spreadRadius: 1` is what makes those two ratios true on screen.** A
  // blur alone rasterises the source colour into partially covered pixels, so
  // the exposed ring would measure below the source (review on #427). The
  // one-pixel spread paints a solid ring at the full colour before the 2 px
  // blur falls off outside it — the cue the ratios describe is the ring, and
  // `app_elevation_test.dart` pins the spread so the ring cannot quietly
  // become a wash again.
  if (scheme.brightness == Brightness.dark) {
    return <BoxShadow>[
      BoxShadow(
        color: AppColors.cardRimDark,
        blurRadius: 2,
        spreadRadius: _darkRimSpread(level),
      ),
    ];
  }

  return _lightShadows(level, scheme.shadow);
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

/// How thick the dark rim is drawn, by level.
///
/// **Dark needs this because it has no shadow to carry depth** (see above), and
/// until M100.33 it drew *the same* rim at every level — so `MxCard.raised` and
/// `MxCard.flat` printed the same box in dark, and the three depths the app
/// claims collapsed to two. The old workaround was worse than the symptom: the
/// card recipe resolved to a different `ColorScheme` role in dark than in
/// light, which makes a component's semantic identity depend on brightness.
///
/// **The ring thickens rather than the fill moving or a shade appearing.** Of
/// the three mechanisms available for dark depth — the surface-container
/// ladder, the rim, elevation rendering — the ladder is the one that would have
/// forced a per-brightness role, and a dark shade is paint nobody can see at
/// this page lightness. The rim is the one left, and a thicker edge reads as a
/// nearer object without any second colour entering the system.
///
/// Monotonic by construction, which is what makes `none < card < raised`
/// perceptible: 0 (no rim at all), then 1, then 2.
double _darkRimSpread(double level) => switch (level) {
  AppElevation.card => 1,
  AppElevation.raised => 2,
  _ => 3,
};

/// Tokyo's own two alphas, and they do not climb with the level.
///
/// Depth is carried by how far the float travels and how wide it spreads, not
/// by how dark it gets — which is what keeps a raised card from reading as a
/// *darker* card. The old single layer climbed its alpha instead (`0.06 + 0.01
/// * level`), because with one tight layer that was the only handle it had.
const double _floatAlpha = 0.18;
const double _seatAlpha = 0.32;
