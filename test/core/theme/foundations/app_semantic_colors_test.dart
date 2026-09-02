import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_colors.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_surface_colors.dart';

/// Behaviour of the `ThemeExtension` itself — `copyWith` and `lerp`.
///
/// Split from `app_theme_test.dart`, which asserts colour *values* on a built
/// theme. Two different questions: "does the extension carry its fields
/// correctly" versus "is this palette legible".
void main() {
  group('AppSemanticColors', () {
    test('copyWith replaces only what it is given', () {
      const base = AppSemanticColors.light();
      final changed = base.copyWith(danger: const Color(0xFF123456));

      expect(changed.danger, const Color(0xFF123456));
      expect(changed.success, base.success);
      expect(changed.warning, base.warning);
      expect(changed.info, base.info);
      expect(changed.surfaceMuted, base.surfaceMuted);
      expect(changed.borderSubtle, base.borderSubtle);
      expect(changed.surfaceElevated, base.surfaceElevated);
      expect(changed.disabledSurface, base.disabledSurface);
      expect(changed.onDisabled, base.onDisabled);
    });

    test('lerp interpolates every field, not just some', () {
      const light = AppSemanticColors.light();
      const dark = AppSemanticColors.dark();
      final mid = light.lerp(dark, 0.5);

      // A field left out of lerp snaps during a theme change, and the snap is
      // visible only on the one screen that uses it. Comparing every field to
      // Color.lerp catches the omission wherever it is.
      expect(mid.success, Color.lerp(light.success, dark.success, 0.5));
      expect(mid.warning, Color.lerp(light.warning, dark.warning, 0.5));
      expect(mid.danger, Color.lerp(light.danger, dark.danger, 0.5));
      expect(mid.info, Color.lerp(light.info, dark.info, 0.5));
      expect(
        mid.surfaceMuted,
        Color.lerp(light.surfaceMuted, dark.surfaceMuted, 0.5),
      );
      expect(
        mid.borderSubtle,
        Color.lerp(light.borderSubtle, dark.borderSubtle, 0.5),
      );
      expect(
        mid.surfaceElevated,
        Color.lerp(light.surfaceElevated, dark.surfaceElevated, 0.5),
      );
      expect(
        mid.disabledSurface,
        Color.lerp(light.disabledSurface, dark.disabledSurface, 0.5),
      );
      expect(
        mid.onDisabled,
        Color.lerp(light.onDisabled, dark.onDisabled, 0.5),
      );
    });

    test('lerp at the endpoints returns the endpoints', () {
      const light = AppSemanticColors.light();
      const dark = AppSemanticColors.dark();

      expect(light.lerp(dark, 0).danger, light.danger);
      expect(light.lerp(dark, 1).danger, dark.danger);
    });

    test('lerp against a foreign extension keeps this one', () {
      const light = AppSemanticColors.light();

      expect(light.lerp(null, 0.5), same(light));
    });
  });

  group('the disabled pair', () {
    const light = AppSemanticColors.light();
    const dark = AppSemanticColors.dark();

    test('disabledSurface is the ink at 12%, already flattened', () {
      // The constants replaced a blend that ran at theme-build time, and this
      // pins them to the formula rather than to a hex somebody typed. It is
      // also what keeps them honest if the surface or the ink moves: a solid
      // that no longer equals its own derivation is a colour nobody chose.
      expect(
        light.disabledSurface.toARGB32(),
        Color.alphaBlend(
          AppColors.textPrimaryLight.withValues(
            alpha: AppStateOpacity.disabledSurfaceBlend,
          ),
          AppSurfaceColors.surfaceLight,
        ).toARGB32(),
      );
      expect(
        dark.disabledSurface.toARGB32(),
        Color.alphaBlend(
          AppColors.textPrimaryDark.withValues(
            alpha: AppStateOpacity.disabledSurfaceBlend,
          ),
          AppSurfaceColors.surfaceDark,
        ).toARGB32(),
      );
    });

    test('disabledSurface is opaque, so it cannot pick up its ground', () {
      // The whole point of precomputing (MX-VIS-002 R7). A translucent value
      // here renders as three colours depending on whether the control sits on
      // a page, a card or a sheet.
      expect(light.disabledSurface.a, 1);
      expect(dark.disabledSurface.a, 1);
    });

    test('onDisabled is the ink at 38%', () {
      // Compared as packed ARGB, which is the comparison that matters: the
      // constant is written as a literal because MX-VIS-002 R2 keeps colour
      // literals in `AppColors`, and a literal carries a byte alpha where
      // `withValues` carries a double. 97/255 and 0.38 are the same pixel.
      expect(
        light.onDisabled.toARGB32(),
        AppColors.textPrimaryLight
            .withValues(alpha: AppStateOpacity.disabledContent)
            .toARGB32(),
      );
      expect(
        dark.onDisabled.toARGB32(),
        AppColors.textPrimaryDark
            .withValues(alpha: AppStateOpacity.disabledContent)
            .toARGB32(),
      );
    });
  });
}
