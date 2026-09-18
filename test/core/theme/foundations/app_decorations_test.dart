import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_elevation.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/schemes/app_color_scheme.dart';

void _expectShadow(
  List<BoxShadow> shadows, {
  required double dy,
  required double blur,
  required int argb,
}) {
  expect(shadows, hasLength(1));
  final BoxShadow shadow = shadows.single;
  expect(shadow.offset, Offset(0, dy));
  expect(shadow.blurRadius, blur);
  expect(shadow.spreadRadius, 0);
  expect(shadow.color.toARGB32(), argb);
}

void main() {
  // docs/superpowers/specs/2026-09-18-memox-v3-theme-prerequisite.md §5.4.
  test('card-whisper-shadow (shadow-soft): 0 1px 2px @4% light, none dark', () {
    _expectShadow(
      AppDecorations.cardWhisperShadow(lightColorScheme),
      dy: 1,
      blur: 2,
      argb: 0x0A0F1638,
    );
    expect(AppDecorations.cardWhisperShadow(darkColorScheme), isEmpty);
  });

  test('overlay-shadow (shadow-card) — the Dialog, not the Card', () {
    _expectShadow(
      AppDecorations.overlayShadow(lightColorScheme),
      dy: 12,
      blur: 32,
      argb: 0x1A0F1638,
    );
    _expectShadow(
      AppDecorations.overlayShadow(darkColorScheme),
      dy: 16,
      blur: 40,
      argb: 0x6B000000,
    );
  });

  test('chrome-shadow (shadow-chrome) casts upward', () {
    _expectShadow(
      AppDecorations.chromeShadow(lightColorScheme),
      dy: -2,
      blur: 12,
      argb: 0x0D0F1638,
    );
    _expectShadow(
      AppDecorations.chromeShadow(darkColorScheme),
      dy: -2,
      blur: 14,
      argb: 0x5C000000,
    );
  });

  test('fab-shadow (shadow-fab)', () {
    _expectShadow(
      AppDecorations.fabShadow(lightColorScheme),
      dy: 8,
      blur: 24,
      argb: 0x1F0F1638,
    );
    _expectShadow(
      AppDecorations.fabShadow(darkColorScheme),
      dy: 10,
      blur: 28,
      argb: 0x80000000,
    );
  });

  test(
    'hairline-edge (border-ghost) is primary at 14% / 16%, one hairline',
    () {
      final BorderSide light = AppDecorations.hairlineEdge(lightColorScheme);
      final BorderSide dark = AppDecorations.hairlineEdge(darkColorScheme);
      expect(light.color.toARGB32(), 0x245265F5);
      expect(dark.color.toARGB32(), 0x298B9AFF);
      expect(light.width, AppStroke.hairline);
      expect(dark.width, AppStroke.hairline);
    },
  );

  test('the elevation scale still paints what it painted before', () {
    // This task centralises the VALUES; which treatment a level wears is the
    // component contracts' decision, deferred (delta matrix D4). So the levels
    // keep main's mapping: card -> whisper, raised -> overlay-shadow,
    // overlay -> fab-shadow, with the dark rim unchanged.
    expect(
      shadowsFor(AppElevation.card, lightColorScheme),
      AppDecorations.cardWhisperShadow(lightColorScheme),
    );
    expect(
      shadowsFor(AppElevation.raised, lightColorScheme),
      AppDecorations.overlayShadow(lightColorScheme),
    );
    expect(
      shadowsFor(AppElevation.overlay, lightColorScheme),
      AppDecorations.fabShadow(lightColorScheme),
    );
  });
}
