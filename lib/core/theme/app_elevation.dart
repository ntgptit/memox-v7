import 'package:flutter/material.dart';

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

  /// A surface deliberately lifted above its neighbours — a selected card, a
  /// dragged item. Nothing uses it yet; it exists so the next caller does not
  /// invent a number.
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
/// Light is the opposite, and the alpha was **solved for rather than picked**.
/// Dark separates a card from its page by ΔL\* 7.70 on the surface step alone.
/// Light's surface step is only 3.46, so the shadow has to make up 4.24 — which
/// lands at alpha **0.05**, giving 7.62 against dark's 7.70. The first draft used
/// 0.12 and overshot to 13.28, making light cards float where dark's sit.
///
/// **So the modes stay symmetric in the thing that matters.** They are no longer
/// matched on *border contrast* — light's border is now the lighter of the two —
/// but on how far a card is lifted off the page in total. That is what
/// `app_theme_test.dart` pins, and it is what a reader perceives.
List<BoxShadow> shadowsFor(double level, ColorScheme scheme) {
  if (level <= AppElevation.none) return const <BoxShadow>[];
  if (scheme.brightness == Brightness.dark) return const <BoxShadow>[];

  // One shadow, not Material's two. The second is an ambient wash that costs a
  // full-size blur per surface and, at level 1, moves the result by under half
  // an L\* step — measurable, not visible, and a list of twenty cards pays for
  // it twenty times.
  return <BoxShadow>[
    BoxShadow(
      color: scheme.shadow.withValues(alpha: 0.04 + 0.01 * level),
      blurRadius: level * 3,
      offset: Offset(0, level),
    ),
  ];
}
