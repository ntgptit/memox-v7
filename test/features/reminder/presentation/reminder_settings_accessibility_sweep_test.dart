import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/semantics_traversal.dart';
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
    // And in the order a reader would take them: the two guidelines above pass
    // just as happily on a screen that announces its footer first.
    expectTraversalFollowsReadingOrder(tester);
    // Contrast is deliberately not swept here: `textContrastGuideline`
    // samples rendered pixels, and on a 12px line most glyph pixels are only
    // partially covered — `settings_accessibility_test.dart` records it
    // reporting 1.35:1 on a pair that measures 7.0:1. Every ink this screen
    // writes in is measured from the tokens by the contrast suites under
    // `test/core/theme/`.
    handle.dispose();
  });

  // **The assertion above has to be able to fail.** Flutter derives traversal
  // from geometry, so on a screen that only lays widgets out the check agrees
  // with the framework by construction and would pass even if it compared
  // nothing. What separates the two is a sort key, and this proves the check
  // sees one: two boxes, the lower given the earlier ordinal, and the
  // traversal comes back `bottom, top`.
  //
  // Recorded because the first attempt to prove it went the other way. An
  // `OrdinalSortKey` dropped into a real section left the sweep green — the
  // injected node merged into its parent and never became a sibling in the
  // sort group — which reads as "the assertion is asleep" and is not.
  testWidgets('the check sees a reversed sort key (fault probe)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            Semantics(
              sortKey: const OrdinalSortKey(2),
              label: 'upper',
              child: const SizedBox(height: 100, width: 100),
            ),
            Semantics(
              sortKey: const OrdinalSortKey(1),
              label: 'lower',
              child: const SizedBox(height: 100, width: 100),
            ),
          ],
        ),
      ),
    );

    expect(
      () => expectTraversalFollowsReadingOrder(tester),
      throwsA(isA<TestFailure>()),
      reason: 'a sort key that fights the layout must fail the check',
    );

    handle.dispose();
  });
}
