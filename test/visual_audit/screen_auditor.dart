import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audit_model.dart';
import 'audit_raster.dart';
import 'paint_extractors.dart';
import 'raster_cross_check.dart';
import 'render_classification.dart';
import 'traversal_policy.dart';

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

/// The item everything outside every anchor belongs to.
const String rootItemId = 'screen';

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

/// Rejects an anchor set whose names cannot tell two items apart.
///
/// Sinks are keyed by the id string, so two anchors sharing a name merge two
/// different pieces of UI into one item — wrong background pairing, wrong
/// allowance scope, a report that quietly describes a thing that does not exist.
/// Fixing this with a hidden internal key would not help: allowances scope by the
/// id *string* and people read the report by that same string, so the ambiguity
/// would simply move somewhere nobody can see it.
///
/// Throws rather than reporting: a duplicate name is a bug in the test, and
/// putting it in the same list as the render nodes it is meant to resolve is how
/// it gets skimmed past.
void validateAnchors(List<AuditAnchor> anchors) {
  final indexed = RegExp(r'\[\d+\]$');
  final seen = <String>{};

  for (final anchor in anchors) {
    final id = anchor.id;

    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'AuditAnchor.id', 'An anchor needs a name');
    }
    if (id == rootItemId) {
      throw ArgumentError.value(
        id,
        'AuditAnchor.id',
        '"$rootItemId" is the implicit item everything unclaimed belongs to; '
            'an anchor with that name merges into it',
      );
    }
    if (indexed.hasMatch(id)) {
      throw ArgumentError.value(
        id,
        'AuditAnchor.id',
        'The "name[i]" form is reserved for anchors that match several '
            'widgets, and an explicit id in that shape can collide with a '
            'generated one',
      );
    }
    if (!seen.add(id)) {
      throw ArgumentError.value(
        id,
        'AuditAnchor.id',
        'Two anchors share this name, so their paints would land in one item',
      );
    }
  }
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
  validateAnchors(anchors);

  final boundaryFinder = find.byKey(auditSurfaceKey);
  final root = tester.renderObject<RenderRepaintBoundary>(boundaryFinder);
  final raster = await RasterCapture.capture(
    tester,
    boundaryFinder: boundaryFinder,
    pixelRatio: pixelRatio,
  );

  const rootId = rootItemId;
  final resolved = _resolveAnchors(anchors);
  final owners = resolved.owners;
  final sinks = <String, AuditSink>{rootId: AuditSink(rootId)};
  final captureRect = globalRect(root);
  var hiddenNodes = 0;
  var outsideCaptureNodes = 0;
  var clippedNodes = 0;

  void walk(RenderObject node, String owner, Rect clip) {
    final id = owners[node] ?? owner;

    // The hidden check comes BEFORE the measurement, not after. `globalRect`
    // reads `RenderBox.size`, which asserts on a box that was never laid out —
    // and an unlaid-out box is one of the things `isHidden` recognises. Measuring
    // first meant the walk threw on exactly the nodes it was about to prune.
    if (isHidden(node)) {
      // Nothing below an `Offstage` or a zero-opacity layer reaches the screen,
      // so the whole subtree is pruned. A hidden node is NOT an unresolved one:
      // there was nothing there to measure, and counting it as unread would
      // inflate the very number that is supposed to mean "part of this screen
      // went unchecked".
      hiddenNodes++;

      return;
    }

    final rect = globalRect(node);

    // Only the part of the node that survives the clip is measured. Handing the
    // full rect to the extractor and then to the raster puts pixels the widget
    // never painted into the histogram: coverage drops, the dominant colour
    // becomes whatever surrounds the widget, and the audit reports a mismatch
    // against a region half of which was never its own.
    final visible = rect.intersect(clip);
    if (rect.isEmpty || visible.isEmpty) {
      outsideCaptureNodes++;
    } else {
      final sink = sinks.putIfAbsent(id, () => AuditSink(id));
      _extract(node, visible, sink, extractors);
    }

    // The clip is asked per child, after the node itself is judged. A node can
    // sit outside the visible region and still have children inside it: a
    // transform is not included in the matrix returned for the transform node
    // itself, so that node's rect is the untransformed one. Pruning the subtree
    // on it would drop widgets that are on screen.
    node.visitChildren((child) {
      final childClip = clipForChild(node, child, clip);
      if (childClip.isEmpty) {
        clippedNodes++;

        return;
      }

      walk(child, id, childClip);
    });
  }

  walk(root, rootId, captureRect);

  final items = <AuditItem>[];
  final skips = <AuditSkip>[];

  for (final entry in sinks.entries) {
    final sink = entry.value;
    crossCheckAgainstRaster(sink, raster);
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
    // Asks the resolver whether it matched, rather than searching the owner
    // map by bare id. An anchor matching four widgets writes four indexed
    // names, none of which equals the anchor's own name, so the old check
    // reported "matched no widget" about an anchor that had matched four — a
    // phantom unresolved skip that made PASS unreachable in strict mode.
    if (resolved.matchedAnchorIds.contains(anchor.id)) continue;

    skips.add(
      AuditSkip(
        itemId: anchor.id,
        reason: SkipReason.anchorNotFound,
        detail: 'anchor matched no widget',
      ),
    );
  }

  skips.addAll(resolved.collisions);

  return ScreenAudit(
    screen: screen,
    theme: theme,
    state: state,
    viewport: tester.view.physicalSize / tester.view.devicePixelRatio,
    items: List<AuditItem>.unmodifiable(items),
    skips: List<AuditSkip>.unmodifiable(skips),
    hiddenNodes: hiddenNodes,
    outsideCaptureNodes: outsideCaptureNodes,
    clippedNodes: clippedNodes,
  );
}

