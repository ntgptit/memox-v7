import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../support/reminder_screen_harness.dart';

/// How the reminder screen is announced (M6 A3, A4).
///
/// Split from `reminder_settings_layout_test.dart` when that file crossed the
/// guard's 400-line ceiling. The seam is the honest one: this file reads the
/// semantics tree, that one measures rectangles, and neither needed the
/// other's imports.
void main() {
  final english = AppLocalizationsEn();

  late ReminderScreenHarness harness;

  setUp(() => harness = ReminderScreenHarness());

  group('accessibility (M6 A3, A4)', () {
    testWidgets('the toggle is spoken with its own name and value', (
      tester,
    ) async {
      // Disposed at the end of the body rather than through `addTearDown`:
      // the framework verifies no handle is live *before* tear-downs run.
      final handle = tester.ensureSemantics();
      await harness.pump(tester);

      // Read off the control itself, not by label: the screen title is the
      // same words, so a label search would find two nodes and prove nothing
      // about which one carries the switch.
      final node = tester.getSemantics(find.byType(Switch));

      // The label lives on the control, not only on the Text beside it: a
      // reader that focuses the switch would otherwise hear "Off" with no idea
      // what is off (WCAG 4.1.2).
      expect(node.label, english.reminderToggleLabel);
      // The value is what carries the state in words. The toggled *flag* is
      // Material's own and is asserted by the framework's Switch tests; what
      // this screen owns, and what M6 R7 is about, is that the state is also
      // readable without seeing the colour.
      expect(node.value, english.reminderStatusOff);

      handle.dispose();
    });

    testWidgets('the time row announces the time once, as its value', (
      tester,
    ) async {
      // Disposed at the end of the body rather than through `addTearDown`:
      // the framework verifies no handle is live *before* tear-downs run.
      final handle = tester.ensureSemantics();
      await harness.pump(tester);

      // Read from the text rather than from the widget type: the merged node
      // belongs to the tile's ancestor, and `byType` lands on an element whose
      // own node is empty.
      final node = tester.getSemantics(find.text(english.reminderTimeLabel));

      // One node carries both, and the time appears exactly once. It used to be
      // in the merged label *and* in a `Semantics(value:)` wrapper, so a reader
      // heard "Reminder time 8:00 PM, 8:00 PM".
      expect(node.label, contains(english.reminderTimeLabel));
      expect(node.label, contains('8:00 PM'));
      expect('${node.label}${node.value}'.split('8:00 PM').length - 1, 1);

      handle.dispose();
    });
  });
}
