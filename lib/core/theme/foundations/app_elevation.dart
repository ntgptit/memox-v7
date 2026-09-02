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

/// The shadow a [level] paints, given the theme's own shadow colour.
///
/// **Empty in dark, and that is measured rather than assumed.** The dark page is
/// at L\* 3.86 — the bottom of the scale — so there is no room below it for a
/// shadow to occupy. At alpha 0.10 a dark shadow moves the page by **ΔL\* 0.26**;
/// at 0.70, still only 2.04. The surface step already there is ΔL\* 7.70. A dark
/// shadow is paint nobody can see, and Material 3 drops it for the same reason.
///
/// Light is the opposite, and the alpha is **solved for rather than picked**.
/// Dark separates a card from its page by ΔL\* 7.70 on the surface step alone.
/// Light's step is 2.15 once the card carries a seed tint, so the shadow has to
/// make up 5.6 — alpha **0.07**, giving 7.75. It has been re-solved twice: 0.12
/// overshot to 13.28, and 0.05 was right only while the card was pure white and
/// its step was 3.46.
///
/// **So the modes stay symmetric in the thing that matters.** They are no longer
/// matched on *border contrast* — light's border is now the lighter of the two —
/// but on how far a card is lifted off the page in total. That is what
/// `app_theme_test.dart` pins, and it is what a reader perceives.
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

List<BoxShadow> shadowsFor(double level, ColorScheme scheme) {
  if (level <= AppElevation.none) return const <BoxShadow>[];
  // **Dark paints a rim, not a shade (M100.27).** The measurement above still
  // holds — a dark shadow moves the page by under one L* — and with the card
  // fixed at Tokyo's `#111633` on Tokyo's `#070C27` the surface step is 4.3
  // L*, below the 6 the ladder used to carry alone. Tokyo's own answer is its
  // `shadows.card`: `0px 0px 2px #6A7199`, a one-pixel halo that reads 4.07:1
  // against the page and 3.74:1 against the card. Same colour at every level:
  // a halo is an edge, and an edge does not get deeper.
  //
  // **`spreadRadius: 1` is what makes those two ratios true on screen.** A
  // blur alone rasterises the source colour into partially covered pixels, so
  // the exposed ring would measure below the source (review on #427). The
  // one-pixel spread paints a solid ring at the full colour before the 2 px
  // blur falls off outside it — the cue the ratios describe is the ring, and
  // `app_elevation_test.dart` pins the spread so the ring cannot quietly
  // become a wash again.
  if (scheme.brightness == Brightness.dark) {
    return const <BoxShadow>[
      BoxShadow(color: AppColors.cardRimDark, blurRadius: 2, spreadRadius: 1),
    ];
  }

  // One shadow, not Material's two. The second is an ambient wash that costs a
  // full-size blur per surface and, at level 1, moves the result by under half
  // an L\* step — measurable, not visible, and a list of twenty cards pays for
  // it twenty times.
  return <BoxShadow>[
    BoxShadow(
      color: scheme.shadow.withValues(alpha: 0.06 + 0.01 * level),
      blurRadius: level * 3,
      offset: Offset(0, level),
    ),
  ];
}
