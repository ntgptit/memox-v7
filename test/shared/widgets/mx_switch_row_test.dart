import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_switch_row.dart';

/// `MxSwitchRow` — one node, one state channel (A20.1 P2-13).
///
/// OLD ASSERTIONS: the "announced" variant carried the value in words
/// (`value: 'On'`) on a switch that also carried `toggled`, and the label was
/// "the tap target for nothing". WHY WRONG: two channels for one state — a
/// reader heard "On, switch, on" (A19-19). NEW CONTRACT: the row is a
/// `SwitchListTile` — its name is the label, its state is the toggle, and
/// the whole row toggles. AUTHORITY: A20.1 P2-13.
/// The toggle state, on the node or on the switch node beneath it.
Tristate _toggledIn(SemanticsNode node) {
  var found = node.flagsCollection.isToggled;
  node.visitChildren((child) {
    if (child.flagsCollection.isToggled != Tristate.none) {
      found = child.flagsCollection.isToggled;
    }
    return true;
  });
  return found;
}

List<String> _valuesIn(SemanticsNode node) {
  final values = <String>[node.value];
  node.visitChildren((child) {
    values.addAll(_valuesIn(child));
    return true;
  });
  return values;
}

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('the label names the switch and the toggle is its state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      MxSwitchRow(label: 'Reminders', isOn: true, onChanged: (_) {}),
    );

    final node = tester.getSemantics(find.byType(SwitchListTile));
    expect(node.label, contains('Reminders'));
    // Flutter 3.44's `SwitchListTile` keeps the switch's own node under the
    // named tile — `MergeSemantics` folds the name onto the tile and leaves
    // the toggle where the platform reads a toggle. One name, one state.
    expect(_toggledIn(node), Tristate.isTrue);
    expect(node.value, isEmpty, reason: 'a second state channel');
    expect(_valuesIn(node), everyElement(isEmpty), reason: 'no "On" text');
    handle.dispose();
  });

  testWidgets('the whole row toggles as one control', (tester) async {
    var changes = 0;
    await pump(
      tester,
      MxSwitchRow(label: 'Reminders', isOn: false, onChanged: (_) => changes++),
    );

    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();
    expect(changes, 1);
  });

  testWidgets('a null handler disables the row and says so', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const MxSwitchRow(label: 'Reminders', isOn: true, onChanged: null),
    );
    final node = tester.getSemantics(find.byType(SwitchListTile));
    expect(node.flagsCollection.isEnabled, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('the label sits at the body-lg rung', (tester) async {
    await pump(
      tester,
      MxSwitchRow(label: 'Reminders', isOn: true, onChanged: (_) {}),
    );
    final text = tester.widget<Text>(find.text('Reminders'));
    expect(
      text.style?.fontSize,
      buildLightTheme().textTheme.bodyLarge?.fontSize,
    );
  });
}
