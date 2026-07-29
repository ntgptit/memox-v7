import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audit_allowance.dart';
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

    test('the allowed entry keeps both halves of the pair', () {
      // The rationale is the only part anyone needs six months later, and
      // dropping it at match time leaves a report that can say "one allowed"
      // and nothing about whether that permission is still true.
      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[painterSkip]),
        noRules,
        allowances: const <AuditSkipAllowance>[allowance],
      );

      expect(outcome.allowedSkips.single.skip, painterSkip);
      expect(outcome.allowedSkips.single.allowance, allowance);
    });

    test('the text report prints the rationale, not just a count', () {
      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[painterSkip]),
        noRules,
        allowances: const <AuditSkipAllowance>[allowance],
      );

      expect(outcome.describe(), contains('allowed'));
      expect(outcome.describe(), contains('because: ${allowance.rationale}'));
    });

    test('the JSON pairs each allowed skip with its allowance', () {
      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[painterSkip]),
        noRules,
        allowances: const <AuditSkipAllowance>[allowance],
      );

      final json = auditToJson(outcome);

      expect(json, contains('"detailContains": "_InputBorderPainter"'));
      expect(json, contains(allowance.rationale));
      expect(json, contains('"allowedSkips": 1'));
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

    test('two allowances on one skip are ambiguous, not allowed', () {
      // Picking the first would mean nobody can say which promise is being
      // relied on, and a broad allowance sitting behind a narrow one keeps
      // working long after the narrow one stops being true.
      const broad = AuditSkipAllowance(
        itemId: 'search',
        reason: SkipReason.customPainter,
        detailContains: 'CustomPaint',
        rationale: 'Everything painted by hand on this field.',
      );

      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[painterSkip]),
        noRules,
        allowances: const <AuditSkipAllowance>[allowance, broad],
      );

      expect(outcome.allowanceConflicts, hasLength(1));
      expect(outcome.allowanceConflicts.single.allowances, hasLength(2));
      expect(outcome.allowedSkips, isEmpty);
      expect(outcome.status, AuditStatus.passWithUnresolved);
      expect(outcome.satisfies(AuditExpectation.complete), isFalse);
      expect(outcome.describe(), contains('AMBIGUOUS ALLOWANCE'));
      expect(outcome.coverage.allowanceConflicts, 1);
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

  group('allowance validation', () {
    AuditSkipAllowance build({
      String itemId = 'search',
      String detailContains = 'painter',
      String rationale = 'checked elsewhere',
    }) => AuditSkipAllowance(
      itemId: itemId,
      reason: SkipReason.customPainter,
      detailContains: detailContains,
      rationale: rationale,
    );

    test('an empty itemId is rejected at construction', () {
      expect(() => build(itemId: ''), throwsA(isA<AssertionError>()));
    });

    test('an empty detailContains is rejected at construction', () {
      // Without it an allowance covers every skip of its reason on its item,
      // including the one added six months later that nobody has looked at.
      expect(() => build(detailContains: ''), throwsA(isA<AssertionError>()));
    });

    test('an empty rationale is rejected at construction', () {
      expect(() => build(rationale: ''), throwsA(isA<AssertionError>()));
    });

    test('whitespace-only fields are rejected before evaluation', () {
      // A `const` constructor can only assert on constant expressions, so
      // `trim()` cannot run there. This is the second gate.
      for (final blank in <AuditSkipAllowance>[
        build(itemId: '   '),
        build(detailContains: ' 	 '),
        build(rationale: '  '),
      ]) {
        expect(
          () => evaluateAudit(
            auditWith(),
            noRules,
            allowances: <AuditSkipAllowance>[blank],
          ),
          throwsA(isA<ArgumentError>()),
          reason: blank.toString(),
        );
      }
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
