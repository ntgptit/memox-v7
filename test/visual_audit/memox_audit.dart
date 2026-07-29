import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../support/app_palette.dart';
import 'audit_model.dart';
import 'audit_report.dart';
import 'audit_rules.dart';
import 'screen_auditor.dart';

/// Binds the generic audit core to this project.
///
/// Kept apart from the core on purpose: everything in the other files would
/// work on any Flutter app, and mixing memox's palette into them is how a
/// harness stops being reusable one commit after it is written.

/// The rules every memox screen is held to.
List<AuditRule> memoxAuditRules({required bool isDark}) {
  final semantic = isDark
      ? const AppSemanticColors.dark()
      : const AppSemanticColors.light();

  return <AuditRule>[
    const TextContrastRule(),
    NonTextContrastRule(<Color>[
      semantic.focusRing,
      semantic.success,
      semantic.warning,
      semantic.danger,
      semantic.info,
    ]),
    PaletteClosureRule(isDark ? darkPaletteTokens : lightPaletteTokens),
  ];
}

/// Pumps [screen] under the production theme and audits what it paints.
///
/// One call per screen per state. The state name is not decoration — a screen
/// audited only at rest is a screen where every pressed, focused and disabled
/// colour is unchecked, and those are where colour bugs live.
Future<ScreenAudit> auditMemoxScreen(
  WidgetTester tester, {
  required String name,
  required bool isDark,
  required Widget screen,
  String state = 'idle',
  Size viewport = const Size(420, 1040),
  List<AuditAnchor> anchors = const <AuditAnchor>[],
  Future<void> Function(WidgetTester tester)? drive,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    AuditSurface(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: screen,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 250));

  if (drive != null) {
    await drive(tester);
    await tester.pump(const Duration(milliseconds: 250));
  }

  return auditScreen(
    tester,
    screen: name,
    theme: isDark ? 'dark' : 'light',
    state: state,
    anchors: anchors,
  );
}

/// The one-liner a screen test uses: audit light and dark, assert both.
void memoxAuditTest(
  String name,
  Widget Function() build, {
  String state = 'idle',
  List<AuditAnchor> anchors = const <AuditAnchor>[],
  Set<SkipReason> tolerated = const <SkipReason>{},
  Future<void> Function(WidgetTester tester)? drive,
}) {
  for (final isDark in <bool>[false, true]) {
    final mode = isDark ? 'dark' : 'light';

    testWidgets('$name audit · $state · $mode', (tester) async {
      final audit = await auditMemoxScreen(
        tester,
        name: name,
        isDark: isDark,
        screen: build(),
        state: state,
        anchors: anchors,
        drive: drive,
      );

      expectAuditClean(
        audit,
        memoxAuditRules(isDark: isDark),
        tolerated: tolerated,
      );
    });
  }
}
