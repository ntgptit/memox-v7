@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';

import '../memox_audit.dart';
import 'audited_screens.dart';

/// Audits every registered screen, light and dark.
///
/// The loop is the enforcement. A screen reaches this file by being added to
/// `auditedScreens`, and it is added there because `screen_audit_coverage_test`
/// will not pass otherwise — so a registration cannot exist without producing a
/// running audit, and an audit cannot be satisfied by a file somebody left empty.
///
/// Bar is [AuditExpectation.noViolations] while the app is being built: nothing
/// may be *wrong*, and whatever could not be measured is printed on every run.
/// Raising a screen to `complete` is a per-screen decision made once its
/// remaining skips are either measurable or carry a written allowance.
void main() {
  for (final entry in auditedScreens) {
    memoxAuditTest(
      entry.name,
      entry.build,
      anchors: entry.anchors,
      allowances: entry.allowances,
    );
  }

  test('the registry is not empty', () {
    // The one thing the coverage gate cannot catch: deleting every screen and
    // every entry leaves both lists consistent and this suite silent.
    expect(auditedScreens, isNotEmpty);
  });
}
