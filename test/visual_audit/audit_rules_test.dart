import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_palette.dart';
import 'audit_model.dart';
import 'audit_rules.dart';

/// Rules judged on synthetic audits, where the right answer is known before the
/// test runs.
///
/// The palette-closure pair is the important one: **declared and raster are held
/// to different bars**, and a test that only proves the lenient half would let
/// the strict half rot without saying so.
void main() {
  const white = Color(0xFFFFFFFF);
  const black = Color(0xFF000000);
  const region = Rect.fromLTWH(0, 0, 100, 20);

  ScreenAudit auditOf(List<AuditPaint> paints) => ScreenAudit(
    screen: 'probe',
    theme: 'light',
    state: 'idle',
    viewport: const Size(300, 300),
    items: <AuditItem>[AuditItem(id: 'probe', rect: region, paints: paints)],
    skips: const <AuditSkip>[],
  );

  AuditPaint paintOf(
    Color color, {
    required PaintSource source,
    PaintRole role = PaintRole.fill,
    double? size,
  }) => AuditPaint(
    role: role,
    color: color,
    rect: region,
    source: source,
    origin: 'probe',
    fontSize: size,
  );

  List<AuditFinding> closureOn(AuditPaint paint) => runAuditRules(
    auditOf(<AuditPaint>[paint]),
    <AuditRule>[PaletteClosureRule(lightPaletteTokens)],
  );

  group('palette closure · declared', () {
    test('an exact token passes', () {
      expect(
        closureOn(
          paintOf(lightPaletteTokens.first, source: PaintSource.declared),
        ),
        isEmpty,
      );
    });

    test('a blend of two tokens FAILS', () {
      // The hole this closes. With forty tokens the segments between them cover
      // a great deal of colour space, so a hardcoded value lands on one often
      // enough to matter — and the rule was then certifying it as on-palette.
      // Code that wants a state layer must compute it from tokens somewhere the
      // palette can see, not smuggle it past the check.
      final blend = Color.lerp(
        lightPaletteTokens.first,
        lightPaletteTokens.last,
        0.5,
      )!;

      final findings = closureOn(
        paintOf(blend, source: PaintSource.declared),
      ).where((finding) => finding.isBlocking);

      expect(findings, hasLength(1));
      expect(findings.first.message, contains('is not a palette token'));
    });

    test('a hardcoded colour outside the palette fails', () {
      expect(
        closureOn(
          paintOf(const Color(0xFF123456), source: PaintSource.declared),
        ).where((finding) => finding.isBlocking),
        hasLength(1),
      );
    });
  });

  group('palette closure · raster', () {
    test('an exact token passes', () {
      expect(
        closureOn(
          paintOf(lightPaletteTokens.first, source: PaintSource.raster),
        ),
        isEmpty,
      );
    });

    test('a blend of two tokens passes', () {
      // Antialiasing and alpha compositing produce exactly this. Holding the
      // image to the same bar as the source would make every rounded corner a
      // violation.
      final blend = Color.lerp(white, lightPaletteTokens.last, 0.5)!;

      expect(closureOn(paintOf(blend, source: PaintSource.raster)), isEmpty);
    });

    test('a colour that is neither is reported, but does not block', () {
      // A teal-green: no token in this palette is near it and no pair of them
      // blends to it. It was an orange-brown until M100.32, when `warning` was
      // retuned a step darker and the old fixture fell *inside* the closure —
      // so the rule stopped reporting and this self-test caught it. The fixture
      // is the thing that has to be outside; the rule was right both times.
      final findings = closureOn(
        paintOf(const Color(0xFF1F7A5A), source: PaintSource.raster),
      );

      expect(findings, hasLength(1));
      expect(findings.single.isBlocking, isFalse);
      expect(findings.single.message, contains('something is compositing'));
    });
  });

  group('contrast', () {
    const background = AuditPaint(
      role: PaintRole.fill,
      color: white,
      rect: region,
      source: PaintSource.raster,
      origin: 'probe',
    );

    test('text passes at 21:1 and fails at 1:1', () {
      expect(
        runAuditRules(
          auditOf(<AuditPaint>[
            paintOf(
              black,
              source: PaintSource.declared,
              role: PaintRole.text,
              size: 14,
            ),
            background,
          ]),
          const <AuditRule>[TextContrastRule()],
        ).where((finding) => finding.isBlocking),
        isEmpty,
      );

      final failures = runAuditRules(
        auditOf(<AuditPaint>[
          paintOf(
            const Color(0xFFF8F8F8),
            source: PaintSource.declared,
            role: PaintRole.text,
            size: 14,
          ),
          background,
        ]),
        const <AuditRule>[TextContrastRule()],
      ).where((finding) => finding.isBlocking);

      expect(failures, hasLength(1));
      expect(failures.first.message, contains(':1, below 4.5'));
    });

    test('a non-informational border is not held to 3:1', () {
      // 1.4.11 covers what identifies a component or its state. A decorative
      // hairline is neither, and forcing it to 3:1 would turn every card outline
      // into a hard rule.
      final findings = runAuditRules(
        auditOf(<AuditPaint>[
          paintOf(
            const Color(0xFFF4F4F4),
            source: PaintSource.declared,
            role: PaintRole.border,
          ),
          background,
        ]),
        const <AuditRule>[NonTextContrastRule(<Color>[])],
      );

      expect(findings, isEmpty);
    });

    test('an informational border below 3:1 blocks', () {
      const focus = Color(0xFFF4F4F4);
      final findings = runAuditRules(
        auditOf(<AuditPaint>[
          paintOf(focus, source: PaintSource.declared, role: PaintRole.border),
          background,
        ]),
        const <AuditRule>[
          NonTextContrastRule(<Color>[focus]),
        ],
      ).where((finding) => finding.isBlocking);

      expect(findings, hasLength(1));
      expect(findings.first.message, contains('below 3.0'));
    });
  });
}
