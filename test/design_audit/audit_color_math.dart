import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Colour maths the audit needs and `test/support/color_math.dart` does not have.
///
/// Kept here rather than added to the shared helper: the audit is a one-off
/// measurement harness, and widening a file every theme test depends on for the
/// sake of a report is how a temporary tool becomes permanent surface area.
/// `luminance`, `contrast`, `saturation` and `chroma` are imported from there —
/// two implementations of contrast would be two answers.

/// Hue in degrees, 0–360. Undefined for a true neutral, which returns null.
///
/// Null rather than 0: hue 0 is red, and a report that prints "red" for pure
/// grey would invent a hue family that is not there. The distinction is the
/// whole point of V1 — "does this neutral carry a trace of the seed" cannot be
/// answered by a number that lies when the answer is "no hue at all".
double? hueOf(Color color) {
  final r = color.r;
  final g = color.g;
  final b = color.b;
  final high = math.max(r, math.max(g, b));
  final low = math.min(r, math.min(g, b));
  final delta = high - low;

  // 1/255 of a channel. Below this the three channels are the same 8-bit value
  // and there is nothing to take a hue from.
  if (delta < 0.004) return null;

  final double raw;
  if (high == r) {
    raw = 60 * (((g - b) / delta) % 6);
  } else if (high == g) {
    raw = 60 * (((b - r) / delta) + 2);
  } else {
    raw = 60 * (((r - g) / delta) + 4);
  }

  return raw < 0 ? raw + 360 : raw;
}

/// The shorter way round the colour wheel between two hues, 0–180.
///
/// Null when either colour has no hue, which the caller must report rather than
/// treat as zero distance.
double? hueDistance(Color a, Color b) {
  final ha = hueOf(a);
  final hb = hueOf(b);
  if (ha == null || hb == null) return null;

  final raw = (ha - hb).abs();

  return raw > 180 ? 360 - raw : raw;
}

/// The canonical derivation the target model names: blend [hueSource] at
/// [opacity] over [surface] and keep the solid result.
///
/// Precomputing is the point. A `BorderSide` given a translucent colour composites
/// against whatever happens to be behind it at paint time, so the same token
/// renders differently over a card and over a sheet — and neither value is the
/// one anybody chose.
Color blendOver(Color hueSource, Color surface, double opacity) =>
    Color.alphaBlend(hueSource.withValues(alpha: opacity), surface);

/// `#RRGGBB`, or `#AARRGGBB` when the colour is not opaque.
///
/// The alpha is shown rather than dropped because a translucent value in a paint
/// slot is itself a finding (V5), and a report that printed it as opaque would
/// hide the thing it exists to catch.
String hex(Color color) {
  final a = (color.a * 255).round();
  final r = (color.r * 255).round();
  final g = (color.g * 255).round();
  final b = (color.b * 255).round();
  final rgb =
      '#${r.toRadixString(16).padLeft(2, '0')}'
              '${g.toRadixString(16).padLeft(2, '0')}'
              '${b.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();

  if (a == 255) return rgb;

  return '#${a.toRadixString(16).padLeft(2, '0').toUpperCase()}${rgb.substring(1)}';
}
