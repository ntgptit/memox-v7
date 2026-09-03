import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_checkbox_row.dart';

/// `MxCheckboxRow` — the pick-many row.
///
/// It had no test file at all (#431 §24): one production caller, a stress
/// specimen and one Widgetbook knob. Everything below is what the widget's own
/// doc comment promises — the box leads, the whole row is the target, the tile
/// merges label and box into one spoken node, `null` locks it — stated so a
/// change to any of them fails here rather than in the tag filter sheet.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool isDark = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final mode in <(String, bool)>[('light', false), ('dark', true)]) {
    final label = mode.$1;
    final isDark = mode.$2;

    testWidgets('$label · a tap anywhere on the row toggles', (tester) async {
      var toggles = 0;
      await pump(
        tester,
        MxCheckboxRow(
          label: 'grammar',
          isChecked: false,
          onToggle: () => toggles += 1,
        ),
        isDark: isDark,
      );

      // The label, not the box: the row is the target.
      await tester.tap(find.text('grammar'));
      await tester.pumpAndSettle();

      expect(toggles, 1, reason: label);
    });

    testWidgets('$label · the box leads, and the subtitle renders', (
      tester,
    ) async {
      await pump(
        tester,
        MxCheckboxRow(
          label: 'grammar',
          subtitle: '12 cards',
          isChecked: true,
          onToggle: () {},
        ),
        isDark: isDark,
      );

      final box = tester.getRect(find.byType(Checkbox));
      final text = tester.getRect(find.text('grammar'));
      expect(box.right, lessThan(text.left), reason: '$label: the box trails');
      expect(find.text('12 cards'), findsOneWidget, reason: label);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox)).value,
        isTrue,
        reason: label,
      );
    });

    testWidgets('$label · one spoken node carries label, checked state and '
        'the toggle', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        MxCheckboxRow(label: 'grammar', isChecked: true, onToggle: () {}),
        isDark: isDark,
      );

      expect(
        tester.getSemantics(find.byType(CheckboxListTile)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
          // `ListTile` 3.44.8 passes `selected: selected` — a non-nullable
          // `bool` — to its `Semantics`, so every tile carries the flag even
          // when selection is not a concept it has (list_tile.dart:997). The
          // row's truth is `isChecked`; this flag is the SDK's, pinned so a
          // future SDK that makes it nullable is noticed rather than absorbed.
          hasSelectedState: true,
          label: 'grammar',
        ),
        reason: label,
      );
      handle.dispose();
    });

    testWidgets('$label · null locks the row: no tap, no focus, greyed', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const MxCheckboxRow(label: 'grammar', isChecked: true, onToggle: null),
        isDark: isDark,
      );

      await tester.tap(find.text('grammar'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(CheckboxListTile)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          // `isEnabled` is left at the matcher's default — false — which is
          // the assertion: the flag is present and it is off.
          hasEnabledState: true,
          hasSelectedState: true,
          label: 'grammar',
        ),
        reason: '$label: a locked row still offers a tap or a focus',
      );
      handle.dispose();
    });
  }
}
