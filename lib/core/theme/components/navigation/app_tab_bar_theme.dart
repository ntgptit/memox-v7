import 'package:flutter/material.dart';

import '../../foundations/app_stroke.dart';
import '../../states/app_interaction_states.dart';

/// The tab bar — the card detail screen's deferred *History* view, which
/// `docs/wbs.md` records as blocked on a study-answers screen rather than on a
/// design.
///
/// **`primary` for the selected label, which is M3's own answer and was not
/// available until M100.18.** A tab's label sits on the page or a card, not on a
/// selection fill, so it wants the brand hue as a label — and the old dark fill
/// tone could not be one, at 3.33:1 on the page against the 4.5:1 text needs. A
/// separate accent token carried it until the palette inverted; `primary` now
/// measures 11.36:1 there.
TabBarThemeData buildTabBarTheme(
  ColorScheme scheme,
  TextTheme texts,
) => TabBarThemeData(
  labelColor: scheme.primary,
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
