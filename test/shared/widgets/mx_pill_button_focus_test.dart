import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';

/// The focus indicator `MxPillButton` draws, and the two properties that made it
/// move out of `ChipThemeData.side` at M100.23.
///
/// No golden covers a focused control — every golden in this project shoots a
/// resting state — so this is the only thing standing between the ring and a
/// silent disappearance.
void main() {
  Future<void> pump(WidgetTester tester, {required bool isSelected}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: MxPillButton(
              label: 'All',
              isSelected: isSelected,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration? ringDecoration(WidgetTester tester) {
    final Finder finder = find.byWidgetPredicate(
      (Widget w) =>
          w is DecoratedBox && w.position == DecorationPosition.foreground,
    );
    if (finder.evaluate().isEmpty) return null;

    return tester.widget<DecoratedBox>(finder.first).decoration
        as BoxDecoration?;
  }

  for (final bool isSelected in <bool>[false, true]) {
    final String what = isSelected ? 'a selected pill' : 'an unselected pill';

    testWidgets('$what draws no ring until it is focused', (tester) async {
      await pump(tester, isSelected: isSelected);

      expect(ringDecoration(tester)?.border, isNull);
    });

    testWidgets('$what draws the ring once focus arrives', (tester) async {
      await pump(tester, isSelected: isSelected);

      // Reaching the chip the way a keyboard does, rather than by poking a
      // FocusNode: the wrapper is `skipTraversal`, and a bug there would be
      // invisible to a test that focuses the node directly.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final BoxDecoration? decoration = ringDecoration(tester);
      expect(decoration?.border, isNotNull, reason: 'the focus ring is gone');
      expect(
        decoration!.border!.top.color,
        AppInteractionStates.focusIndicator(
          buildLightTheme().colorScheme,
        ).color,
      );
    });

    testWidgets('$what: the ring traces the painted pill, not the finger box', (
      tester,
    ) async {
      // The ring used to wrap `RawChip`'s 48 × 48 redirecting hit box, so it
      // floated 7dp clear of the 34-tall pill at a corner the pill did not
      // have (#434 P1-4). The chip is `shrinkWrap` now, the ring wraps the
      // painted `Material`, and the 48 target is grown *outside* the ring.
      await pump(tester, isSelected: isSelected);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final Rect ring = tester.getRect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is DecoratedBox && w.position == DecorationPosition.foreground,
        ),
      );
      final Rect painted = tester.getRect(
        find
            .descendant(
              of: find.byType(ChoiceChip),
              matching: find.byType(Material),
            )
            .first,
      );
      final Rect target = tester.getRect(find.byType(MxPillButton));

      expect(ring, painted, reason: 'the ring is not on the pill');
      expect(
        target.height,
        greaterThan(ring.height),
        reason: 'the touch target must be the larger box, outside the ring',
      );
    });
  }
}
