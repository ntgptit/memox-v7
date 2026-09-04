import 'package:flutter_test/flutter_test.dart';

import '../support/reminder_screen_harness.dart';

/// A20.1 P2-17 — the reminder settings screen under the accessibility
/// guidelines.
void main() {
  testWidgets('idle', (tester) async {
    final harness = ReminderScreenHarness();
    await harness.pump(tester);
    await tester.pumpAndSettle();

    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    // Contrast is deliberately not swept here: `textContrastGuideline`
    // samples rendered pixels, and on a 12px line most glyph pixels are only
    // partially covered — `settings_accessibility_test.dart` records it
    // reporting 1.35:1 on a pair that measures 7.0:1. Every ink this screen
    // writes in is measured from the tokens by the contrast suites under
    // `test/core/theme/`.
    handle.dispose();
  });
}
