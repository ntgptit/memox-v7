import 'package:flutter/rendering.dart';

import 'audit_model.dart';

/// Collects what one item paints, and what it refused to guess at.
class AuditSink {
  AuditSink(this.itemId);

  final String itemId;
  final List<AuditPaint> paints = <AuditPaint>[];
  final List<AuditSkip> skips = <AuditSkip>[];

  void add(AuditPaint paint) {
    // Same colour, same role, same rect from two nodes is one fact reported
    // twice — a Material and the DecoratedBox inside it, for instance.
    final isDuplicate = paints.any(
      (existing) =>
          existing.role == paint.role &&
          existing.color == paint.color &&
          existing.rect == paint.rect,
    );
    if (isDuplicate) return;

    paints.add(paint);
  }

  void skip(SkipReason reason, String detail, {Rect? rect}) {
    skips.add(
      AuditSkip(itemId: itemId, reason: reason, detail: detail, rect: rect),
    );
  }
}

/// Reads the colours out of one kind of render object.
///
/// A registry rather than a switch because Flutter paints through many
/// unrelated types, and the set is open: `Ink`, `backgroundBuilder` and every
/// `CustomPainter` are outside it. Anything unclaimed becomes a
/// [SkipReason.unknownRenderType] rather than silence — so a painting widget
/// added later announces itself instead of being quietly ignored.
abstract interface class PaintExtractor {
  bool handles(RenderObject node);

  void extract(RenderObject node, Rect rect, AuditSink sink);
}

const List<PaintExtractor> defaultExtractors = <PaintExtractor>[
  _ParagraphExtractor(),
  _DecoratedBoxExtractor(),
  _PhysicalShapeExtractor(),
  _PhysicalModelExtractor(),
  _ImageExtractor(),
  _CustomPaintExtractor(),
  _OpacityExtractor(),
];

/// Text and font-glyph icons.
class _ParagraphExtractor implements PaintExtractor {
  const _ParagraphExtractor();

  @override
  bool handles(RenderObject node) => node is RenderParagraph;

  @override
  void extract(RenderObject node, Rect rect, AuditSink sink) {
    final paragraph = node as RenderParagraph;

    _visitSpan(paragraph.text, const TextStyle(), rect, sink);
  }

  /// Walks the span tree merging parent style into child.
  ///
  /// `Text` merges `DefaultTextStyle` before building its `RichText`, so its
  /// root span is already resolved — but `Text.rich` and `RichText` nest spans
  /// that inherit, and reading only the root style would report the parent's
  /// colour for a child painted in another one.
  void _visitSpan(
    InlineSpan span,
    TextStyle inherited,
    Rect rect,
    AuditSink sink,
  ) {
    final style = span.style == null ? inherited : inherited.merge(span.style);

    if (span is! TextSpan) {
      sink.skip(
        SkipReason.unknownRenderType,
        'inline span ${span.runtimeType} is not text',
        rect: rect,
      );

      return;
    }

    final text = span.text;
    if (text != null && text.isNotEmpty) {
      _emit(style, text, rect, sink);
    }

    final children = span.children;
    if (children == null) return;

    for (final child in children) {
      _visitSpan(child, style, rect, sink);
    }
  }

  void _emit(TextStyle style, String text, Rect rect, AuditSink sink) {
    if (style.foreground != null) {
      sink.skip(
        SkipReason.shaderForeground,
        'text "${_clip(text)}" paints through a Paint, so it has no '
        'single colour',
        rect: rect,
      );

      return;
    }

    final color = style.color;
    if (color == null) {
      sink.skip(
        SkipReason.missingColor,
        'text "${_clip(text)}" resolved with no colour',
        rect: rect,
      );

      return;
    }

    sink.add(
      AuditPaint(
        role: PaintRole.text,
        color: color,
        rect: rect,
        source: PaintSource.declared,
        origin: 'RenderParagraph',
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
      ),
    );
  }

  String _clip(String text) {
    const limit = 24;

    return text.length <= limit ? text : '${text.substring(0, limit)}…';
  }
}

/// `Container`, `DecoratedBox`, and the `Card` outline.
class _DecoratedBoxExtractor implements PaintExtractor {
  const _DecoratedBoxExtractor();

  @override
  bool handles(RenderObject node) => node is RenderDecoratedBox;

  @override
  void extract(RenderObject node, Rect rect, AuditSink sink) {
    final decoration = (node as RenderDecoratedBox).decoration;

    if (decoration is BoxDecoration) {
      if (decoration.gradient != null) {
        sink.skip(SkipReason.gradient, 'BoxDecoration.gradient', rect: rect);
      }
      _addFill(decoration.color, rect, 'BoxDecoration', sink);
      _addBorder(decoration.border, rect, 'BoxDecoration', sink);

      return;
    }

    if (decoration is ShapeDecoration) {
      if (decoration.gradient != null) {
        sink.skip(SkipReason.gradient, 'ShapeDecoration.gradient', rect: rect);
      }
      _addFill(decoration.color, rect, 'ShapeDecoration', sink);

      final shape = decoration.shape;
      if (shape is OutlinedBorder) {
        _addSide(shape.side, rect, 'ShapeDecoration', sink);
      }

      return;
    }

    sink.skip(
      SkipReason.unknownRenderType,
      'decoration ${decoration.runtimeType}',
      rect: rect,
    );
  }