/// What the anchors resolved to, including what they failed to resolve to.
///
/// [matchedAnchorIds] is tracked rather than inferred from [owners], because an
/// anchor matching several widgets writes indexed ids and its bare name appears
/// nowhere in the map.
@immutable
class _ResolvedAnchors {
  const _ResolvedAnchors({
    required this.owners,
    required this.matchedAnchorIds,
    required this.collisions,
  });

  final Map<RenderObject, String> owners;
  final Set<String> matchedAnchorIds;
  final List<AuditSkip> collisions;
}

_ResolvedAnchors _resolveAnchors(List<AuditAnchor> anchors) {
  final owners = <RenderObject, String>{};
  final claimedBy = <RenderObject, String>{};
  final matched = <String>{};
  final collisions = <AuditSkip>[];

  for (final anchor in anchors) {
    final elements = anchor.finder.evaluate().toList();
    final nodes = <RenderObject>[
      for (final element in elements)
        if (element.renderObject != null) element.renderObject!,
    ];

    if (nodes.isEmpty) continue;

    matched.add(anchor.id);

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final id = nodes.length == 1 ? anchor.id : '${anchor.id}[$i]';

      final existing = claimedBy[node];
      if (existing != null) {
        // Assigning anyway would let the later anchor overwrite the earlier one
        // and take its half of the report with it, silently.
        collisions.add(
          AuditSkip(
            itemId: anchor.id,
            reason: SkipReason.anchorCollision,
            detail:
                'anchors "$existing" and "$id" both claim the same '
                '${node.runtimeType}; the report can only name it once',
          ),
        );

        continue;
      }

      claimedBy[node] = id;
      owners[node] = id;
    }
  }

  return _ResolvedAnchors(
    owners: owners,
    matchedAnchorIds: matched,
    collisions: collisions,
  );
}

void _extract(
  RenderObject node,
  Rect rect,
  AuditSink sink,
  List<PaintExtractor> extractors,
) {
  if (renderIsErrorBox(node)) {
    sink.skip(
      SkipReason.errorWidget,
      'the widget threw while building and Flutter is rendering its error box',
      rect: rect,
    );

    return;
  }

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

Rect _itemRect(List<AuditPaint> paints) {
  if (paints.isEmpty) return Rect.zero;

  return paints
      .map((paint) => paint.rect)
      .reduce((a, b) => a.expandToInclude(b));
}
