import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/color_math.dart';

/// The rendered image, read back once and sampled many times.
///
/// This is the only source that sees what is actually composited: `Ink` splash
/// and highlight are painted onto the `Material` rather than into render objects
/// of their own, so a pressed button's overlay exists **nowhere** in the render
/// tree. Elevation tint, `Opacity` and one widget covering another are the same
/// story. For those, raster is not a cross-check — it is the only witness.
///
/// **Known blind spot:** `flutter_test` sets `debugDisableShadows = true` so
/// goldens stay deterministic, which means every capture here is of a screen
/// with no shadows. Harmless for a palette whose whole thesis is that the
/// surface ladder carries hierarchy without them — but a screen that starts
/// relying on elevation will look correct here and different on a device.
class RasterCapture {
  const RasterCapture._({
    required this.rgba,
    required this.width,
    required this.height,
    required this.origin,
    required this.pixelRatio,
  });

  final Uint8List rgba;
  final int width;
  final int height;

  /// The boundary's top-left in global coordinates.
  ///
  /// `tester.getRect()` is global; `toImage()` puts the boundary's own corner at
  /// (0,0). They coincide only when the boundary is the whole screen at the
  /// origin. Keeping the offset explicit is what lets the same code audit a
  /// sub-region — a sheet, a dialog — without silently sampling the wrong place.
  final Offset origin;

  final double pixelRatio;

  /// Captures the subtree under [boundaryFinder].
  ///
  /// `pixelRatio: 1` keeps one logical unit equal to one pixel, so a rect maps
  /// to the image without a scale factor to get wrong.
  static Future<RasterCapture> capture(
    WidgetTester tester, {
    required Finder boundaryFinder,
    double pixelRatio = 1,
  }) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(boundaryFinder);
    final origin = boundary.localToGlobal(Offset.zero);

    final captured = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      // Dimensions BEFORE dispose. Reading them afterwards is use-after-free:
      // it happens to return stale values today, which is worse than crashing,
      // because a wrong width silently shifts every pixel index by a row.
      final width = image.width;
      final height = image.height;
      // Default format is rawRgba, which is PREMULTIPLIED — see `_rawAt`.
      final data = await image.toByteData();
      image.dispose();

      return (data!.buffer.asUint8List(), width, height);
    });

    if (captured == null) {
      throw StateError('RasterCapture.capture ran outside a live async zone.');
    }

    return RasterCapture._(
      rgba: captured.$1,
      width: captured.$2,
      height: captured.$3,
      origin: origin,
      pixelRatio: pixelRatio,
    );
  }

  Color? colorAt(Offset global) {
    final x = ((global.dx - origin.dx) * pixelRatio).round();
    final y = ((global.dy - origin.dy) * pixelRatio).round();

    return _at(x, y);
  }

  /// The most common exact colour inside [global], and how much of the sampled
  /// area it covers.
  ///
  /// No quantisation. Bucketing to 16 levels merges `surfaceElevated #383D55`
  /// with `surfaceContainerHighest #333852` — two different tokens, one bucket —
  /// which destroys the only question worth asking of a flat fill: *is it
  /// exactly the token we meant*.
  ///
  /// [inset] pulls the sample away from the edges so a border does not vote.
  RegionSample? sample(Rect global, {double inset = 4}) {
    final counts = _histogram(global, inset);
    if (counts.isEmpty) return null;

    var bestValue = 0;
    var bestCount = 0;
    var total = 0;

    counts.forEach((value, count) {
      total += count;
      if (count <= bestCount) return;

      bestValue = value;
      bestCount = count;
    });

    return RegionSample._(
      dominant: Color(bestValue),
      coverage: bestCount / total,
      sampled: total,
      counts: counts,
    );
  }

  /// The colour inside [global] furthest in luminance from [background].
  ///
  /// This is the foreground as the eye receives it. Antialiasing does not
  /// prevent it: a blend lies on the segment between foreground and background,
  /// so the far end of that segment *is* the foreground — provided enough
  /// pixels are fully covered, which is why [minPixels] exists and why small
  /// light text can legitimately return nothing.
  Color? farthestFrom(Color background, Rect global, {int minPixels = 4}) {
    final counts = _histogram(global, 0);
    if (counts.isEmpty) return null;

    final reference = luminance(background);
    Color? best;
    var bestDistance = 0.0;

    counts.forEach((value, count) {
      if (count < minPixels) return;

      final candidate = Color(value);
      final distance = (luminance(candidate) - reference).abs();
      if (distance <= bestDistance) return;

      bestDistance = distance;
      best = candidate;
    });

    return best;
  }

  Map<int, int> _histogram(Rect global, double inset) {
    final local = global.shift(-origin).deflate(inset);
    final left = (local.left * pixelRatio).floor().clamp(0, width);
    final top = (local.top * pixelRatio).floor().clamp(0, height);
    final right = (local.right * pixelRatio).ceil().clamp(0, width);
    final bottom = (local.bottom * pixelRatio).ceil().clamp(0, height);

    final counts = <int, int>{};

    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        final value = _rawAt(x, y);
        if (value == null) continue;

        counts[value] = (counts[value] ?? 0) + 1;
      }
    }

    return counts;
  }

  Color? _at(int x, int y) {
    final value = _rawAt(x, y);

    return value == null ? null : Color(value);
  }

  /// Returns ARGB, or null for a pixel outside the image or not fully opaque.
  ///
  /// Translucent pixels are dropped rather than un-premultiplied: `rawRgba` is
  /// premultiplied, and recovering the original colour from a partly
  /// transparent pixel divides by alpha, which amplifies rounding error into
  /// exactly the kind of nearly-right number that reads as a real measurement.
  int? _rawAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return null;

    final index = (y * width + x) * 4;
    final alpha = rgba[index + 3];
    if (alpha != 0xFF) return null;

    return (0xFF << 24) |
        (rgba[index] << 16) |
        (rgba[index + 1] << 8) |
        rgba[index + 2];
  }
}

/// What the image holds inside one rectangle.
///
/// More than "the dominant colour", because a rectangle that contains nested
/// surfaces has no single answer, and reporting the dominant as if it did is how
/// a card sitting inside a page turns into a false claim that the page is the
/// wrong colour. [shareOf] is what lets the caller ask the narrower question it
/// actually has: *is the colour I declared still present here.*
@immutable
class RegionSample {
  const RegionSample._({
    required this.dominant,
    required this.coverage,
    required this.sampled,
    required Map<int, int> counts,
    // Dart forbids a named parameter starting with an underscore, so the
    // initialising-formal form the lint asks for does not exist for a private
    // field reached through a named argument.
    // ignore: prefer_initializing_formals
  }) : _counts = counts;

  final Color dominant;

  /// Share of sampled pixels holding exactly [dominant]. A flat fill sits near
  /// 1.0; anything low means the region is not one colour and a single value
  /// should not be reported as if it were.
  final double coverage;

  final int sampled;

  final Map<int, int> _counts;

  /// Share of sampled pixels holding exactly [color], 0.0 to 1.0.
  double shareOf(Color color) {
    if (sampled == 0) return 0;

    return (_counts[color.toARGB32()] ?? 0) / sampled;
  }
}
