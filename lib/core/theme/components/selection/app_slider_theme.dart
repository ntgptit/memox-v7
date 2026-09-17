import 'package:flutter/material.dart';

import '../../foundations/app_semantic_colors.dart';
import '../../states/app_interaction_states.dart';

/// The slider — `CLAUDE.md` names SM-2 parameters as deliberately deferred, and
/// a bounded numeric parameter is what a slider is for.
///
/// **`primary` on `secondaryContainer` — M3's own pairing, in both halves.**
/// The binding survives every palette move (v3 foundations ruling R1); only
/// the hex behind each role changes, so per-palette contrast figures are not
/// pinned here — git keeps that history — and a component spec re-measures
/// them if it ever changes the pairing itself.
///
/// **This reverses the argument this file first shipped**, which was that a
/// slider is pressable so it takes the accent while a progress bar does not.
/// The premise is still right — a slider is a control — but pressability is
/// carried by the thumb, not by the hue.
///
/// The value indicator takes the inverse pair — the same surface a snack bar
/// uses, and for the same reason: it is a momentary overlay that has to read
/// against whatever it covers.
SliderThemeData buildSliderTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => SliderThemeData(
  // **One Material generation, stated** (A20.1 P2-06). The colours below are
  // the 2024 palette's slots, and with `year2023` unset `slider.dart:834`
  // resolves `_SliderDefaultsM3Year2023` for everything this theme does not
  // declare — geometry included — so the slider was split across two
  // generations. `false` selects the 2024 defaults the colours belong to.
  // The flag is marked deprecated *because* its default is changing to
  // `false`; until it does, stating `false` is the SDK's own instruction.
  // ignore: deprecated_member_use
  year2023: false,
  activeTrackColor: scheme.primary,
  // `secondaryContainer` is M3's, and it is also the one neutral fill in this
  // palette that is not already a surface tier — so the inactive half cannot be
  // mistaken for the card behind it.
  inactiveTrackColor: scheme.secondaryContainer,
  thumbColor: scheme.primary,
  disabledActiveTrackColor: semantic.disabledSurface,
  disabledInactiveTrackColor: semantic.disabledSurface,
  disabledThumbColor: semantic.disabledSurface,
  // `onPrimary` on the filled track — a tick is a mark on a track, not text,
  // so it only needs the graphic floor, not 4.5:1.
  activeTickMarkColor: scheme.onPrimary,
  inactiveTickMarkColor: scheme.onSecondaryContainer,
  overlayColor: scheme.primary.withValues(alpha: AppStateOpacity.pressed),
  valueIndicatorColor: scheme.inverseSurface,
  valueIndicatorTextStyle: texts.labelMedium?.copyWith(
    color: scheme.onInverseSurface,
  ),
);
