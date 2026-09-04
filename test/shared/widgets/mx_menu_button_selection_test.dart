import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_menu_button.dart';

/// A20.1 P2-14 (A19-03) — a single-choice menu marks and announces its
/// current value.
void main() {
  Future<void> open(WidgetTester tester, {required bool picker}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: MxMenuButton(
            tooltip: 'Sort',
            actions: <MxMenuAction>[
              MxMenuAction(
                label: 'Name',
                onSelected: () {},
                isSelected: picker,
              ),
              MxMenuAction(label: 'Newest', onSelected: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(MxMenuButton));
    await tester.pumpAndSettle();
  }

  testWidgets('the picked row draws a check and announces selected', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, picker: true);

    expect(find.byIcon(Icons.check), findsOneWidget);
    final picked = tester.getSemantics(find.text('Name'));
    expect(picked.flagsCollection.isSelected, Tristate.isTrue);
    expect(picked.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
    final other = tester.getSemantics(find.text('Newest'));
    expect(other.flagsCollection.isSelected, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('a command menu carries neither the check nor the group', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, picker: false);

    expect(find.byIcon(Icons.check), findsNothing);
    final row = tester.getSemantics(find.text('Name'));
    expect(row.flagsCollection.isInMutuallyExclusiveGroup, isFalse);
    handle.dispose();
  });
}
