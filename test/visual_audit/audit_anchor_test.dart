import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

import 'audit_model.dart';
import 'audit_report.dart';
import 'audit_rules.dart';
import 'screen_auditor.dart';

/// How anchors name items, and what happens when the naming goes wrong.
///
/// The bug this file exists for: an anchor matching four widgets writes
/// `verdict[0]`…`verdict[3]`, and the old "did it match?" check looked for the
/// bare `verdict` in that list. It never found it, so the audit reported
/// "matched no widget" about an anchor that had matched four — a phantom
/// unresolved skip that put PASS permanently out of reach.
void main() {
  const noRules = <AuditRule>[];

  Future<ScreenAudit> auditOf(
    WidgetTester tester,
    Widget body,
    List<AuditAnchor> anchors,
  ) async {
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AuditSurface(
        child: MaterialApp(theme: buildLightTheme(), home: body),
      ),
    );
    await tester.pump();

    return auditScreen(
      tester,
      screen: 'probe',
      theme: 'light',
      anchors: anchors,
    );
  }

  Widget tile() => const SizedBox(
    width: 30,
    height: 30,
    child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF123456))),
  );

  testWidgets('an anchor matching one widget is not reported missing', (
    tester,
  ) async {
    final audit = await auditOf(tester, Center(child: tile()), <AuditAnchor>[
      AuditAnchor.type('tile', DecoratedBox),
    ]);

    expect(audit.skipsBecause(SkipReason.anchorNotFound), isEmpty);
    expect(audit.items.map((item) => item.id), contains('tile'));
  });

  testWidgets('an anchor matching four widgets is not reported missing', (
    tester,
  ) async {
    final audit = await auditOf(
      tester,
      Column(children: <Widget>[tile(), tile(), tile(), tile()]),
      <AuditAnchor>[AuditAnchor.type('tile', DecoratedBox)],
    );

    expect(audit.skipsBecause(SkipReason.anchorNotFound), isEmpty);
  });

  testWidgets('four matches become four indexed items', (tester) async {
    final audit = await auditOf(
      tester,
      Column(children: <Widget>[tile(), tile(), tile(), tile()]),
      <AuditAnchor>[AuditAnchor.type('tile', DecoratedBox)],
    );

    expect(
      audit.items.map((item) => item.id),
      containsAll(<String>['tile[0]', 'tile[1]', 'tile[2]', 'tile[3]']),
    );
  });

  testWidgets('an anchor matching nothing IS reported missing', (tester) async {
    final audit = await auditOf(tester, Center(child: tile()), <AuditAnchor>[
      AuditAnchor.type('nowhere', Slider),
    ]);

    expect(audit.skipsBecause(SkipReason.anchorNotFound), hasLength(1));
  });

  testWidgets('two anchors on the same render object collide loudly', (
    tester,
  ) async {
    // Without this, one anchor silently overwrites the other in the owner map
    // and takes its half of the report with it.
    final audit = await auditOf(tester, Center(child: tile()), <AuditAnchor>[
      AuditAnchor.type('first', DecoratedBox),
      AuditAnchor.type('second', DecoratedBox),
    ]);

    final collisions = audit.skipsBecause(SkipReason.anchorCollision);

    expect(collisions, hasLength(1));
    expect(collisions.first.detail, contains('first'));
    expect(collisions.first.detail, contains('second'));
    expect(collisions.first.detail, contains('RenderDecoratedBox'));
  });

  testWidgets('a collision keeps strict mode from passing', (tester) async {
    final audit = await auditOf(tester, Center(child: tile()), <AuditAnchor>[
      AuditAnchor.type('first', DecoratedBox),
      AuditAnchor.type('second', DecoratedBox),
    ]);

    final outcome = evaluateAudit(audit, noRules);

    expect(outcome.satisfies(AuditExpectation.complete), isFalse);
  });
}
