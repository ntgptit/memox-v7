import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

import 'audit_model.dart';
import 'audit_rules.dart';
import 'screen_auditor.dart';

/// Proves the harness measures what it claims to, on colours chosen so the
/// right answer is known in advance.
///
/// Infrastructure that has only been run against a screen that happens to pass
/// is indistinguishable from infrastructure that reports nothing. Every check
/// below therefore has a companion that makes it fail.
void main() {
  const black = Color(0xFF000000);
  const white = Color(0xFFFFFFFF);
  const grey = Color(0xFF767676);

  Future<ScreenAudit> pump(WidgetTester tester, Widget body) async {
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

  group('extraction', () {
    testWidgets('reads a fill and a border off a decorated box', (
      tester,
    ) async {
      final audit = await pump(
        tester,
        const DecoratedBox(
          decoration: BoxDecoration(
            color: black,
            border: Border.fromBorderSide(BorderSide(color: white, width: 2)),
          ),
          child: SizedBox.expand(),
        ),
      );

      final declared = audit.allPaints.where(
        (paint) => paint.source == PaintSource.declared,
      );

      expect(
        declared.where((p) => p.role == PaintRole.fill).map((p) => p.color),
        contains(black),
      );
      expect(
        declared.where((p) => p.role == PaintRole.border).map((p) => p.color),
        contains(white),
      );
    });

    testWidgets('resolves a nested span against its parent style', (
      tester,
    ) async {
      // The correction that matters: `RichText` children inherit, so reading
      // only the root span reports the parent's colour for a child painted in
      // another one.
      final audit = await pump(
        tester,
        const Center(
          child: Text.rich(
            TextSpan(
              style: TextStyle(color: black, fontSize: 12),
              text: 'parent ',
              children: <InlineSpan>[
                TextSpan(text: 'inherits'),
                TextSpan(
                  text: ' overrides',
                  style: TextStyle(color: grey),
                ),
              ],
            ),
          ),
        ),
      );

      final texts = audit.allPaints
          .where((paint) => paint.role == PaintRole.text)
          .map((paint) => paint.color)
          .toSet();

      expect(texts, containsAll(<Color>[black, grey]));
    });

    testWidgets('refuses to invent a colour for shader text', (tester) async {
      final audit = await pump(
        tester,
        Center(
          child: Text(
            'shader',
            style: TextStyle(foreground: Paint()..color = black, fontSize: 12),
          ),
        ),
      );

      expect(audit.skipsBecause(SkipReason.shaderForeground), isNotEmpty);
      expect(
        audit.allPaints.where((paint) => paint.role == PaintRole.text),
        isEmpty,
      );
    });

    testWidgets(
      'reports an unrecognised painting node instead of ignoring it',
      (tester) async {
        final audit = await pump(
          tester,
          CustomPaint(painter: _NoopPainter(), size: const Size(50, 50)),
        );

        expect(audit.skipsBecause(SkipReason.customPainter), isNotEmpty);
      },
    );

    testWidgets('large text is judged at 3:1, small text at 4.5:1', (
      tester,
    ) async {
      // 4.54:1 — passes as normal text, and would also pass as large. The pair
      // that matters is the threshold selection itself.
      const paint = AuditPaint(
        role: PaintRole.text,
        color: black,
        rect: Rect.zero,
        source: PaintSource.declared,
        origin: 'probe',
        fontSize: 24,
      );

      expect(paint.isLargeText, isTrue);
      expect(
        const AuditPaint(
          role: PaintRole.text,
          color: black,
          rect: Rect.zero,
          source: PaintSource.declared,
          origin: 'probe',
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ).isLargeText,
        isTrue,
      );
      // Unknown size must buy the stricter bar, never the looser one.
      expect(
        const AuditPaint(
          role: PaintRole.text,
          color: black,
          rect: Rect.zero,
          source: PaintSource.declared,
          origin: 'probe',
        ).isLargeText,
        isFalse,
      );
    });
  });

  group('raster', () {
    testWidgets('reads the ground around a glyph that fills its own box', (
      tester,
    ) async {
      // A filled glyph on a pill painted into the Material ink layer: no render
      // object carries the pill, and the glyph covers most of its own box, so
      // the band around the glyph is the only witness of its ground. Without
      // that band the rule falls back to the white Material behind the pill
      // and reports white on white (M100.93, the navigation bar's pill).
      const pill = Color(0xFF283593);
      final audit = await pump(
        tester,
        Material(
          color: white,
          child: Center(
            child: Ink(
              width: 64,
              height: 32,
              decoration: const ShapeDecoration(
                color: pill,
                shape: StadiumBorder(),
              ),
              child: const Center(
                child: Icon(Icons.square, size: 24, color: white),
              ),
            ),
          ),
        ),
      );

      final grounds = audit.allPaints.where(
        (paint) =>
            paint.source == PaintSource.raster &&
            paint.origin.startsWith('raster ring'),
      );
      expect(grounds.map((paint) => paint.color), contains(pill));
      expect(
        runAuditRules(audit, const <AuditRule>[
          TextContrastRule(),
        ]).where((finding) => finding.isBlocking),
        isEmpty,
        reason: 'the white glyph was judged against white, not its pill',
      );
    });

    testWidgets('sees an ink overlay that exists in no render object', (
      tester,
    ) async {
      // The case that justifies the raster pass at all: `Ink` paints onto the
      // Material, so a highlight has no render object to read.
      final audit = await pump(
        tester,
        Center(
          child: Material(
            color: white,
            child: Ink(
              width: 100,
              height: 100,
              color: black,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );

      final rasterColours = audit.allPaints
          .where((paint) => paint.source == PaintSource.raster)
          .map((paint) => paint.color)
          .toSet();

      expect(rasterColours, contains(black));
      // Named for the measurement, not for a cause nobody proved: the image
      // disagreeing with the declaration is the fact; "occluded" would be a
      // guess at why.
      expect(audit.skipsBecause(SkipReason.declaredRasterMismatch), isNotEmpty);
    });
  });
}

class _NoopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
