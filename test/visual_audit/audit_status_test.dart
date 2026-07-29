import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audit_model.dart';
import 'audit_report.dart';
import 'audit_rules.dart';

/// Status, allowances, and the two bars a caller can ask for.
///
/// The distinction under test is the one a red/green result cannot express: a
/// screen with nothing wrong is not the same as a screen with nothing left
/// unread, and CI has to be able to tell them apart without a human reading the
/// log.
void main() {
  ScreenAudit auditWith({
    List<AuditSkip> skips = const <AuditSkip>[],
    List<AuditPaint> paints = const <AuditPaint>[],
  }) => ScreenAudit(
    screen: 'probe',
    theme: 'light',
    state: 'idle',
    viewport: const Size(300, 300),
    items: <AuditItem>[
      AuditItem(id: 'search', rect: Rect.zero, paints: paints),
    ],
    skips: skips,
  );

  const painterSkip = AuditSkip(
    itemId: 'search',
    reason: SkipReason.customPainter,
    detail: 'CustomPaint (_InputBorderPainter)',
  );

  const noRules = <AuditRule>[];

  group('status', () {
    test('nothing wrong and nothing unread is PASS', () {
      expect(evaluateAudit(auditWith(), noRules).status, AuditStatus.pass);
    });

    test('an unresolved skip is PASS_WITH_UNRESOLVED, not PASS', () {
      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[painterSkip]),
        noRules,
      );

      expect(outcome.status, AuditStatus.passWithUnresolved);
      expect(outcome.unresolvedSkips, hasLength(1));
    });

    test('a blocking finding is FAIL', () {
      final outcome = evaluateAudit(
        auditWith(
          paints: <AuditPaint>[
            const AuditPaint(
              role: PaintRole.fill,
              color: Color(0xFF123456),
              rect: Rect.zero,
              source: PaintSource.declared,
              origin: 'probe',
            ),
          ],
        ),
        <AuditRule>[const PaletteClosureRule(<Color>[])],
      );

      expect(outcome.status, AuditStatus.fail);
    });

    test('a non-blocking finding also counts as unresolved', () {
      // It is a thing the audit could not settle. Letting it reach PASS would
      // put "the image shows a colour nobody can explain" behind a green tick.
      final outcome = evaluateAudit(
        auditWith(
          paints: <AuditPaint>[
            const AuditPaint(
              role: PaintRole.fill,
              color: Color(0xFF7F3B12),
              rect: Rect.zero,
              source: PaintSource.raster,
              origin: 'raster',
            ),
          ],
        ),
        <AuditRule>[const PaletteClosureRule(<Color>[])],
      );

      expect(outcome.status, AuditStatus.passWithUnresolved);
    });
  });

  group('expectation', () {
    test('noViolations accepts PASS_WITH_UNRESOLVED, complete does not', () {
      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[painterSkip]),
        noRules,
      );

      expect(outcome.satisfies(AuditExpectation.noViolations), isTrue);
      expect(outcome.satisfies(AuditExpectation.complete), isFalse);
    });

    test('neither accepts FAIL', () {
      final outcome = evaluateAudit(
        auditWith(
          paints: <AuditPaint>[
            const AuditPaint(
              role: PaintRole.text,
              color: Color(0xFF123456),
              rect: Rect.zero,
              source: PaintSource.declared,
              origin: 'probe',
            ),
          ],
        ),
        <AuditRule>[const PaletteClosureRule(<Color>[])],
      );

      expect(outcome.satisfies(AuditExpectation.noViolations), isFalse);
      expect(outcome.satisfies(AuditExpectation.complete), isFalse);
    });
  });

  group('allowance', () {
    const allowance = AuditSkipAllowance(
      itemId: 'search',
      reason: SkipReason.customPainter,
      detailContains: '_InputBorderPainter',
      rationale: 'Focused border is covered by the state raster audit in M5.',
    );

    test('a matching allowance resolves the skip and reaches PASS', () {
      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[painterSkip]),
        noRules,
        allowances: const <AuditSkipAllowance>[allowance],
      );

      expect(outcome.status, AuditStatus.pass);
      expect(outcome.allowedSkips, hasLength(1));
      expect(outcome.unusedAllowances, isEmpty);
    });

    test('it does not reach a different item', () {
      // The whole reason allowances are scoped. A blanket
      // `{SkipReason.customPainter}` would wave through every painter on the
      // screen, including ones added long after anyone checked.
      const elsewhere = AuditSkip(
        itemId: 'flashcard',
        reason: SkipReason.customPainter,
        detail: 'CustomPaint (_InputBorderPainter)',
      );

      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[elsewhere]),
        noRules,
        allowances: const <AuditSkipAllowance>[allowance],
      );

      expect(outcome.status, AuditStatus.passWithUnresolved);
      expect(outcome.unresolvedSkips, hasLength(1));
    });

    test('the detail matcher narrows it further', () {
      const otherPainter = AuditSkip(
        itemId: 'search',
        reason: SkipReason.customPainter,
        detail: 'CustomPaint (_SomeNewPainter)',
      );

      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[otherPainter]),
        noRules,
        allowances: const <AuditSkipAllowance>[allowance],
      );

      expect(outcome.unresolvedSkips, hasLength(1));
      expect(outcome.unusedAllowances, hasLength(1));
    });

    test('an unused allowance is reported and blocks completeness', () {
      // A standing permission for a problem that no longer exists reads as
      // coverage to the next person. It has to expire loudly.
      final outcome = evaluateAudit(
        auditWith(),
        noRules,
        allowances: const <AuditSkipAllowance>[allowance],
      );

      expect(outcome.unusedAllowances, hasLength(1));
      expect(outcome.status, AuditStatus.passWithUnresolved);
      expect(outcome.satisfies(AuditExpectation.complete), isFalse);
      expect(outcome.describe(), contains('UNUSED ALLOWANCE'));
    });
  });

  group('report', () {
    test('the text report leads with the status, not with a paint count', () {
      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[painterSkip]),
        noRules,
      );

      expect(outcome.describe(), startsWith('PASS_WITH_UNRESOLVED'));
    });

    test('the JSON carries status, coverage and both skip lists', () {
      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[painterSkip]),
        noRules,
      );

      final json = auditToJson(outcome);

      expect(json, contains('"status": "PASS_WITH_UNRESOLVED"'));
      expect(json, contains('"unresolvedSkips": 1'));
      expect(json, contains('customPainter'));
    });
  });
}
