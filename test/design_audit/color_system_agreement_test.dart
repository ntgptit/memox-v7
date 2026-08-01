import 'package:flutter_test/flutter_test.dart';

import 'audit_scan_steps.dart';
import 'color_rule_scope.dart';
import 'color_usage_scan.dart';

/// **Two audits reading the same `lib/` must not reach two verdicts.**
///
/// The repo checks colour twice, on purpose and with different jobs:
/// `color_source_rules_test.dart` is a gate that fails a build, and
/// `design_audit/` is a report a human reads. They share the scanner, so they
/// see identical sites — and until now they classified them differently. R7
/// exempted foreground and label alpha; the V5 step exempted only `shadow` and
/// `scrim`.
///
/// The consequence was not a wrong colour, it was worse: the report permanently
/// carried one 🟢 nobody could clear, because the fix it proposed — precomputing
/// a disabled label — is the thing R7 deliberately allows. A standing violation
/// with no available action is how a report stops being read.
///
/// This file does not re-derive the scope. It asserts that both callers reach it
/// through [isTranslucentFillViolation], by checking that neither can name a
/// site the other would not.
void main() {
  /// The V5 rows the generator produces, as `file:line`.
  Set<String> reportedV5() =>
      (buildViolations()['violations']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .where((violation) => violation['code'] == 'V5')
          .map((violation) => '${violation['file']}:${violation['line']}')
          .toSet();

  /// The sites rule R7 fails on, as `file:line`.
  Set<String> gateFailures() => scanLib()
      .where(isTranslucentFillViolation)
      .map((ColorSite site) => '${site.file}:${site.line}')
      .toSet();

  test('the report raises no V5 the source gate would let through', () {
    // The direction that matters. A V5 the gate *also* fails is actionable — fix
    // the code and both go green. A V5 the gate passes is a contradiction, and
    // it can only be cleared by breaking the other test.
    final unactionable = (reportedV5()..removeAll(gateFailures())).toList()
      ..sort();

    expect(
      unactionable,
      isEmpty,
      reason:
          'Reported as V5 but passing rule R7, so acting on the report would '
          'break the gate. Both scopes come from isTranslucentFillViolation — '
          'if one has grown a second opinion, that is the '
          'bug.\n${unactionable.join('\n')}',
    );
  });

  test('every site the gate fails on is in the report', () {
    // The converse, stated separately so a failure names which way they parted.
    // Silence here would let a broken build look clean to whoever reads the
    // report instead of the test output.
    final missed = (gateFailures()..removeAll(reportedV5())).toList()..sort();

    expect(missed, isEmpty, reason: missed.join('\n'));
  });

  test('a disabled label keeps its alpha in both audits', () {
    // The concrete case that started this, pinned by name rather than by count.
    // `MxTextButton` paints its disabled label at `onSurface @ 0.38` — the
    // Material idiom, and what `--color-on-disabled` states — and neither audit
    // may call that a violation.
    final labelSites = scanLib()
        .where((ColorSite site) => site.file.endsWith('mx_text_button.dart'))
        .where((ColorSite site) => site.sourceKind == 'opacity-modified-token')
        .toList();

    expect(
      labelSites,
      isNotEmpty,
      reason:
          'no translucent site found in mx_text_button.dart — either the file '
          'moved or the scanner stopped classifying it, and this test is now '
          'asserting nothing',
    );

    for (final site in labelSites) {
      expect(
        isTranslucentFillViolation(site),
        isFalse,
        reason:
            '${site.file}:${site.line} ${site.expression} is a label, not a '
            'fill or a border. Its ground is the surface it is printed on, so '
            'there is nothing to precompute against.',
      );
    }
  });
}
