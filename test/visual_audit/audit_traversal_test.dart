import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audit_model.dart';
import 'marker_probe.dart';

/// What the walk visits, and what it refuses to.
///
/// Visibility only: `Offstage`, opacity, layout position, transforms. Clipping
/// is a separate question with a separate failure mode, and lives in
/// `audit_clip_test.dart`.
void main() {
  Future<ScreenAudit> auditOf(WidgetTester tester, Widget body) =>
      auditMarker(tester, body);

  testWidgets('a visible child is audited', (tester) async {
    final audit = await auditOf(tester, Center(child: markerBox()));

    expect(sawMarker(audit), isTrue);
  });

  testWidgets('Offstage(true) prunes the subtree', (tester) async {
    final audit = await auditOf(tester, Offstage(child: markerBox()));

    expect(sawMarker(audit), isFalse);
    expect(audit.hiddenNodes, greaterThan(0));
  });

  testWidgets('Offstage(false) does not', (tester) async {
    final audit = await auditOf(
      tester,
      Center(child: Offstage(offstage: false, child: markerBox())),
    );

    expect(sawMarker(audit), isTrue);
  });

  testWidgets('Opacity(0) prunes the subtree', (tester) async {
    final audit = await auditOf(
      tester,
      Center(child: Opacity(opacity: 0, child: markerBox())),
    );

    expect(sawMarker(audit), isFalse);
    expect(audit.hiddenNodes, greaterThan(0));
  });

  testWidgets('Opacity(1) does not', (tester) async {
    final audit = await auditOf(
      tester,
      Center(child: Opacity(opacity: 1, child: markerBox())),
    );

    expect(sawMarker(audit), isTrue);
    // A fully opaque layer is not a composited one, and reporting it as such
    // buried the real skips under noise nobody read.
    expect(audit.skipsBecause(SkipReason.compositedLayer), isEmpty);
  });

  testWidgets('a child laid out beyond the surface is not audited', (
    tester,
  ) async {
    final audit = await auditOf(
      tester,
      Stack(
        clipBehavior: Clip.none,
        children: <Widget>[Positioned(left: 900, top: 900, child: markerBox())],
      ),
    );

    expect(sawMarker(audit), isFalse);
    expect(audit.outsideCaptureNodes, greaterThan(0));
  });

  testWidgets('a transform that pulls a child into view is NOT pruned', (
    tester,
  ) async {
    // The trap. `RenderTransform` does not appear in its own `getTransformTo`,
    // so its rect is the untransformed one — here, far off screen — while the
    // child it moves is plainly visible. Pruning on the ancestor's rect would
    // drop a widget the user is looking at, and the audit would report nothing
    // at all about it.
    final audit = await auditOf(
      tester,
      Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: 900,
            top: 900,
            child: Transform.translate(
              offset: const Offset(-880, -880),
              child: markerBox(),
            ),
          ),
        ],
      ),
    );

    expect(sawMarker(audit), isTrue);
  });
}
