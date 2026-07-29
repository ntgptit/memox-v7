import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../support/app_palette.dart';
import 'audit_allowance.dart';
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
    // First, because everything after it is meaningless if the screen threw.
    const NoErrorWidgetRule(),
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
        // The delegates are not optional scenery. A real screen reads its copy
        // through `context.l10n`, and without them every one of them throws and
        // renders Flutter's error box — which the first run of this harness
        // against production widgets did, on both screens, while the replica
        // screens it had been developed on used hardcoded strings and never
        // noticed.
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
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
///
/// [expectation] defaults to [AuditExpectation.noViolations] — the exploratory
/// bar, which is honest for the preview screens: they still contain a text field
/// and an `Ink` layer nobody has measured yet, and the report says so on every
/// run. A production screen should be raised to [AuditExpectation.complete] once
/// each remaining skip is either measurable or carries a written allowance.
void memoxAuditTest(
  String name,
  Widget Function() build, {
  String state = 'idle',
  List<AuditAnchor> anchors = const <AuditAnchor>[],
  List<AuditSkipAllowance> allowances = const <AuditSkipAllowance>[],
  AuditExpectation expectation = AuditExpectation.noViolations,
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

      expectAudit(
        audit,
        memoxAuditRules(isDark: isDark),
        expectation: expectation,
        allowances: allowances,
      );
    });
  }
}

/// The bar a **production** screen is held to: [AuditExpectation.complete].
///
/// Two helpers instead of a flag, because a bar that can be lowered at the call
/// site is not a bar. `memoxAuditTest` is for design preview and exploration and
/// may end at PASS_WITH_UNRESOLVED; this one may not, and it takes no parameter
/// that could relax it.
///
/// Every unresolved node on a production screen therefore has to be either
/// measurable or covered by a scoped allowance carrying a reason — which is the
/// difference between "we looked at this screen" and "this screen was in a list".
void memoxProductionScreenAuditTest(
  String name,
  Widget Function() build, {
  String state = 'idle',
  List<AuditAnchor> anchors = const <AuditAnchor>[],
  List<AuditSkipAllowance> allowances = const <AuditSkipAllowance>[],
  Future<void> Function(WidgetTester tester)? drive,
}) {
  memoxAuditTest(
    name,
    build,
    state: state,
    anchors: anchors,
    allowances: allowances,
    expectation: AuditExpectation.complete,
    drive: drive,
  );
}
