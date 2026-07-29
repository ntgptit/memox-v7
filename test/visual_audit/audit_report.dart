import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'audit_allowance.dart';
import 'audit_model.dart';
import 'audit_rules.dart';

/// What a caller is asking the audit to prove.
enum AuditExpectation {
  /// Nothing on this screen is wrong. Parts of it may still be unmeasured, and
  /// the report says which — the right bar while a screen is being built, when
  /// unread nodes are expected and useful as a to-do list.
  noViolations,

  /// Nothing is wrong *and* nothing was left unread. The production gate: every
  /// unresolved node must either be measurable or carry a written allowance.
  complete,
}

/// The whole result of judging one screen.
@immutable
class AuditOutcome {
  const AuditOutcome({
    required this.audit,
    required this.status,
    required this.findings,
    required this.unresolvedSkips,
    required this.allowedSkips,
    required this.allowanceConflicts,
    required this.unusedAllowances,
    required this.miscountedAllowances,
    required this.coverage,
  });

  final ScreenAudit audit;
  final AuditStatus status;
  final List<AuditFinding> findings;

  /// Skips nobody has accounted for. These are what separate [AuditStatus.pass]
  /// from [AuditStatus.passWithUnresolved].
  final List<AuditSkip> unresolvedSkips;

  /// Each accounted-for skip **with the allowance that accounted for it**.
  ///
  /// The pairing is the point: the rationale is the only part of an allowance
  /// anyone will need later, and dropping it at match time leaves a report that
  /// can say "four allowed" and nothing about whether those four permissions are
  /// still true.
  final List<AuditAllowedSkip> allowedSkips;

  /// Skips that more than one allowance claimed.
  ///
  /// Left unresolved rather than settled by picking the first: with two
  /// overlapping permissions nobody can say which promise is being relied on,
  /// and a broad allowance behind a narrow one keeps working long after the
  /// narrow one stops being true.
  final List<AuditAllowanceConflict> allowanceConflicts;

  /// Allowances that matched nothing.
  ///
  /// Reported, and fatal in [AuditExpectation.complete]: a stale allowance is a
  /// standing permission for a problem that no longer exists, and it will be
  /// read as coverage by whoever comes next.
  final List<AuditSkipAllowance> unusedAllowances;

  /// Allowances that covered a different number of skips than they declared.
  ///
  /// The direction nobody was checking: substring matching lets one permission
  /// quietly cover several nodes, only one of which anyone looked at.
  final List<AuditAllowanceMiscount> miscountedAllowances;

  final AuditCoverage coverage;

  Iterable<AuditFinding> get blocking =>
      findings.where((finding) => finding.isBlocking);

  Iterable<AuditFinding> get notes =>
      findings.where((finding) => !finding.isBlocking);

  bool satisfies(AuditExpectation expectation) => switch (expectation) {
    AuditExpectation.noViolations => status != AuditStatus.fail,
    AuditExpectation.complete => status == AuditStatus.pass,
  };

  /// Report text. Always starts with the status, because "8 items, 32 paints"
  /// reads as a clean bill of health and is not one.
  String describe() {
    final report = StringBuffer()
      ..writeln('${status.label}  ${audit.label}')
      ..writeln(
        '  ${coverage.items} items · ${coverage.paints} paints · '
        '${coverage.blockingFindings} blocking · '
        '${coverage.nonBlockingFindings} notes · '
        '${coverage.unresolvedSkips} unresolved · '
        '${coverage.allowedSkips} allowed · '
        '${coverage.unusedAllowances} unused · '
        '${coverage.allowanceConflicts} conflicts · '
        '${coverage.miscountedAllowances} miscounted · '
        '${coverage.hiddenNodes} hidden · '
        '${coverage.outsideCaptureNodes} off-surface · '
        '${coverage.clippedNodes} clipped',
      );

    for (final finding in findings) {
      report.writeln('  $finding');
    }
    for (final skip in unresolvedSkips) {
      report.writeln('  unresolved  $skip');
    }
    // Printed in full, rationale included. An allowance is a claim that someone
    // verified this another way, and a claim only stays honest while it is
    // visible next to the thing it excuses.
    for (final allowed in allowedSkips) {
      report.writeln('  allowed  $allowed');
    }
    for (final conflict in allowanceConflicts) {
      report.writeln('  AMBIGUOUS ALLOWANCE  $conflict');
    }
    for (final miscount in miscountedAllowances) {
      report.writeln('  MISCOUNTED ALLOWANCE  $miscount');
    }
    for (final allowance in unusedAllowances) {
      report.writeln('  UNUSED ALLOWANCE  $allowance');
    }

    return report.toString().trimRight();
  }
}

