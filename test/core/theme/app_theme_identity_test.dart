import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/components/app_button_themes.dart';
import 'package:memox/core/theme/schemes/app_compact_scale.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

/// **A theme is only as cheap as its identity.**
///
/// `Theme.updateShouldNotify` is `data != oldWidget.data`, so what decides
/// whether a `MemoxApp` rebuild costs one widget or the whole tree is not how
/// fast a `ThemeData` builds — it is whether the new one compares equal to the
/// old one. It does not, and cannot: `ThemeData.==` walks every component
/// theme, and the button, chip and icon themes here hold
/// `WidgetStateProperty.resolveWith` closures, which have no value equality.
///
/// So the builders memoise, and this file asserts the two halves of that: that
/// one instance comes back, and that the equality it is standing in for really
/// is unavailable. Split from `app_theme_test.dart` on the seam that file
/// already had: everything there is about what the palette *looks* like, and
/// nothing here is about colour at all.
void main() {
  group('theme identity', () {
    test('each theme is built once', () {
      expect(buildLightTheme(), same(buildLightTheme()));
      expect(buildDarkTheme(), same(buildDarkTheme()));
      expect(buildLightTheme(), isNot(same(buildDarkTheme())));
    });

    test('rebuilding a component theme makes the theme unequal', () {
      // Pins the reason for the cache rather than the cache itself. If Flutter
      // ever gives `WidgetStateProperty` value equality, this fails and the
      // memoisation drops from a correctness fix to an optimisation — worth
      // noticing, not worth silently keeping.
      final ThemeData base = buildLightTheme();
      final ColorScheme scheme = base.colorScheme;
      final ThemeData rebuilt = base.copyWith(
        filledButtonTheme: buildFilledButtonTheme(
          scheme,
          base.extension<AppSemanticColors>()!,
          base.textTheme,
        ),
      );

      expect(rebuilt, isNot(base));
    });
  });

  group('compact scale identity', () {
    test('the same base theme yields the same scaled theme', () {
      // `CompactScaleWidget` calls this from `build()`, under `MaterialApp` —
      // so it re-runs on every `MemoxApp` rebuild, not only when the width
      // changes. Uncached, it would re-notify every `Theme.of` dependent below
      // it and undo the memoisation one level up.
      final ThemeData base = buildLightTheme();

      expect(applyCompactScale(base), same(applyCompactScale(base)));
    });

    test('a different base yields a different scaled theme', () {
      // The cache keys on the base, not on nothing. Without this a dark base
      // would silently receive the light theme's compact pass.
      expect(
        applyCompactScale(buildLightTheme()),
        isNot(same(applyCompactScale(buildDarkTheme()))),
      );
    });

    test('and it still applies the compact pass', () {
      // Caching a wrong answer is worse than not caching. The app bar title is
      // the cheapest proof that the returned theme is the scaled one.
      final ThemeData base = buildLightTheme();
      final ThemeData compact = applyCompactScale(base);

      expect(
        compact.textTheme.titleLarge?.fontSize,
        lessThan(base.textTheme.titleLarge!.fontSize!),
      );
    });
  });
}
