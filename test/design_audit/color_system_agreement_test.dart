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

  test('a label is out of R7 scope, wherever the next one appears', () {
    // The concrete case that started this was `MxTextButton` painting its
    // disabled label at `onSurface @ 0.38`, and neither audit was allowed to
    // call that a violation: a label's ground is the surface it is printed on,
    // so there is nothing left unresolved to precompute.
    //
    // **That site no longer exists, and its absence is the outcome the rule
    // wanted.** M4.10an turned the value into `AppColors.onDisabled*`, so the
    // alpha is now declared once instead of applied at a paint site. The scope
    // rule still has to hold for the next label that needs one, so it is stated
    // against a site built here rather than against whichever file happens to
    // carry one today — a test that reads production code for its own fixture
    // silently stops asserting when the code improves.
    for (final kind in <String>['text', 'icon']) {
      final label = ColorSite(
        file: 'lib/shared/widgets/mx_text_button.dart',
        line: 1,
        widgetContext: '_MxTextButtonState',
        elementKind: kind,
        sourceKind: 'opacity-modified-token',
        expression: 'context.colors.onSurface.withValues(alpha: 0.38)',
        tokenName: 'onSurface',
      );

      expect(
        isTranslucentFillViolation(label),
        isFalse,
        reason:
            'a $kind is not a fill or a border. Its ground is the surface it '
            'is printed on, so there is nothing to precompute against.',
      );
    }
  });

  test('every translucent site left in lib/ is one R7 exempts', () {
    // The anti-vacuous half, and the invariant M4.10an actually established:
    // after the disabled label became a token, the only translucency left in
    // `lib/` is paint that *has* no ground — a shadow, the modal scrim, a state
    // layer over whatever surface the control sits on — plus the text-selection
    // and scrollbar washes that are the same idea. A new translucent fill on a
    // card or a button has to show up here.
    final translucent = scanLib()
        .where((ColorSite site) => site.sourceKind == 'opacity-modified-token')
        .toList();

    expect(
      translucent,
      isNotEmpty,
      reason:
          'the scanner stopped classifying translucency, and this test is now '
          'asserting nothing',
    );

    final offenders = translucent
        .where(isTranslucentFillViolation)
        .map((ColorSite site) => '${site.file}:${site.line} ${site.expression}')
        .toList();

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
