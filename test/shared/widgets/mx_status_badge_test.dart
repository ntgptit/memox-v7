import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: child),
    ),
  );

  testWidgets('paints the fixed 22dp lifecycle pill', (tester) async {
    await pump(tester, const MxStatusBadge(status: MxCardStatus.learning));

    expect(tester.getSize(find.byType(MxStatusBadge)).height, 22);
    expect(find.text('Learning'), findsOneWidget);
  });

  testWidgets('keeps the bare-dot variant non-interactive', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const MxStatusBadge(status: MxCardStatus.mastered, dotOnly: true),
    );

    expect(tester.getSize(find.byKey(MxStatusBadge.dotKey)).width, 8);
    expect(find.text('Mastered'), findsNothing);
    expect(
      tester
          .getSemantics(find.byType(MxStatusBadge))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    handle.dispose();
  });
}