/// Judges [audit] without asserting anything.
AuditOutcome evaluateAudit(
  ScreenAudit audit,
  List<AuditRule> rules, {
  List<AuditSkipAllowance> allowances = const <AuditSkipAllowance>[],
}) {
  validateAllowances(allowances);

  final findings = runAuditRules(audit, rules);
  final blocking = findings.where((finding) => finding.isBlocking).toList();
  final notes = findings.where((finding) => !finding.isBlocking).toList();

  final allowed = <AuditAllowedSkip>[];
  final conflicts = <AuditAllowanceConflict>[];
  final unresolved = <AuditSkip>[];
  final accountedFor = <AuditSkipAllowance>{};

  for (final skip in audit.skips) {
    final matched = allowances
        .where((allowance) => allowance.matches(skip))
        .toList();

    if (matched.isEmpty) {
      unresolved.add(skip);

      continue;
    }

    if (matched.length > 1) {
      conflicts.add(AuditAllowanceConflict(skip: skip, allowances: matched));
      // Recorded as involved so they do not ALSO appear as unused — the
      // conflict entry already names them, and listing the same allowance twice
      // under two headings trains people to skim.
      accountedFor.addAll(matched);

      continue;
    }

    accountedFor.add(matched.single);
    allowed.add(AuditAllowedSkip(skip: skip, allowance: matched.single));
  }

  final unused = <AuditSkipAllowance>[];
  final miscounted = <AuditAllowanceMiscount>[];

  for (final allowance in allowances) {
    // Counted against every skip, not just the ones it resolved: an allowance
    // that also matched a skip somebody else claimed has still widened its
    // reach, and that is exactly what this number exists to show.
    final actual = audit.skips.where(allowance.matches).length;

    if (actual == 0) {
      unused.add(allowance);

      continue;
    }
    if (actual == allowance.expectedMatches) continue;

    miscounted.add(
      AuditAllowanceMiscount(allowance: allowance, actualMatches: actual),
    );
  }

  // A non-blocking finding is something the audit could not settle, so it counts
  // toward "unresolved" exactly like an unread node does. Treating it as clean
  // would let a screen reach PASS while the report still says the image shows a
  // colour nobody can explain.
  final isComplete =
      unresolved.isEmpty &&
      unused.isEmpty &&
      conflicts.isEmpty &&
      miscounted.isEmpty &&
      notes.isEmpty;

  final status = blocking.isNotEmpty
      ? AuditStatus.fail
      : isComplete
      ? AuditStatus.pass
      : AuditStatus.passWithUnresolved;

  return AuditOutcome(
    audit: audit,
    status: status,
    findings: findings,
    unresolvedSkips: unresolved,
    allowedSkips: allowed,
    allowanceConflicts: conflicts,
    unusedAllowances: unused,
    miscountedAllowances: miscounted,
    coverage: AuditCoverage(
      items: audit.items.length,
      paints: audit.allPaints.length,
      blockingFindings: blocking.length,
      nonBlockingFindings: notes.length,
      unresolvedSkips: unresolved.length,
      allowedSkips: allowed.length,
      unusedAllowances: unused.length,
      allowanceConflicts: conflicts.length,
      miscountedAllowances: miscounted.length,
      hiddenNodes: audit.hiddenNodes,
      outsideCaptureNodes: audit.outsideCaptureNodes,
      clippedNodes: audit.clippedNodes,
    ),
  );
}

/// Prints the report and asserts the outcome meets [expectation].
///
/// The name this replaced — `expectAuditClean` — was a lie by omission: it
/// passed a screen with eleven unread nodes and said nothing about the
/// difference. The bar now lives in the call, so a reader of the test can see
/// which one was asked for.
AuditOutcome expectAudit(
  ScreenAudit audit,
  List<AuditRule> rules, {
  required AuditExpectation expectation,
  List<AuditSkipAllowance> allowances = const <AuditSkipAllowance>[],
}) {
  final outcome = evaluateAudit(audit, rules, allowances: allowances);

  // Unconditional, not `printOnFailure`: the unread list is the point, and
  // showing it only when something else already broke is showing it to nobody.
  debugPrint(outcome.describe());

  expect(
    outcome.satisfies(expectation),
    isTrue,
    reason:
        'expected ${expectation.name}, got ${outcome.status.label}\n'
        '${outcome.describe()}',
  );

  return outcome;
}

