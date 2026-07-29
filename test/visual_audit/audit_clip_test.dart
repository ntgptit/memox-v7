import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audit_model.dart';
import 'marker_probe.dart';

/// Whether a node survives the clips above it.
///
/// The suite exists because the previous policy guessed clipping from render
/// type and `clipBehavior`, and guessed wrong for the most ordinary case there
/// is: a `Stack` that has not overflowed. It pruned widgets Flutter was plainly
/// painting, which is silence, which reads as a pass.
void main() {
  Future<ScreenAudit> auditOf(WidgetTester tester, Widget body) =>
      auditMarker(tester, body);

  testWidgets('Stack(hardEdge) with NO overflow does not clip anything', (
    tester,
  ) async {
    // The case the type-based policy got wrong, and the one the old
    // `Clip.hardEdge` test could not see because it built real overflow.
    // `RenderStack` pushes a clip only when LAYOUT found visual overflow, and
    // layout only sees positioned children — a `Transform` further down paints
    // outside without producing any overflow, so Flutter draws it and the audit
    // must measure it. `describeApproximatePaintClip` returns null here; the old
    // policy returned the stack's rect and dropped the widget in silence.
    final audit = await auditOf(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            children: <Widget>[
              SizedBox(
                width: 50,
                height: 50,
                child: Transform.translate(
                  offset: const Offset(100, 0),
                  child: markerBox(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(sawMarker(audit), isTrue);
  });

  testWidgets('Flex(hardEdge) with no overflow does not clip either', (
    tester,
  ) async {
    final audit = await auditOf(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Flex(
            direction: Axis.vertical,
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              Transform.translate(
                offset: const Offset(100, 0),
                child: markerBox(),
              ),
            ],
          ),
        ),
      ),
    );

    expect(sawMarker(audit), isTrue);
  });

  testWidgets('a custom clipper over-reports, and that keeps the node', (
    tester,
  ) async {
    // A measured limitation, pinned so it cannot drift. The node is 50 wide and
    // the clipper allows 10, but `describeApproximatePaintClip` answers with the
    // full 50 — the API is explicitly *approximate* and may report a region
    // larger than the real one. So a marker outside the clipper but inside the
    // node stays in the inventory and gets measured even though no pixel of it
    // is on screen.
    //
    // That is the direction to fail in: over-reporting is noise in a list
    // somebody reads, under-reporting is a widget dropped in silence. Anything
    // that starts trusting this rect as exact would turn the second one back on.
    final audit = await auditOf(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 50,
          height: 50,
          child: ClipRect(
            clipper: LeftStripClipper(),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(left: 20, top: 0, child: markerBox()),
              ],
            ),
          ),
        ),
      ),
    );

    expect(sawMarker(audit), isTrue);
  });

  testWidgets('only the visible part of a half-clipped widget is measured', (
    tester,
  ) async {
    // A 40-wide box with 20 columns inside the clip. Measuring the full rect
    // feeds 20 columns of pixels the widget never painted into the histogram,
    // which is how a nested surface turns into a false mismatch.
    final audit = await auditOf(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 20,
          height: 40,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxWidth: 40,
              child: markerBox(),
            ),
          ),
        ),
      ),
    );

    final marked = audit.allPaints.firstWhere(
      (paint) =>
          paint.source == PaintSource.declared &&
          paint.color.toARGB32() == marker.toARGB32(),
    );

    expect(marked.rect.width, 20);
    expect(marked.rect.height, 40);
    expect(audit.skipsBecause(SkipReason.declaredRasterMismatch), isEmpty);
    expect(audit.skipsBecause(SkipReason.rasterNotFlat), isEmpty);
  });

  testWidgets('a child outside an ancestor ClipRect is not audited', (
    tester,
  ) async {
    // The gap effective clip closes. The child sits inside the 300×300 capture
    // rectangle, so a check against the capture alone calls it visible — while
    // the ClipRect above it means no pixel of it was ever drawn.
    final audit = await auditOf(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 50,
          height: 50,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(left: 100, top: 0, child: markerBox()),
              ],
            ),
          ),
        ),
      ),
    );

    expect(sawMarker(audit), isFalse);
  });

  testWidgets('a child partly overlapping a ClipRect is audited', (
    tester,
  ) async {
    final audit = await auditOf(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 50,
          height: 50,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(left: 30, top: 0, child: markerBox()),
              ],
            ),
          ),
        ),
      ),
    );

    expect(sawMarker(audit), isTrue);
  });

  testWidgets('a child fully inside a ClipRect is audited', (tester) async {
    final audit = await auditOf(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 50,
          height: 50,
          child: ClipRect(child: markerBox()),
        ),
      ),
    );

    expect(sawMarker(audit), isTrue);
  });

  testWidgets('Stack(Clip.none) lets a deliberate overflow stay visible', (
    tester,
  ) async {
    // A badge hanging off the corner of a tile is the everyday case. Treating
    // every Stack as a clip would prune it and report nothing about it.
    final audit = await auditOf(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(left: 40, top: 0, child: markerBox()),
            ],
          ),
        ),
      ),
    );

    expect(sawMarker(audit), isTrue);
  });

  testWidgets('Stack(hardEdge) removes a child beyond its bounds', (
    tester,
  ) async {
    final audit = await auditOf(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            // Stack's default, named anyway: this test only means anything
            // beside the `Clip.none` case above it.
            // ignore: avoid_redundant_argument_values
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              Positioned(left: 100, top: 0, child: markerBox()),
            ],
          ),
        ),
      ),
    );

    expect(sawMarker(audit), isFalse);
    expect(audit.clippedNodes + audit.outsideCaptureNodes, greaterThan(0));
  });

  testWidgets('a child scrolled out of a viewport is not audited', (
    tester,
  ) async {
    final audit = await auditOf(
      tester,
      SizedBox(
        height: 100,
        child: ListView(
          children: <Widget>[const SizedBox(height: 2000), markerBox()],
        ),
      ),
    );

    expect(sawMarker(audit), isFalse);
  });

  testWidgets('a transform that pushes a child OUT of the clip is pruned', (
    tester,
  ) async {
    // The mirror of the test below. A child laid out inside the clip but moved
    // out of it by a transform must not be audited — its rect is computed
    // through the final transform, so the check sees where it actually lands.
    final audit = await auditOf(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 50,
          height: 50,
          child: ClipRect(
            child: Transform.translate(
              offset: const Offset(200, 0),
              child: markerBox(),
            ),
          ),
        ),
      ),
    );

    expect(sawMarker(audit), isFalse);
  });
}
