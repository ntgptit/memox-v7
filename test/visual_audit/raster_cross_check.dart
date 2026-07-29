import 'package:flutter/material.dart';

import 'audit_model.dart';
import 'audit_raster.dart';
import 'paint_extractors.dart';

/// Adds what the raster actually shows, and says where it disagrees — without
/// claiming to know why.
///
/// Three thresholds rather than one, because the same number cannot answer three
/// different questions. A rectangle only needs to be half one colour to serve as
/// the background a glyph sits on; it has to be almost entirely one colour before
/// "the image shows something else" is a statement about the fill rather than
/// about the children drawn inside it. Using the background threshold for both is
/// what turns every card nested in a page into a false accusation against the
/// page.
void crossCheckAgainstRaster(AuditSink sink, RasterCapture raster) {
  /// Enough of one colour to stand in as what a glyph is drawn on.
  const usableAsBackground = 0.5;

  /// Enough of one colour that a different dominant is about the fill itself.
  const flatEnoughToJudge = 0.9;

  /// The declared colour is still plainly on screen, just not dominant —
  /// the ordinary shape of a surface with things drawn on top of it.
  const stillPresent = 0.15;

  final declaredFills = sink.paints
      .where((paint) => paint.role == PaintRole.fill)
      .toList();
  final measured = <Rect, RegionSample?>{};

  for (final paint in <AuditPaint>[
    ...declaredFills,
    ...sink.paints.where((paint) => paint.role == PaintRole.text),
  ]) {
    measured[paint.rect] ??= raster.sample(paint.rect);
  }

  measured.forEach((rect, sample) {
    if (sample == null) return;
    if (sample.coverage < usableAsBackground) return;

    sink.add(
      AuditPaint(
        role: PaintRole.fill,
        color: sample.dominant,
        rect: rect,
        source: PaintSource.raster,
        origin: 'raster ${(sample.coverage * 100).toStringAsFixed(0)}%',
      ),
    );
  });

  for (final declared in declaredFills) {
    final sample = measured[declared.rect];
    if (sample == null) continue;
    // Packed ARGB, not `==`: `Color` compares float channels, and a colour
    // built by `alphaBlend` never equals the integer one a raster reports
    // even when both render to the same pixel.
    if (sample.dominant.toARGB32() == declared.color.toARGB32()) continue;

    if (sample.coverage >= flatEnoughToJudge) {
      sink.skip(
        SkipReason.declaredRasterMismatch,
        'declared ${hexOf(declared.color)} from ${declared.origin}, but the '
        'image is ${hexOf(sample.dominant)} across '
        '${(sample.coverage * 100).toStringAsFixed(0)}% of the area',
        rect: declared.rect,
      );

      continue;
    }

    if (sample.shareOf(declared.color) >= stillPresent) continue;

    sink.skip(
      SkipReason.rasterNotFlat,
      'declared ${hexOf(declared.color)} covers only '
      '${(sample.shareOf(declared.color) * 100).toStringAsFixed(0)}% of its '
      'own rect and no colour reaches '
      '${(flatEnoughToJudge * 100).toStringAsFixed(0)}%, so the image cannot '
      'confirm or contradict it',
      rect: declared.rect,
    );
  }
}
