import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Every line the app draws around or inside a component — the Tokyo
/// handoff's (M100.87).
///
/// **The hairline and the control edge are the kit's hex verbatim, and the
/// control edge is recorded where it falls short.** `outlineVariant` is the
/// decorative hairline on cards, dividers and a resting chip; `outline` is the
/// edge of something a finger acts on — a text field, an outlined button, a
/// switch's resting thumb. The owner accepted (2026-09-13) that `outline` sits
/// under WCAG 1.4.11's 3:1 on the higher rungs: light 2.92 on a dialog or sheet
/// and 2.74 on a switch track; dark 2.65 on `surfaceContainer`, 2.25 on a
/// dialog and 1.96 on a switch track. `control_border_grounds_test.dart` pins
/// those figures as floors, so they record a decision rather than drift.
abstract final class AppBorderColors {
  /// The hairline — `outlineVariant`. 1.61:1 on a light card, 1.42:1 on a dark
  /// one: present as an edge, absent as a frame.
  static const Color borderSubtleLight = Color(0xFFC5CBE3);
  static const Color borderSubtleDark = Color(0xFF2A3267);

  /// A control's edge — `outline`. 3.62:1 on the light card and 3.44 on the
  /// page; 3.36 and 3.75 in dark.
  static const Color borderControlLight = Color(0xFF7C85AB);
  static const Color borderControlDark = Color(0xFF5A6BAE);

  /// The edge a picked card or option wears — the brand, which is what the kit
  /// draws around a selected answer or match tile.
  static const Color borderSelectedLight = AppColors.primaryLight;
  static const Color borderSelectedDark = AppColors.primaryDark;

  /// The resting edge of a selectable card (`MxCard.option`) — the control
  /// edge, because an option *is* a control.
  static const Color borderOptionLight = borderControlLight;
  static const Color borderOptionDark = borderControlDark;

  /// The hairline a panel wears when it is the screen's answer rather than one
  /// row among many — the brand at 38% over the paper, resolved here rather
  /// than at paint time (MX-VIS-002 R7).
  static const Color borderAccentLight = Color(0xFFBDC4FB);
  static const Color borderAccentDark = Color(0xFF414B85);
}
