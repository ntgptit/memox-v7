import 'dart:io';

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
      expect(changed.accentInk, base.accentInk);
      expect(changed.dangerInk, base.dangerInk);
      expect(changed.successInk, base.successInk);
      expect(changed.warningInk, base.warningInk);
      expect(changed.secondaryInk, base.secondaryInk);
      expect(changed.tertiaryInk, base.tertiaryInk);
      expect(changed.inversePrimaryInk, base.inversePrimaryInk);
      expect(changed.surfaceMuted, base.surfaceMuted);
      expect(changed.borderSubtle, base.borderSubtle);
      expect(changed.surfaceEmphasis, base.surfaceEmphasis);
      expect(changed.disabledSurface, base.disabledSurface);
      expect(changed.onDisabled, base.onDisabled);
      expect(changed.mastery, base.mastery);
      expect(changed.statusNew, base.statusNew);
      expect(changed.statusLearning, base.statusLearning);
      expect(changed.statusReviewing, base.statusReviewing);
      expect(changed.statusMastered, base.statusMastered);
      expect(changed.errorFill, base.errorFill);
      expect(changed.onErrorFill, base.onErrorFill);
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
      expect(mid.accentInk, Color.lerp(light.accentInk, dark.accentInk, 0.5));
      expect(mid.dangerInk, Color.lerp(light.dangerInk, dark.dangerInk, 0.5));
      expect(
        mid.successInk,
        Color.lerp(light.successInk, dark.successInk, 0.5),
      );
      expect(
        mid.warningInk,
        Color.lerp(light.warningInk, dark.warningInk, 0.5),
      );
      expect(
        mid.secondaryInk,
        Color.lerp(light.secondaryInk, dark.secondaryInk, 0.5),
      );
      expect(
        mid.tertiaryInk,
        Color.lerp(light.tertiaryInk, dark.tertiaryInk, 0.5),
      );
      // inversePrimaryInk is not checked against light/dark here: GC-3 makes
      // it identical in both modes, so Color.lerp(x, x, 0.5) and a field that
      // snaps to `this` instead of interpolating are the same number — the
      // dedicated test below forces two different values instead.
      expect(
        mid.surfaceMuted,
        Color.lerp(light.surfaceMuted, dark.surfaceMuted, 0.5),
      );
      expect(
        mid.borderSubtle,
        Color.lerp(light.borderSubtle, dark.borderSubtle, 0.5),
      );
      expect(
        mid.surfaceEmphasis,
        Color.lerp(light.surfaceEmphasis, dark.surfaceEmphasis, 0.5),
      );
      expect(
        mid.disabledSurface,
        Color.lerp(light.disabledSurface, dark.disabledSurface, 0.5),
      );
      expect(
        mid.onDisabled,
        Color.lerp(light.onDisabled, dark.onDisabled, 0.5),
      );
      expect(mid.mastery, Color.lerp(light.mastery, dark.mastery, 0.5));
      expect(mid.statusNew, Color.lerp(light.statusNew, dark.statusNew, 0.5));
      expect(
        mid.statusLearning,
        Color.lerp(light.statusLearning, dark.statusLearning, 0.5),
      );
      expect(
        mid.statusReviewing,
        Color.lerp(light.statusReviewing, dark.statusReviewing, 0.5),
      );
      expect(
        mid.statusMastered,
        Color.lerp(light.statusMastered, dark.statusMastered, 0.5),
      );
      expect(mid.errorFill, Color.lerp(light.errorFill, dark.errorFill, 0.5));
      expect(
        mid.onErrorFill,
        Color.lerp(light.onErrorFill, dark.onErrorFill, 0.5),
      );
    });

    test('lerp interpolates inversePrimaryInk, which is identical in both '
        'modes', () {
      // light and dark carry the same inversePrimaryInk value (GC-3: its
      // one ground, inverseSurface, is theme-invariant too), so a
      // light-to-dark lerp can't tell a real blend from a field that snaps
      // to `this` — both read as the unchanged value. Force two instances
      // that actually differ so the assertion can fail.
      const light = AppSemanticColors.light();
      final variant = light.copyWith(
        inversePrimaryInk: const Color(0xFF000000),
      );

      expect(
        light.lerp(variant, 0.5).inversePrimaryInk,
        Color.lerp(light.inversePrimaryInk, variant.inversePrimaryInk, 0.5),
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
      //
      // v3 (GC-2, colors_and_type.css 2026-09-17) flattens over `surface`
      // (the page), not the card: `AppSurfaceColors.page*`, not `paper*`.
      expect(
        light.disabledSurface.toARGB32(),
        Color.alphaBlend(
          AppColors.textPrimaryLight.withValues(
            alpha: AppStateOpacity.disabledSurfaceBlend,
          ),
          AppSurfaceColors.pageLight,
        ).toARGB32(),
      );
      expect(
        dark.disabledSurface.toARGB32(),
        Color.alphaBlend(
          AppColors.textPrimaryDark.withValues(
            alpha: AppStateOpacity.disabledSurfaceBlend,
          ),
          AppSurfaceColors.pageDark,
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

  group('v3 MEMOX_SEMANTIC_COLOR — BIND_NOW', () {
    // docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.1.
    const AppSemanticColors light = AppSemanticColors.light();
    const AppSemanticColors dark = AppSemanticColors.dark();

    void pin(String name, Color l, Color d, int lightArgb, int darkArgb) {
      expect(l.toARGB32(), lightArgb, reason: '$name light');
      expect(d.toARGB32(), darkArgb, reason: '$name dark');
    }

    test('carry the registry values in both themes', () {
      pin('mastery', light.mastery, dark.mastery, 0xFF1F8A5B, 0xFF6FE0BD);
      pin(
        'status-new',
        light.statusNew,
        dark.statusNew,
        0xFF8C95B8,
        0xFF6B75A3,
      );
      pin(
        'status-learning',
        light.statusLearning,
        dark.statusLearning,
        0xFFF59E0B,
        0xFFFFC658,
      );
      pin(
        'status-reviewing',
        light.statusReviewing,
        dark.statusReviewing,
        0xFF5265F5,
        0xFF8B9AFF,
      );
      pin(
        'status-mastered',
        light.statusMastered,
        dark.statusMastered,
        0xFF1F8A5B,
        0xFF6FE0BD,
      );
      pin(
        'error-fill',
        light.errorFill,
        dark.errorFill,
        0xFFDC2D4E,
        0xFFB0485C,
      );
      pin(
        'on-error-fill',
        light.onErrorFill,
        dark.onErrorFill,
        0xFFFFFFFF,
        0xFFFFFFFF,
      );
    });

    test('copyWith and lerp carry the new fields', () {
      const Color probe = Color(0xFF000000);
      final AppSemanticColors changed = light.copyWith(errorFill: probe);
      expect(changed.errorFill, probe);
      expect(changed.mastery, light.mastery);

      final AppSemanticColors mid = light.lerp(dark, 0.5);
      for (final (Color got, Color a, Color b) in <(Color, Color, Color)>[
        (mid.mastery, light.mastery, dark.mastery),
        (mid.statusNew, light.statusNew, dark.statusNew),
        (mid.statusLearning, light.statusLearning, dark.statusLearning),
        (mid.statusReviewing, light.statusReviewing, dark.statusReviewing),
        (mid.statusMastered, light.statusMastered, dark.statusMastered),
        (mid.errorFill, light.errorFill, dark.errorFill),
        (mid.onErrorFill, light.onErrorFill, dark.onErrorFill),
      ]) {
        expect(got, Color.lerp(a, b, 0.5));
      }
    });

    test('no v3 M3_ALIAS gained a field of its own', () {
      // `surfaceMuted` is NOT on this list: it is a pre-#569 name collision
      // (it resolves to `surfaceContainer`), not v3's `surface-muted`.
      final String source = File(
        'lib/core/theme/foundations/app_semantic_colors.dart',
      ).readAsStringSync();
      for (final String alias in <String>[
        'bg',
        'surfaceRaised',
        'textSecondary',
      ]) {
        expect(source, isNot(contains('final Color $alias;')), reason: alias);
      }
    });
  });
}