  void _addFill(Color? color, Rect rect, String origin, AuditSink sink) {
    if (color == null || color.a == 0) return;

    sink.add(
      AuditPaint(
        role: PaintRole.fill,
        color: color,
        rect: rect,
        source: PaintSource.declared,
        origin: origin,
      ),
    );
  }

  void _addBorder(BoxBorder? border, Rect rect, String origin, AuditSink sink) {
    if (border == null) return;

    if (border is Border) {
      for (final side in <BorderSide>[
        border.top,
        border.right,
        border.bottom,
        border.left,
      ]) {
        _addSide(side, rect, origin, sink);
      }

      return;
    }

    if (border is BorderDirectional) {
      for (final side in <BorderSide>[
        border.top,
        border.start,
        border.bottom,
        border.end,
      ]) {
        _addSide(side, rect, origin, sink);
      }

      return;
    }

    sink.skip(
      SkipReason.unknownRenderType,
      'border ${border.runtimeType}',
      rect: rect,
    );
  }

  void _addSide(BorderSide side, Rect rect, String origin, AuditSink sink) {
    if (side.style == BorderStyle.none || side.width == 0) return;

    sink.add(
      AuditPaint(
        role: PaintRole.border,
        color: side.color,
        rect: rect,
        source: PaintSource.declared,
        origin: origin,
      ),
    );
  }
}

/// `Material` with a shape — the surface under most Material components.
class _PhysicalShapeExtractor implements PaintExtractor {
  const _PhysicalShapeExtractor();

  @override
  bool handles(RenderObject node) => node is RenderPhysicalShape;

  @override
  void extract(RenderObject node, Rect rect, AuditSink sink) {
    // `MaterialType.transparency` lands here as transparent black. It paints
    // nothing, and reporting it as a fill made the audit accuse the screen of
    // a hardcoded black.
    if ((node as RenderPhysicalShape).color.a == 0) return;

    sink.add(
      AuditPaint(
        role: PaintRole.fill,
        color: node.color,
        rect: rect,
        source: PaintSource.declared,
        origin: 'RenderPhysicalShape',
      ),
    );
  }
}

class _PhysicalModelExtractor implements PaintExtractor {
  const _PhysicalModelExtractor();

  @override
  bool handles(RenderObject node) => node is RenderPhysicalModel;

  @override
  void extract(RenderObject node, Rect rect, AuditSink sink) {
    if ((node as RenderPhysicalModel).color.a == 0) return;

    sink.add(
      AuditPaint(
        role: PaintRole.fill,
        color: node.color,
        rect: rect,
        source: PaintSource.declared,
        origin: 'RenderPhysicalModel',
      ),
    );
  }
}

/// `ImageIcon` and a tinted `Image` — the tint is readable, the pixels are not.
class _ImageExtractor implements PaintExtractor {
  const _ImageExtractor();

  @override
  bool handles(RenderObject node) => node is RenderImage;

  @override
  void extract(RenderObject node, Rect rect, AuditSink sink) {
    final color = (node as RenderImage).color;
    if (color == null) {
      sink.skip(SkipReason.imageContent, 'untinted RenderImage', rect: rect);

      return;
    }

    sink.add(
      AuditPaint(
        role: PaintRole.text,
        color: color,
        rect: rect,
        source: PaintSource.declared,
        origin: 'RenderImage',
      ),
    );
  }
}

/// Always a skip, and an important one: this is how `InputDecorator` draws its
/// border, so an input's stroke colour never appears in the render tree.
class _CustomPaintExtractor implements PaintExtractor {
  const _CustomPaintExtractor();

  @override
  bool handles(RenderObject node) => node is RenderCustomPaint;

  @override
  void extract(RenderObject node, Rect rect, AuditSink sink) {
    final painter = (node as RenderCustomPaint).painter;

    sink.skip(
      SkipReason.customPainter,
      'CustomPaint (${painter?.runtimeType ?? 'no painter'}) — read this from '
      'the raster',
      rect: rect,
    );
  }
}

/// Not a colour, a modifier: everything declared below it is not what lands.
class _OpacityExtractor implements PaintExtractor {
  const _OpacityExtractor();

  @override
  bool handles(RenderObject node) =>
      node is RenderOpacity || node is RenderAnimatedOpacity;

  @override
  void extract(RenderObject node, Rect rect, AuditSink sink) {
    // A fully opaque layer changes nothing, and reporting it would bury the
    // ones that do under noise nobody reads.
    final opacity = node is RenderOpacity
        ? node.opacity
        : (node as RenderAnimatedOpacity).opacity.value;
    if (opacity == 1.0) return;

    sink.skip(
      SkipReason.compositedLayer,
      'opacity ${opacity.toStringAsFixed(2)} applies to this subtree',
      rect: rect,
    );
  }
}
