import 'package:flutter/material.dart';

import '../foundations/app_radius.dart';

/// The safety net for a bare or third-party `Card` — no app widget renders
/// one. `MxCard` is the canonical card and paints itself, because its
/// focus-ring border swap and `shadowsFor` depth have no `CardThemeData`
/// slot; this keeps an untended `Card` on the same surface, radius and
/// hairline instead of Material's elevated default.
CardThemeData buildCardTheme(ColorScheme scheme) => CardThemeData(
  color: scheme.surface,
  elevation: 0,
  margin: EdgeInsets.zero,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    side: BorderSide(color: scheme.outlineVariant),
  ),
);
