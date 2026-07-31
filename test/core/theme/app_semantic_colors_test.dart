import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';

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
      expect(changed.primaryAccent, base.primaryAccent);
      expect(changed.success, base.success);
      expect(changed.warning, base.warning);
      expect(changed.info, base.info);
      expect(changed.surfaceMuted, base.surfaceMuted);
      expect(changed.borderSubtle, base.borderSubtle);
      expect(changed.focusRing, base.focusRing);
      expect(changed.surfaceElevated, base.surfaceElevated);
      expect(changed.secondaryAction, base.secondaryAction);
    });

    test('lerp interpolates every field, not just some', () {
      const light = AppSemanticColors.light();
      const dark = AppSemanticColors.dark();
      final mid = light.lerp(dark, 0.5);

      // A field left out of lerp snaps during a theme change, and the snap is
      // visible only on the one screen that uses it. Comparing every field to
      // Color.lerp catches the omission wherever it is.
      expect(
        mid.primaryAccent,
        Color.lerp(light.primaryAccent, dark.primaryAccent, 0.5),
      );
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
      expect(mid.focusRing, Color.lerp(light.focusRing, dark.focusRing, 0.5));
      expect(
        mid.surfaceElevated,
        Color.lerp(light.surfaceElevated, dark.surfaceElevated, 0.5),
      );
      expect(
        mid.secondaryAction,
        Color.lerp(light.secondaryAction, dark.secondaryAction, 0.5),
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
}
