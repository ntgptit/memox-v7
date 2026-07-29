import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audit_allowance.dart';
import 'audit_model.dart';
import 'audit_report.dart';
import 'audit_rules.dart';

/// Allowances: how narrow they must be, how many skips each may cover, and what
/// happens when two of them claim the same one.
///
/// An allowance is a promise that a human checked something another way. Every
/// rule here exists to stop that promise from quietly widening — into a second
/// node nobody looked at, into a second permission nobody can choose between, or
/// into a screen it no longer describes.
void main() {
  ScreenAudit auditWith({List<AuditSkip> skips = const <AuditSkip>[]}) =>
      ScreenAudit(
        screen: 'probe',
        theme: 'light',
        state: 'idle',
        viewport: const Size(300, 300),
        items: const <AuditItem>[
          AuditItem(id: 'search', rect: Rect.zero, paints: <AuditPaint>[]),
        ],
        skips: skips,
      );

  const painterSkip = AuditSkip(
    itemId: 'search',
    reason: SkipReason.customPainter,
    detail: 'CustomPaint (_InputBorderPainter)',
  );

  const noRules = <AuditRule>[];

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

    test('one allowance covering several skips is a miscount', () {
      // The direction nobody was checking, and it was live in this repo: an
      // allowance written for `RenderEditable` also swallowed two
      // `_RenderEditableCustomPaint` nodes, because the second string contains
      // the first. Three nodes excused, one of them examined.
      const second = AuditSkip(
        itemId: 'search',
        reason: SkipReason.customPainter,
        detail: 'CustomPaint (_InputBorderPainterExtra)',
      );

      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[painterSkip, second]),
        noRules,
        allowances: const <AuditSkipAllowance>[allowance],
      );

      expect(outcome.miscountedAllowances, hasLength(1));
      expect(outcome.miscountedAllowances.single.actualMatches, 2);
      expect(outcome.miscountedAllowances.single.isOverbroad, isTrue);
      expect(outcome.satisfies(AuditExpectation.complete), isFalse);
      expect(outcome.describe(), contains('MISCOUNTED ALLOWANCE'));
    });

    test('a declared count of several is accepted when it is exact', () {
      const second = AuditSkip(
        itemId: 'search',
        reason: SkipReason.customPainter,
        detail: 'CustomPaint (_InputBorderPainterExtra)',
      );
      const two = AuditSkipAllowance(
        itemId: 'search',
        reason: SkipReason.customPainter,
        detailContains: '_InputBorderPainter',
        expectedMatches: 2,
        rationale:
            'Both painters draw the same border; one M5 audit covers them.',
      );

      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[painterSkip, second]),
        noRules,
        allowances: const <AuditSkipAllowance>[two],
      );

      expect(outcome.miscountedAllowances, isEmpty);
      expect(outcome.status, AuditStatus.pass);
    });

    test('covering fewer than declared is also a miscount', () {
      // A permission that no longer describes the screen is stale for the same
      // reason an unused one is, and it must expire just as loudly.
      const two = AuditSkipAllowance(
        itemId: 'search',
        reason: SkipReason.customPainter,
        detailContains: '_InputBorderPainter',
        expectedMatches: 2,
        rationale: 'Two painters were here when this was written.',
      );

      final outcome = evaluateAudit(
        auditWith(skips: <AuditSkip>[painterSkip]),
        noRules,
        allowances: const <AuditSkipAllowance>[two],
      );

      expect(outcome.miscountedAllowances, hasLength(1));
      expect(outcome.miscountedAllowances.single.isOverbroad, isFalse);
      expect(outcome.satisfies(AuditExpectation.complete), isFalse);
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
}
