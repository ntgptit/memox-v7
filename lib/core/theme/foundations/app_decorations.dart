import 'package:flutter/material.dart';

import 'app_stroke.dart';

/// One CSS `box-shadow` rule for one brightness — an offset, a blur and an
/// alpha over `ColorScheme.shadow` — transcribed verbatim from
/// `colors_and_type.css`. A record rather than a class: there is no
/// behaviour here, only four numbers that belong together.
typedef _ShadowRule = ({double y, double blur, double alpha});

/// v3's `DECORATION` treatments, by their registry name — see
/// `docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md` §5.4.
///
/// **The theme owns these values; a component's own contract owns which one
/// it wears, in which state.** `shadowsFor` (`app_elevation.dart`) is the one
/// place that still maps an elevation *level* to a treatment, and it now
/// calls these by name instead of hiding them in a private enum — the
/// mapping is unchanged, only the values got names a spec row can be checked
/// against.
///
/// [cardWhisperShadow], [overlayShadow] and [fabShadow] are the three shadows
/// this app already paints, under their v3 names. [chromeShadow] is the
/// fourth — `shadow-chrome` — new in this task: no elevation level wears it
/// yet, because giving BottomSheet its own chrome is a component contract's
/// decision, not this file's (COMPONENT_MIGRATION_PENDING). [hairlineEdge] is
/// the registry's one non-shadow entry, `border-ghost`.
abstract final class AppDecorations {
  /// `--memox-shadow-soft` — the card's light edge: `0 1px 2px
  /// rgba(15,22,56,.04)`. The registry states dark as `none`, so unlike the
  /// other three shadows here this returns nothing in dark — the dark card
  /// still reads as a step, but that is `app_elevation.dart`'s hairline rim,
  /// not this treatment.
  static List<BoxShadow> cardWhisperShadow(ColorScheme scheme) {
    if (scheme.brightness == Brightness.dark) return const <BoxShadow>[];
    return <BoxShadow>[_paint(scheme.shadow, _cardWhisperShadowLight)];
  }

  /// `--memox-shadow-card` — the Dialog's elevation. **Not the Card's**: v3
  /// names each tier for the surface that actually wears it today.
  static List<BoxShadow> overlayShadow(ColorScheme scheme) => <BoxShadow>[
    _paint(
      scheme.shadow,
      scheme.brightness == Brightness.dark
          ? _overlayShadowDark
          : _overlayShadowLight,
    ),
  ];

  /// `--memox-shadow-chrome` — casts upward, for a surface anchored to the
  /// bottom of the screen.
  static List<BoxShadow> chromeShadow(ColorScheme scheme) => <BoxShadow>[
    _paint(
      scheme.shadow,
      scheme.brightness == Brightness.dark
          ? _chromeShadowDark
          : _chromeShadowLight,
    ),
  ];

  /// `--memox-shadow-fab`.
  static List<BoxShadow> fabShadow(ColorScheme scheme) => <BoxShadow>[
    _paint(
      scheme.shadow,
      scheme.brightness == Brightness.dark ? _fabShadowDark : _fabShadowLight,
    ),
  ];

  /// `border-ghost` — `primary` at 14% light / 16% dark, one
  /// [AppStroke.hairline] wide. The registry states the colour directly as
  /// `rgba(82,101,245,.14)` / `rgba(139,154,255,.16)`, which **is** primary at
  /// those alphas rather than a colour of its own.
  ///
  /// **Translucent on purpose, the same argument a shadow already gets.** A
  /// token factory in `foundations/` cannot know which surface a component
  /// will eventually draw this edge over, so it cannot precompute a solid
  /// colour the way a fill with a known ground must (rule R7). The exemption
  /// `color_rule_scope.dart` already carries for `app_elevation.dart` now
  /// also names this file, for the same reason extended to a border instead
  /// of a shadow.
  static BorderSide hairlineEdge(ColorScheme scheme) => BorderSide(
    color: scheme.primary.withValues(
      alpha: scheme.brightness == Brightness.dark
          ? _hairlineEdgeDarkAlpha
          : _hairlineEdgeLightAlpha,
    ),
    // Stated rather than defaulted, and the redundancy is the point: the
    // width is one *because the stroke scale says a hairline is one*, not
    // because `BorderSide` happens to agree today (see `app_card_theme.dart`).
    // ignore: avoid_redundant_argument_values
    width: AppStroke.hairline,
  );

  static BoxShadow _paint(Color shadow, _ShadowRule rule) => BoxShadow(
    color: shadow.withValues(alpha: rule.alpha),
    blurRadius: rule.blur,
    offset: Offset(0, rule.y),
  );
}

const _ShadowRule _cardWhisperShadowLight = (y: 1, blur: 2, alpha: 0.04);

const _ShadowRule _overlayShadowLight = (y: 12, blur: 32, alpha: 0.10);
const _ShadowRule _overlayShadowDark = (y: 16, blur: 40, alpha: 0.42);

const _ShadowRule _chromeShadowLight = (y: -2, blur: 12, alpha: 0.05);
const _ShadowRule _chromeShadowDark = (y: -2, blur: 14, alpha: 0.36);

const _ShadowRule _fabShadowLight = (y: 8, blur: 24, alpha: 0.12);
const _ShadowRule _fabShadowDark = (y: 10, blur: 28, alpha: 0.5);

const double _hairlineEdgeLightAlpha = 0.14;
const double _hairlineEdgeDarkAlpha = 0.16;
