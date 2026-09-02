import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_interaction_states.dart';
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
  }
}
