import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_checkbox_row.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: child),
      ),
    );
  }

  BoxDecoration decorationOf(WidgetTester tester) =>
      tester
              .widget<DecoratedBox>(
                find.descendant(
                  of: find.byKey(kMxCheckboxBoxKey),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .decoration
          as BoxDecoration;

  testWidgets('the whole row, including its 48dp target, toggles', (
    tester,
  ) async {
    var toggles = 0;
    await pump(
      tester,
      MxCheckboxRow(
        label: 'grammar',
        isChecked: false,
        onToggle: () => toggles += 1,
      ),
    );

    final row = tester.getRect(find.byType(MxCheckboxRow));
    expect(row.height, greaterThanOrEqualTo(AppSizing.touchTarget));

    // Deliberately outside the 20dp mark: the row is the target.
    await tester.tapAt(Offset(row.right - 1, row.center.dy));
    await tester.pump();
    expect(toggles, 1);
  });

  testWidgets('unchecked paints the fixed 20dp outline box', (tester) async {
    await pump(
      tester,
      MxCheckboxRow(label: 'grammar', isChecked: false, onToggle: () {}),
    );

    expect(tester.getSize(find.byKey(kMxCheckboxBoxKey)), const Size(20, 20));
    final decoration = decorationOf(tester);
    expect(decoration.color, isNull);
    expect(decoration.borderRadius, BorderRadius.circular(AppRadius.xs));
    expect(decoration.border, isA<Border>());
    final border = decoration.border! as Border;
    expect(border.top.width, AppStroke.selectionControl);
    expect(border.top.color, buildLightTheme().colorScheme.outline);
  });

  testWidgets('checked paints primary with a 14dp on-primary check', (
    tester,
  ) async {
    await pump(
      tester,
      MxCheckboxRow(label: 'grammar', isChecked: true, onToggle: () {}),
    );

    final decoration = decorationOf(tester);
    expect(decoration.color, buildLightTheme().colorScheme.primary);
    expect(decoration.border, isNull);
    final glyph = tester.widget<Icon>(find.byKey(kMxCheckboxGlyphKey));
    expect(glyph.icon, Icons.check);
    expect(glyph.size, 14);
    expect(glyph.color, isNull);
    expect(
      tester
          .widget<IconTheme>(
            find
                .ancestor(
                  of: find.byKey(kMxCheckboxGlyphKey),
                  matching: find.byType(IconTheme),
                )
                .first,
          )
          .data
          .color,
      buildLightTheme().colorScheme.onPrimary,
    );
  });

  testWidgets('Space and Enter toggle a focused row', (tester) async {
    final values = <bool>[];
    await pump(
      tester,
      MxCheckboxRow(
        label: 'grammar',
        isChecked: false,
        onToggle: () => values.add(true),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(values, <bool>[true, true]);
  });

  testWidgets('enabled row exposes one checked, focusable toggle node', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      MxCheckboxRow(label: 'grammar', isChecked: true, onToggle: () {}),
    );

    expect(
      tester.getSemantics(find.byType(MxCheckboxRow)),
      matchesSemantics(
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
        label: 'grammar',
      ),
    );
    handle.dispose();
  });

  testWidgets('focused row paints the shared primary focus indicator', (
    tester,
  ) async {
    await pump(
      tester,
      MxCheckboxRow(label: 'grammar', isChecked: false, onToggle: () {}),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final ring = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(MxCheckboxRow),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.position == DecorationPosition.foreground,
        ),
      ),
    );
    final border = (ring.decoration as BoxDecoration).border! as Border;
    expect(border.top.width, AppStroke.focus);
    expect(border.top.color, buildLightTheme().colorScheme.primary);
  });

  testWidgets('disabled blocks tap and focus, and dims the whole row', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const MxCheckboxRow(label: 'grammar', isChecked: true, onToggle: null),
    );

    await tester.tap(find.text('grammar'));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(MxCheckboxRow),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      AppStateOpacity.disabled,
    );
    expect(
      tester.getSemantics(find.byType(MxCheckboxRow)),
      matchesSemantics(
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        label: 'grammar',
      ),
    );
    handle.dispose();
  });
}
