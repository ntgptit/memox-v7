import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audit_model.dart';
import 'audit_raster.dart';
import 'paint_extractors.dart';
import 'render_classification.dart';

/// Key of the boundary every audit captures through.
const Key auditSurfaceKey = ValueKey<String>('visual_audit.surface');

/// Wraps the widget under audit in the `RepaintBoundary` the capture needs.
///
/// A widget, not a `Semantics` marker: instrumentation must not reshape the
/// accessibility tree, and inside a widget test `find.byType` reaches anything a
/// semantics identifier could — identifiers earn their keep one tier up, on the
/// Playwright/device side, where the process boundary makes them the only handle.
class AuditSurface extends StatelessWidget {
  const AuditSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(key: auditSurfaceKey, child: child);
}

/// Names a meaningful piece of UI.
///
/// The unit of a report is an *item*, not a render object: a button is a
/// physical shape plus a paragraph plus padding, and "RenderParagraph #7 is
/// `#C3C6D2`" is not a sentence anyone can act on.
@immutable
class AuditAnchor {
  const AuditAnchor(this.id, this.finder);

  /// Every widget of a type, numbered — for lists and repeated controls.
  factory AuditAnchor.type(String id, Type type) =>
      AuditAnchor(id, find.byType(type));

  final String id;
  final Finder finder;
}

/// Runs the whole audit: walk, extract, capture, cross-check.
///
/// [anchors] decide how the screen is *named*, never what is *covered* — the
/// walk is exhaustive and anything outside every anchor belongs to the implicit
/// `screen` item. A manifest that decided coverage would only ever check what
/// someone remembered to list, and the widget most likely to carry a hardcoded
/// colour is the one added after the list was written.
Future<ScreenAudit> auditScreen(
  WidgetTester tester, {
  required String screen,
  required String theme,
  String state = 'idle',
  List<AuditAnchor> anchors = const <AuditAnchor>[],
  List<PaintExtractor> extractors = defaultExtractors,
  double pixelRatio = 1,
}) async {
  final boundaryFinder = find.byKey(auditSurfaceKey);
  final root = tester.renderObject<RenderRepaintBoundary>(boundaryFinder);
  final raster = await RasterCapture.capture(
    tester,
    boundaryFinder: boundaryFinder,
    pixelRatio: pixelRatio,
  );

  const rootId = 'screen';
  final owners = _resolveAnchors(anchors);
  final sinks = <String, AuditSink>{rootId: AuditSink(rootId)};

  void walk(RenderObject node, String owner) {
    final id = owners[node] ?? owner;
    final sink = sinks.putIfAbsent(id, () => AuditSink(id));
    final rect = _globalRect(node);

    _extract(node, rect, sink, extractors);
    node.visitChildren((child) => walk(child, id));
  }

  walk(root, rootId);

  final items = <AuditItem>[];
  final skips = <AuditSkip>[];

  for (final entry in sinks.entries) {
    final sink = entry.value;
    _crossCheckAgainstRaster(sink, raster);
    items.add(
      AuditItem(
        id: entry.key,
        rect: _itemRect(sink.paints),
        paints: List<AuditPaint>.unmodifiable(sink.paints),
      ),
    );
    skips.addAll(sink.skips);
  }

  for (final anchor in anchors) {
    if (owners.values.contains(anchor.id)) continue;

    skips.add(
      AuditSkip(
        itemId: anchor.id,
        reason: SkipReason.zeroSize,
        detail: 'anchor matched no widget',
      ),
    );
  }

  return ScreenAudit(
    screen: screen,
    theme: theme,
    state: state,
    viewport: tester.view.physicalSize / tester.view.devicePixelRatio,
    items: List<AuditItem>.unmodifiable(items),
    skips: List<AuditSkip>.unmodifiable(skips),
  );
}

Map<RenderObject, String> _resolveAnchors(List<AuditAnchor> anchors) {
  final owners = <RenderObject, String>{};

  for (final anchor in anchors) {
    final elements = anchor.finder.evaluate().toList();

    for (var i = 0; i < elements.length; i++) {
      final node = elements[i].renderObject;
      if (node == null) continue;

      owners[node] = elements.length == 1 ? anchor.id : '${anchor.id}[$i]';
    }
  }

  return owners;
}

void _extract(
  RenderObject node,
  Rect rect,
  AuditSink sink,
  List<PaintExtractor> extractors,
) {
  // Layout scaffolding first: a zero-height spacer is not a finding, and ten
  // of them per screen is how a real skip gets scrolled past.
  if (renderPaintsNothing(node)) return;

  if (renderPaintsRasterOnly(node)) {
    sink.skip(
      SkipReason.rasterOnly,
      '${node.runtimeType} paints with no colour to read',
      rect: rect,
    );

    return;
  }

  if (rect.isEmpty) {
    sink.skip(
      SkipReason.zeroSize,
      '${node.runtimeType} has no area',
      rect: rect,
    );

    return;
  }

  for (final extractor in extractors) {
    if (!extractor.handles(node)) continue;

    extractor.extract(node, rect, sink);

    return;
  }

  sink.skip(
    SkipReason.unknownRenderType,
    '${node.runtimeType} is neither extractable nor known to paint nothing',
    rect: rect,
  );
}

/// Adds what the raster actually shows, and flags where it disagrees.
///
/// The disagreement is the point. A declared fill that the image does not
/// confirm means something is on top — an ink splash, an opacity layer, another
/// widget — and that is precisely the class of bug neither source finds alone.
void _crossCheckAgainstRaster(AuditSink sink, RasterCapture raster) {
  const flatEnough = 0.5;
  final declaredFills = sink.paints
      .where((paint) => paint.role == PaintRole.fill)
      .toList();
  final measured = <Rect, ColorFrequency>{};

  for (final paint in <AuditPaint>[
    ...declaredFills,
    ...sink.paints.where((paint) => paint.role == PaintRole.text),
  ]) {
    measured[paint.rect] ??= raster.dominant(paint.rect) ?? _empty;
  }

  measured.forEach((rect, sample) {
    if (identical(sample, _empty)) return;
    if (sample.coverage < flatEnough) return;

    sink.add(
      AuditPaint(
        role: PaintRole.fill,
        color: sample.color,
        rect: rect,
        source: PaintSource.raster,
        origin: 'raster ${(sample.coverage * 100).toStringAsFixed(0)}%',
      ),
    );
  });

  for (final declared in declaredFills) {
    final sample = measured[declared.rect];
    if (sample == null || identical(sample, _empty)) continue;
    // Packed ARGB, not `==`: `Color` compares float channels, and a colour
    // built by `alphaBlend` never equals the integer one a raster reports
    // even when both render to the same pixel.
    if (sample.color.toARGB32() == declared.color.toARGB32()) continue;
    if (sample.coverage < flatEnough) continue;

    sink.skip(
      SkipReason.occluded,
      'declared ${hexOf(declared.color)} from ${declared.origin}, but the '
      'image shows ${hexOf(sample.color)} over '
      '${(sample.coverage * 100).toStringAsFixed(0)}% of the area',
      rect: declared.rect,
    );
  }
}

const ColorFrequency _empty = ColorFrequency(
  color: Color(0x00000000),
  coverage: 0,
  sampled: 0,
);

Rect _globalRect(RenderObject node) {
  final bounds = node.paintBounds;

  return MatrixUtils.transformRect(node.getTransformTo(null), bounds);
}

Rect _itemRect(List<AuditPaint> paints) {
  if (paints.isEmpty) return Rect.zero;

  return paints
      .map((paint) => paint.rect)
      .reduce((a, b) => a.expandToInclude(b));
}