/// Nothing is wrong. Unmeasured parts are listed and permitted.
AuditOutcome expectAuditNoViolations(
  ScreenAudit audit,
  List<AuditRule> rules, {
  List<AuditSkipAllowance> allowances = const <AuditSkipAllowance>[],
}) => expectAudit(
  audit,
  rules,
  expectation: AuditExpectation.noViolations,
  allowances: allowances,
);

/// Nothing is wrong and nothing is unmeasured.
AuditOutcome expectAuditComplete(
  ScreenAudit audit,
  List<AuditRule> rules, {
  List<AuditSkipAllowance> allowances = const <AuditSkipAllowance>[],
}) => expectAudit(
  audit,
  rules,
  expectation: AuditExpectation.complete,
  allowances: allowances,
);

/// Machine-readable form, for diffing two runs or handing to another tool.
String auditToJson(AuditOutcome outcome) {
  final audit = outcome.audit;

  return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
    'status': outcome.status.label,
    'screen': audit.screen,
    'theme': audit.theme,
    'state': audit.state,
    'viewport': <String, double>{
      'width': audit.viewport.width,
      'height': audit.viewport.height,
    },
    'coverage': outcome.coverage.toJson(),
    'items': <Object>[
      for (final item in audit.items)
        <String, Object?>{
          'id': item.id,
          'rect': _rect(item),
          'paints': <Object>[
            for (final paint in item.paints)
              <String, Object?>{
                'role': paint.role.name,
                'source': paint.source.name,
                'color': hexOf(paint.color),
                'origin': paint.origin,
                if (paint.fontSize != null) 'fontSize': paint.fontSize,
                if (paint.role == PaintRole.text)
                  'largeText': paint.isLargeText,
              },
          ],
        },
    ],
    'unresolvedSkips': <Object>[
      for (final skip in outcome.unresolvedSkips)
        <String, Object?>{
          'item': skip.itemId,
          'reason': skip.reason.name,
          'detail': skip.detail,
        },
    ],
    'allowedSkips': <Object>[
      for (final allowed in outcome.allowedSkips)
        <String, Object?>{
          'item': allowed.skip.itemId,
          'reason': allowed.skip.reason.name,
          'detail': allowed.skip.detail,
          'allowance': <String, Object?>{
            'detailContains': allowed.allowance.detailContains,
            'rationale': allowed.allowance.rationale,
          },
        },
    ],
    'allowanceConflicts': <Object>[
      for (final conflict in outcome.allowanceConflicts)
        <String, Object?>{
          'item': conflict.skip.itemId,
          'reason': conflict.skip.reason.name,
          'detail': conflict.skip.detail,
          'matchedBy': <Object>[
            for (final allowance in conflict.allowances)
              <String, Object?>{
                'detailContains': allowance.detailContains,
                'rationale': allowance.rationale,
              },
          ],
        },
    ],
    'unusedAllowances': <Object>[
      for (final allowance in outcome.unusedAllowances)
        <String, Object?>{
          'item': allowance.itemId,
          'reason': allowance.reason.name,
          'detailContains': allowance.detailContains,
          'rationale': allowance.rationale,
        },
    ],
    'miscountedAllowances': <Object>[
      for (final miscount in outcome.miscountedAllowances)
        <String, Object?>{
          'item': miscount.allowance.itemId,
          'detailContains': miscount.allowance.detailContains,
          'expected': miscount.allowance.expectedMatches,
          'actual': miscount.actualMatches,
        },
    ],
    'findings': <Object>[
      for (final finding in outcome.findings)
        <String, Object?>{
          'rule': finding.rule,
          'item': finding.itemId,
          'blocking': finding.isBlocking,
          'message': finding.message,
        },
    ],
  });
}

List<double> _rect(AuditItem item) => <double>[
  item.rect.left,
  item.rect.top,
  item.rect.width,
  item.rect.height,
];
