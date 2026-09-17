import 'package:flutter/material.dart';

import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_stroke.dart';
import '../../states/app_interaction_states.dart';

/// The tab bar — the card detail screen's deferred *History* view, which
/// `docs/wbs.md` records as blocked on a study-answers screen rather than on a
/// design.
///
/// **The selected label is the brand's ink, and the indicator its fill**
/// (GC-3, 2026-09-17). A tab's label is text on the page or a card, and v3's
/// light `primary` fails 4.5:1 there, so the label takes
/// `AppSemanticColors.accentInk` while the indicator — a graphic — keeps the
/// canonical `primary`.
TabBarThemeData buildTabBarTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => TabBarThemeData(
  labelColor: semantic.accentInk,
  unselectedLabelColor: scheme.onSurfaceVariant,
  labelStyle: texts.titleSmall,
  unselectedLabelStyle: texts.titleSmall,
  indicatorColor: scheme.primary,
  indicatorSize: TabBarIndicatorSize.tab,
  // The hairline under the whole bar, which is the same line every other band
  // in the app is separated by.
  dividerColor: scheme.outlineVariant,
  dividerHeight: AppStroke.hairline,
  overlayColor: AppInteractionStates.controlOverlay(scheme),
);
