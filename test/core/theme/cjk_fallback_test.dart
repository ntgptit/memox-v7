import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/app_typography.dart';

/// The CJK fallback is wired onto every text style (both themes), so a card whose
/// content is Korean/Japanese/Chinese renders the script instead of tofu boxes on
/// any platform whose system font does not cover it — the web build most of all.
///
/// A wiring test, not a golden: `flutter_test`'s renderer does not exercise the
/// fallback, so a PNG would prove nothing. What matters is that every style names
/// [AppTypography.cjkFallbackFamily] behind its Latin primary, which is what makes
/// Flutter reach for the bundled Noto Sans KR only for the glyphs the primary
/// lacks.
void main() {
  TextStyle styleOf(TextStyle? s) {
    expect(s, isNotNull);
    return s!;
  }

  void expectFallback(TextTheme texts) {
    final styles = <MapEntry<String, TextStyle?>>[
      MapEntry('displayLarge', texts.displayLarge),
      MapEntry('titleMedium', texts.titleMedium),
      MapEntry('titleSmall', texts.titleSmall),
      MapEntry('bodyMedium', texts.bodyMedium),
      MapEntry('labelMedium', texts.labelMedium),
      MapEntry('labelSmall', texts.labelSmall),
    ];
    for (final entry in styles) {
      final style = styleOf(entry.value);
      expect(
        style.fontFamilyFallback,
        contains(AppTypography.cjkFallbackFamily),
        reason: '${entry.key} must fall back to the CJK face',
      );
    }
  }

  test('light theme text styles fall back to the CJK face', () {
    expectFallback(buildLightTheme().textTheme);
  });

  test('dark theme text styles fall back to the CJK face', () {
    expectFallback(buildDarkTheme().textTheme);
  });
}
