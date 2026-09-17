import 'package:flutter/material.dart';

import 'app_effects.dart';

/// The v3 registry's `DERIVED_COLOR` entries with runtime disposition
/// `BIND_NOW`, each derived exactly once, here, from the scheme it is handed
/// (docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.3).
///
/// A consumer applies no percentage of its own — its treatment is
/// `FULL_STRENGTH`. Deriving from the scheme rather than from constants is
/// what keeps high contrast and any future palette consistent without a second
/// edit.
///
/// **The PRESERVE_ONLY derivations are absent on purpose** — `primary-soft`,
/// `primary-border`, `danger-border`, `success-soft`, `warning-soft`. Three
/// components that look like `primary-soft` each tint `primary` at their own
/// percentage; they bind `primary` with a component treatment instead.
abstract final class AppDerivedColors {
  /// `danger-soft` — ErrorState's tile. `error` over transparent.
  static Color dangerSoft(ColorScheme scheme) => scheme.error.withValues(
    alpha: _isDark(scheme) ? _dangerSoftDarkAlpha : _dangerSoftLightAlpha,
  );

  /// `surface-hero` — the tinted hero card. **The base differs by theme:**
  /// `primary` 5% over `surfaceBright` in light, 12% over `surface` in dark.
  static Color surfaceHero(ColorScheme scheme) {
    if (_isDark(scheme)) {
      return Color.alphaBlend(
        scheme.primary.withValues(alpha: _heroDarkAlpha),
        scheme.surface,
      );
    }

    return Color.alphaBlend(
      scheme.primary.withValues(alpha: _heroLightAlpha),
      scheme.surfaceBright,
    );
  }

  /// `chrome-glass` — the bottom navigation bar's surface: `surface` at
  /// [AppEffects.glassOpacity]. Returned translucent so it composites at paint
  /// time over whatever is behind it; never pre-flatten it against a page.
  static Color chromeGlass(ColorScheme scheme) =>
      scheme.surface.withValues(alpha: AppEffects.glassOpacity);

  static bool _isDark(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark;
}

const double _dangerSoftLightAlpha = 0.08;
const double _dangerSoftDarkAlpha = 0.16;
const double _heroLightAlpha = 0.05;
const double _heroDarkAlpha = 0.12;
