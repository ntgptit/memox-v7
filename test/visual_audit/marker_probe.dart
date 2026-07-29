import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

import 'audit_model.dart';
import 'screen_auditor.dart';

/// A block in a colour nothing else on screen uses, plus the pump that audits
/// it.
///
/// Shared by the traversal and clip suites so both ask the same question of the
/// same subject: *did this widget reach the inventory*. Two copies of the probe
/// would let the two suites drift into testing slightly different things.
const Color marker = Color(0xFF123456);

/// `DecoratedBox`, not `Container(color:)`: the latter builds a `ColoredBox`,
/// whose render object is private and therefore classified raster-only — the
/// marker would vanish for a reason that has nothing to do with traversal.
Widget markerBox() => const SizedBox(
  width: 40,
  height: 40,
  child: DecoratedBox(decoration: BoxDecoration(color: marker)),
);

bool sawMarker(ScreenAudit audit) => audit.allPaints.any(
  (paint) =>
      paint.source == PaintSource.declared &&
      paint.color.toARGB32() == marker.toARGB32(),
);

Future<ScreenAudit> auditMarker(WidgetTester tester, Widget body) async {
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

/// Allows only the leftmost 10 logical pixels through.
class LeftStripClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, 10, size.height);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
