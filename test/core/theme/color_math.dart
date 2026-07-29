import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Colour measurements shared by the theme tests.
///
/// Kept in one place because the palette is judged by numbers rather than by
/// eye: a palette approved on the reviewer's monitor fails on a phone outdoors,
/// and "looks fine" is not a thing a test can re-check next month.

/// WCAG 2.1 relative luminance, 0.0 to 1.0.
double luminance(Color color) {
  double channel(double component) {
    return component <= 0.03928
        ? component / 12.92
        : math.pow((component + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG contrast ratio between two opaque colours, 1.0 to 21.0.
double contrast(Color foreground, Color background) {
  final a = luminance(foreground);
  final b = luminance(background);

  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

/// CIE L\*, 0 to 100 — perceptual lightness.
///
/// The surface ladder is asserted in this rather than in [contrast] because the
/// dark page sits at luminance 0.004, and down there WCAG's `+0.05` constant
/// compresses every real step into "1.1-something": the card is three times the
/// page's luminance and still scores 1.17:1. L\* stays honest at the bottom of
/// the scale, which is the only part of the scale dark mode lives in.
double lightnessStar(Color color) {
  final y = luminance(color);

  if (y <= 0.008856) return 903.3 * y;

  return 116 * math.pow(y, 1 / 3).toDouble() - 16;
}

/// HSL saturation, 0.0 to 1.0 — "how coloured is this, for its lightness".
///
/// Lightness-normalised on purpose: it is what answers "is this surface as navy
/// as the page", which raw chroma cannot, because chroma grows with lightness
/// and would call every light surface pale regardless of its hue.
double saturation(Color color) {
  final high = math.max(color.r, math.max(color.g, color.b));
  final low = math.min(color.r, math.min(color.g, color.b));
  final delta = high - low;

  if (delta == 0) return 0;

  return delta / (1 - (high + low - 1).abs());
}

/// Hue in degrees, 0 to 360. Returns null for a grey, which has no hue.
double? hue(Color color) {
  final high = math.max(color.r, math.max(color.g, color.b));
  final low = math.min(color.r, math.min(color.g, color.b));
  final delta = high - low;

  if (delta == 0) return null;
  if (high == color.r) return (60 * ((color.g - color.b) / delta)) % 360;
  if (high == color.g) return 60 * ((color.b - color.r) / delta + 2);

  return 60 * ((color.r - color.g) / delta + 4);
}

/// Raw chroma, 0.0 to 1.0 — the absolute distance from grey.
///
/// The right measure for "does this near-white carry a tint": [saturation]
/// reports 22% for a background four steps off pure white, which says nothing
/// useful about whether the tint is visible.
double chroma(Color color) {
  final high = math.max(color.r, math.max(color.g, color.b));
  final low = math.min(color.r, math.min(color.g, color.b));

  return high - low;
}
