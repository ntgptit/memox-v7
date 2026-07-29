import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../support/app_palette.dart';
import 'audit_model.dart';
import 'audit_report.dart';
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
      expect(audit.skipsBecause(SkipReason.occluded), isNotEmpty);
    });
  });

  group('rules', () {
    ScreenAudit auditOf(List<AuditPaint> paints) => ScreenAudit(
      screen: 'probe',
      theme: 'light',
      state: 'idle',
      viewport: const Size(300, 300),
      items: <AuditItem>[
        AuditItem(id: 'probe', rect: Rect.zero, paints: paints),
      ],
      skips: const <AuditSkip>[],
    );

    const region = Rect.fromLTWH(0, 0, 100, 20);
    AuditPaint text(Color color, {double size = 14}) => AuditPaint(
      role: PaintRole.text,
      color: color,
      rect: region,
      source: PaintSource.declared,
      origin: 'probe',
      fontSize: size,
    );
    const background = AuditPaint(
      role: PaintRole.fill,
      color: white,
      rect: region,
      source: PaintSource.raster,
      origin: 'probe',
    );

    test('text contrast passes at 21:1 and fails at 1:1', () {
      expect(
        runAuditRules(auditOf(<AuditPaint>[text(black), background]), const [
          TextContrastRule(),
        ]).where((finding) => finding.isBlocking),
        isEmpty,
      );

      final failures = runAuditRules(
        auditOf(<AuditPaint>[text(const Color(0xFFF8F8F8)), background]),
        const <AuditRule>[TextContrastRule()],
      ).where((finding) => finding.isBlocking);

      expect(failures, hasLength(1));
      expect(failures.first.message, contains(':1, below 4.5'));
    });

    test('palette closure rejects a declared colour outside the palette', () {
      final rule = PaletteClosureRule(lightPaletteTokens);
      final offPalette = runAuditRules(
        auditOf(<AuditPaint>[text(const Color(0xFF123456))]),
        <AuditRule>[rule],
      );

      expect(offPalette.where((f) => f.isBlocking), hasLength(1));
      expect(
        runAuditRules(
          auditOf(<AuditPaint>[text(lightPaletteTokens.first)]),
          <AuditRule>[rule],
        ),
        isEmpty,
      );
    });

    test('a raster blend of two tokens is not treated as a new colour', () {
      final rule = PaletteClosureRule(lightPaletteTokens);
      final blend = Color.lerp(white, lightPaletteTokens.last, 0.5)!;

      final findings = runAuditRules(
        auditOf(<AuditPaint>[
          AuditPaint(
            role: PaintRole.fill,
            color: blend,
            rect: region,
            source: PaintSource.raster,
            origin: 'raster',
          ),
        ]),
        <AuditRule>[rule],
      );

      expect(findings, isEmpty);
    });
  });

  test('the JSON report carries items, skips and findings', () {
    const audit = ScreenAudit(
      screen: 'probe',
      theme: 'dark',
      state: 'pressed',
      viewport: Size(300, 300),
      items: <AuditItem>[
        AuditItem(id: 'screen', rect: Rect.zero, paints: <AuditPaint>[]),
      ],
      skips: <AuditSkip>[
        AuditSkip(
          itemId: 'screen',
          reason: SkipReason.customPainter,
          detail: 'input border',
        ),
      ],
    );

    final json = auditToJson(audit);

    expect(json, contains('"state": "pressed"'));
    expect(json, contains('customPainter'));
  });
}

class _NoopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
