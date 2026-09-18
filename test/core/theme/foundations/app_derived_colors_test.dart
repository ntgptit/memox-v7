import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_derived_colors.dart';
import 'package:memox/core/theme/schemes/app_color_scheme.dart';

/// Channel-wise, within one 8-bit step: `color-mix()` rounds in the browser and
/// `Color.alphaBlend` rounds in `toARGB32`, and the two can land a step apart.
void _expectNear(Color actual, int argb) {
  final Color expected = Color(argb);
  int channel(double value) => (value * 255).round();
  expect((channel(actual.a) - channel(expected.a)).abs(), lessThanOrEqualTo(1));
  expect((channel(actual.r) - channel(expected.r)).abs(), lessThanOrEqualTo(1));
  expect((channel(actual.g) - channel(expected.g)).abs(), lessThanOrEqualTo(1));
  expect((channel(actual.b) - channel(expected.b)).abs(), lessThanOrEqualTo(1));
}

void main() {
  // docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.3.
  test('danger-soft is error at 8% light and 16% dark, over transparent', () {
    expect(
      AppDerivedColors.dangerSoft(lightColorScheme).toARGB32(),
      0x14DC2D4E,
    );
    expect(AppDerivedColors.dangerSoft(darkColorScheme).toARGB32(), 0x29FF8FA3);
  });

  test('surface-hero is primary 5% over surfaceBright in light', () {
    _expectNear(AppDerivedColors.surfaceHero(lightColorScheme), 0xFFF6F7FE);
  });

  test('surface-hero is primary 12% over surface in dark — another base', () {
    _expectNear(AppDerivedColors.surfaceHero(darkColorScheme), 0xFF191F41);
  });

  test('chrome-glass is surface at op-glass, left translucent', () {
    expect(
      AppDerivedColors.chromeGlass(lightColorScheme).toARGB32(),
      0xD6F7F9FE,
    );
    expect(
      AppDerivedColors.chromeGlass(darkColorScheme).toARGB32(),
      0xD60A0E27,
    );
  });

  test('each derivation follows the scheme it is handed', () {
    final ColorScheme moved = lightColorScheme.copyWith(
      error: const Color(0xFF000000),
      surface: const Color(0xFF000000),
    );
    expect(AppDerivedColors.dangerSoft(moved).toARGB32(), 0x14000000);
    expect(AppDerivedColors.chromeGlass(moved).toARGB32(), 0xD6000000);
  });
}
