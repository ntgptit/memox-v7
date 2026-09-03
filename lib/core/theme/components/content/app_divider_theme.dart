import 'package:flutter/material.dart';

import '../../foundations/app_stroke.dart';

/// Hairlines between rows.
///
/// The same token a card's border uses, because they are the same idea at
/// different scales — a divider that disagreed with a card outline would make
/// one list look like two.
/// `space` equals `thickness`, so a divider occupies exactly the line it draws
/// and adds no padding of its own — Material's default reserves 16.
DividerThemeData buildDividerTheme(ColorScheme scheme) => DividerThemeData(
  // `outlineVariant` is M3's name for the decorative hairline, and it *is*
  // `borderSubtle` — the scheme maps the two onto one value. Reading it
  // through the role rather than the extension is what makes that true by
  // construction instead of by coincidence (M100.20).
  color: scheme.outlineVariant,
  thickness: AppStroke.hairline,
  space: AppStroke.hairline,
);
