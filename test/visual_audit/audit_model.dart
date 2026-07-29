import 'package:flutter/material.dart';

/// What a measured colour *is* on screen.
enum PaintRole {
  /// A filled area: card, page, tile, button background.
  fill,

  /// A stroke around something: card outline, input border, focus ring.
  border,

  /// Glyphs. Icons land here too when they are font glyphs.
  text,
}

/// Where a measurement came from, which decides how far it can be trusted.
enum PaintSource {
  /// Read off the render tree. Exact for what the code asked for, blind to
  /// anything composited on top — opacity, ink splash, elevation tint.
  declared,

  /// Read back from the rendered image. What the eye actually receives,
  /// including every blend, but carrying no meaning of its own.
  raster,
}

/// Why a node produced no measurement.
///
/// Every one of these is printed. An audit that silently drops what it cannot
/// read and then reports "no violations" is worse than no audit, because the
/// next person stops looking with their own eyes.
enum SkipReason {
  /// A render type no extractor claims and the transparent list does not
  /// vouch for. The default for anything new — so a painting widget added next
  /// month shows up here rather than vanishing.
  unknownRenderType,

  /// `TextStyle.foreground` is a `Paint`, so there is no single colour. Shader
  /// text is the usual cause.
  shaderForeground,

  /// The style resolved with no colour at all; the engine will fall back, and
  /// guessing which fallback would be inventing data.
  missingColor,

  /// A gradient fill — a region, not a colour.
  gradient,

  /// `CustomPaint`. Notably this is how `InputDecorator` and `OutlinedButton`
  /// draw their borders, so those strokes are never readable from the render
  /// tree.
  customPainter,

  /// A node that definitely paints, through a private render object with no
  /// colour to read: the `Material` ink layer, `ColoredBox`. Distinct from
  /// [unknownRenderType] because this is understood, not unrecognised — the
  /// colour exists, and only the raster has it.
  rasterOnly,

  /// An image whose pixels are the content.
  imageContent,

  /// An opacity or filter layer: every declared colour below it is not final.
  compositedLayer,

  /// The declared fill disagrees with what the raster shows in the same rect —
  /// something is painted over it.
  occluded,

  /// Nothing to measure.
  zeroSize,
}

/// One colour, at one place, with the provenance needed to judge it.
@immutable
class AuditPaint {
  const AuditPaint({
    required this.role,
    required this.color,
    required this.rect,
    required this.source,
    required this.origin,
    this.fontSize,
    this.fontWeight,
  });

  final PaintRole role;
  final Color color;
  final Rect rect;
  final PaintSource source;

  /// The render type it was read from, for tracing a surprise back to code.
  final String origin;

  final double? fontSize;
  final FontWeight? fontWeight;

  /// WCAG's "large scale text": 18pt / 24px, or 14pt / 18.66px when bold.
  ///
  /// Unknown size resolves to `false`, which picks the stricter 4.5:1
  /// threshold. A missing measurement must never buy a lower bar.
  bool get isLargeText {
    final size = fontSize;
    if (size == null) return false;

    const largeRegular = 24.0;
    const largeBold = 18.66;
    final isBold = (fontWeight?.value ?? 0) >= FontWeight.w700.value;

    return size >= largeRegular || (isBold && size >= largeBold);
  }

  @override
  String toString() =>
      '${role.name} ${_hex(color)} @ $origin '
      '${rect.left.toStringAsFixed(0)},${rect.top.toStringAsFixed(0)}';
}

/// A node the audit could not measure, and why.
@immutable
class AuditSkip {
  const AuditSkip({
    required this.itemId,
    required this.reason,
    required this.detail,
    this.rect,
  });

  final String itemId;
  final SkipReason reason;
  final String detail;
  final Rect? rect;

  @override
  String toString() => '${reason.name}: $detail  [$itemId]';
}

/// A meaningful piece of UI — a card, a button, a field — and every colour it
/// paints.
///
/// The unit is deliberately *not* the render object. A button is several render
/// objects and a paragraph is several spans; a flat list of render nodes cannot
/// say "the Forgotten button has label X on background Y", which is the only
/// sentence a report is useful for.
@immutable
class AuditItem {
  const AuditItem({required this.id, required this.rect, required this.paints});

  final String id;
  final Rect rect;
  final List<AuditPaint> paints;

  Iterable<AuditPaint> withRole(PaintRole role) =>
      paints.where((paint) => paint.role == role);
}

/// One screen, in one theme, at one viewport, in one interaction state.
@immutable
class ScreenAudit {
  const ScreenAudit({
    required this.screen,
    required this.theme,
    required this.state,
    required this.viewport,
    required this.items,
    required this.skips,
  });

  final String screen;
  final String theme;

  /// `idle`, `pressed`, `focused`, `disabled`… A screen audited in one state is
  /// one eighth of a screen.
  final String state;

  final Size viewport;
  final List<AuditItem> items;
  final List<AuditSkip> skips;

  String get label => '$screen/$theme/$state';

  Iterable<AuditPaint> get allPaints => items.expand((item) => item.paints);

  Iterable<AuditSkip> skipsBecause(SkipReason reason) =>
      skips.where((skip) => skip.reason == reason);
}

String _hex(Color color) {
  final argb = color.toARGB32();
  final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  final alpha = (argb >> 24) & 0xFF;

  // Alpha is shown whenever it is not opaque. Printing a translucent black as
  // `#000000` cost one debugging round already: the report read as a hardcoded
  // black fill when the truth was `MaterialType.transparency`.
  if (alpha == 0xFF) return '#${rgb.toUpperCase()}';

  return '#${alpha.toRadixString(16).padLeft(2, '0')}$rgb'.toUpperCase();
}

/// `#RRGGBB`, or `#AARRGGBB` when the colour is not opaque.
String hexOf(Color color) => _hex(color);
