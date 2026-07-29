import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

import 'audit_model.dart';
import 'screen_auditor.dart';

/// What the walk visits, and what it refuses to.
///
/// Two failure directions, and they are not symmetric. Auditing something that
/// never reaches the screen produces findings about pixels nobody sees — noise
/// that trains people to ignore the report. Pruning something that *is* on
/// screen produces silence, which reads as a pass. The tests below cover both,
/// because a policy tuned only against noise will happily hide a visible widget.
void main() {
  const marker = Color(0xFF123456);

  Future<ScreenAudit> auditOf(WidgetTester tester, Widget body) async {
    tester.view.physicalSize = const Size(300, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AuditSurface(
        child: MaterialApp(theme: buildLightTheme(), home: body),
      ),
    );
    await tester.pump();

    return auditScreen(tester, screen: 'probe', theme: 'light');
  }

  bool sawMarker(ScreenAudit audit) => audit.allPaints.any(
    (paint) =>
        paint.source == PaintSource.declared &&
        paint.color.toARGB32() == marker.toARGB32(),
  );

  /// A 40×40 block in a colour nothing else uses, easy to find in the inventory.
  ///
  /// `DecoratedBox`, not `Container(color:)`: the latter builds a `ColoredBox`,
  /// whose render object is private and therefore classified raster-only — the
  /// marker would vanish for a reason that has nothing to do with traversal.
  Widget markerBox() => const SizedBox(
    width: 40,
    height: 40,
    child: DecoratedBox(decoration: BoxDecoration(color: marker)),
  );

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
