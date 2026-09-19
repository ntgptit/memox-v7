import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

/// The focus ring `MxFilterChip` draws — pinned the same way
/// `mx_pill_button_focus_test.dart` pins `MxPillButton`'s: the ring must trace
/// the painted 28dp shape, never the 48dp tap target grown around it.
void main() {
  Future<void> pump(WidgetTester tester, {required bool isSelected}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: MxFilterChip(
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
    final String what = isSelected ? 'a selected chip' : 'an unselected chip';

    testWidgets('$what draws no ring until it is focused', (tester) async {
      await pump(tester, isSelected: isSelected);

      expect(ringDecoration(tester)?.border, isNull);
    });

    testWidgets('$what draws the ring once focus arrives', (tester) async {
      await pump(tester, isSelected: isSelected);

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

    testWidgets(
      '$what: the ring traces the painted 28dp shape, not the 48dp target',
      (tester) async {
        await pump(tester, isSelected: isSelected);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final Rect ring = tester.getRect(
          find.byWidgetPredicate(
            (Widget w) =>
                w is DecoratedBox &&
                w.position == DecorationPosition.foreground,
          ),
        );
        final Rect painted = tester.getRect(
          find
              .descendant(
                of: find.byType(MxFilterChip),
                matching: find.byType(Material),
              )
              .first,
        );
        final Rect target = tester.getRect(find.byType(MxFilterChip));

        expect(ring, painted, reason: 'the ring is not on the chip');
        expect(ring.height, AppSizing.controlChip);
        expect(
          target.height,
          greaterThan(ring.height),
          reason: 'the touch target must be the larger box, outside the ring',
        );
      },
    );
  }
}
