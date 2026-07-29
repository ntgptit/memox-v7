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
  final captureRect = _globalRect(root);
  var hiddenNodes = 0;
  var outsideCaptureNodes = 0;

  void walk(RenderObject node, String owner) {
    final id = owners[node] ?? owner;
    final rect = _globalRect(node);

    switch (_presenceOf(node, rect, captureRect)) {
      case _Presence.hidden:
        // Nothing below an `Offstage` or a zero-opacity layer reaches the
        // screen, so the whole subtree is pruned. A hidden node is NOT an
        // unresolved one: there was nothing there to measure, and counting it
        // as unread would inflate the very number that is supposed to mean
        // "part of this screen went unchecked".
        hiddenNodes++;

        return;

      case _Presence.outsideCapture:
        outsideCaptureNodes++;
        // Pruned only when this node clips. `RenderTransform` does not appear
        // in its own `getTransformTo`, so its rect is the *untransformed* one:
        // a transform that pulls a child into view looks off-screen itself, and
        // pruning on it would drop a subtree that is plainly visible.
        if (_clipsChildren(node)) return;

        node.visitChildren((child) => walk(child, id));

        return;

      case _Presence.visible:
        final sink = sinks.putIfAbsent(id, () => AuditSink(id));
        _extract(node, rect, sink, extractors);
        node.visitChildren((child) => walk(child, id));
    }
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
        reason: SkipReason.anchorNotFound,
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
    hiddenNodes: hiddenNodes,
    outsideCaptureNodes: outsideCaptureNodes,
  );
}

/// Whether a node reaches the captured surface at all.
enum _Presence { visible, hidden, outsideCapture }

_Presence _presenceOf(RenderObject node, Rect rect, Rect capture) {
  if (node is RenderOffstage && node.offstage) return _Presence.hidden;
  if (node is RenderOpacity && node.opacity == 0) return _Presence.hidden;
  if (node is RenderAnimatedOpacity && node.opacity.value == 0) {
    return _Presence.hidden;
  }
  // A node with no area paints nothing, but its children still can — an
  // overflowing child of a zero-size box is laid out and painted — so this
  // marks the node, never the subtree.
  if (rect.isEmpty) return _Presence.outsideCapture;
  if (!rect.overlaps(capture)) return _Presence.outsideCapture;

  return _Presence.visible;
}

/// True when children cannot paint outside this node's bounds.
///
/// The only case where an out-of-capture rect proves the subtree is out too.
bool _clipsChildren(RenderObject node) =>
    node is RenderClipRect ||
    node is RenderClipRRect ||
    node is RenderClipOval ||
    node is RenderClipPath ||
    node is RenderViewport ||
    node is RenderShrinkWrappingViewport;

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
void _crossCheckAgainstRaster(AuditSink sink, RasterCapture raster) {
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
