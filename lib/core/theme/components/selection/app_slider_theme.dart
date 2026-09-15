import 'package:flutter/material.dart';

import '../../foundations/app_semantic_colors.dart';
import '../../states/app_interaction_states.dart';

/// The slider — `CLAUDE.md` names SM-2 parameters as deliberately deferred, and
/// a bounded numeric parameter is what a slider is for.
///
/// **`primary` on `secondaryContainer` — M3's own pairing, in both halves.**
///
/// The active half is worth its history, because it is the case this whole
/// palette line was argued from. It was a substitute token for a while:
/// measured against `secondaryContainer`, `primary` scored **6.02:1 in light
/// and 2.11:1 in dark**, under the 3:1 a slider's value needs, because
/// `primaryDark` was a fill tone held between the surfaces and the text and
/// *no* neutral in the dark palette reached 3:1 from it.
///
/// M100.18 fixed the role instead of the component: `primary` against
/// `secondaryContainer` now reads **6.02:1 light and 7.31:1 dark**, and against
/// the card behind it 7.27:1 and 10.02:1. Both halves keep M3's role, which is
/// the whole point of moving the palette rather than the component.
///
/// **This reverses the argument this file first shipped**, which was that a
/// slider is pressable so it takes the accent while a progress bar does not.
/// The premise is still right — a slider is a control — but pressability is
/// carried by the thumb, not by the hue. The hue had a contrast job `primary`
/// could not do on a dark card, and the answer was to give `primary` a tone
/// that can.
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
  // White on the filled track: 7.66:1 in light, 3.09:1 in dark. The dark
  // figure is the tightest number in this file and it clears the graphic
  // floor, which is the right floor — a tick is a mark on a track, not text.
  activeTickMarkColor: scheme.onPrimary,
  inactiveTickMarkColor: scheme.onSecondaryContainer,
  overlayColor: scheme.primary.withValues(alpha: AppStateOpacity.pressed),
  valueIndicatorColor: scheme.inverseSurface,
  valueIndicatorTextStyle: texts.labelMedium?.copyWith(
    color: scheme.onInverseSurface,
  ),
);
