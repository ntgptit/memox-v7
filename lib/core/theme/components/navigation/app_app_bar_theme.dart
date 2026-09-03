import 'package:flutter/material.dart';

/// The top bar on every screen.
///
/// **The page colour, not a surface, and that is the whole decision.**
/// Material 3 would tint the bar with `surfaceContainer` and raise it on
/// scroll; this app paints it the same ground the content sits on, so the
/// chrome reads as one frame rather than as a panel stacked on the page.
///
/// `background` is a parameter because the scheme has no role for the page
/// ground — `surface` is the card sitting on it. See `app_theme.dart`.
AppBarTheme buildAppBarTheme(
  ColorScheme scheme, {
  required Color background,
}) => AppBarTheme(
  backgroundColor: background,
  foregroundColor: scheme.onSurface,
  // No tint on scroll: during a study session the header must stay still, because
  // a colour shift behind the card reads as the card itself changing.
  scrolledUnderElevation: 0,
  elevation: 0,
  centerTitle: false,
);
