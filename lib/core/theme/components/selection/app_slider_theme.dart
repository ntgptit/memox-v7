import 'package:flutter/material.dart';

import '../../foundations/app_semantic_colors.dart';
import '../../states/app_interaction_states.dart';

/// The slider — the handoff Slider (D), drawn by `MxSlider` since M100.92.
///
/// **`primary` on `surfaceContainerHighest`.** The handoff moves the empty
/// half off M3's `secondaryContainer` onto the resting fill the switch track
/// takes, and the two halves still clear 3:1 against each other in both modes
/// (`app_unrendered_component_themes_test.dart`).
///
/// The active half is worth its history. It was a substitute token for a
/// while, because `primaryDark` was a fill tone no neutral in the dark palette
/// reached 3:1 from. M100.18 fixed the role instead of the component, and the
/// slider has drawn `primary` since.
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
  // The handoff's empty half: the switch's resting fill (M100.92).
  inactiveTrackColor: scheme.surfaceContainerHighest,
  thumbColor: scheme.primary,
  disabledActiveTrackColor: semantic.disabledSurface,
  disabledInactiveTrackColor: semantic.disabledSurface,
  disabledThumbColor: semantic.disabledSurface,
  // White on the filled track: 7.66:1 in light, 3.09:1 in dark. The dark
  // figure is the tightest number in this file and it clears the graphic
  // floor, which is the right floor — a tick is a mark on a track, not text.
  activeTickMarkColor: scheme.onPrimary,
  inactiveTickMarkColor: scheme.onSurfaceVariant,
  overlayColor: scheme.primary.withValues(alpha: AppStateOpacity.pressed),
  valueIndicatorColor: scheme.inverseSurface,
  valueIndicatorTextStyle: texts.labelMedium?.copyWith(
    color: scheme.onInverseSurface,
  ),
);
