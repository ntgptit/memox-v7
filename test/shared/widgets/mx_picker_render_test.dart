import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_dropdown.dart';

/// A20.1 P2-21 — both Material pickers are rendered under the app theme, and
/// `MxDropdown`'s disabled/error decision is pinned.
void main() {
  Future<void> pumpHost(
    WidgetTester tester,
    ThemeData theme,
    Widget Function(BuildContext) child,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(body: Builder(builder: child)),
      ),
    );
  }

  for (final (name, theme) in <(String, ThemeData)>[
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    testWidgets('the date picker opens and paints its themed surface, $name', (
      tester,
    ) async {
      await pumpHost(
        tester,
        theme,
        (context) => TextButton(
          onPressed: () => showDatePicker(
            context: context,
            initialDate: DateTime(2026, 9, 4),
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
          ),
          child: const Text('open'),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      final surface = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(DatePickerDialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(surface.color, theme.datePickerTheme.backgroundColor);
    });

    testWidgets('the time picker opens and paints its themed surface, $name', (
      tester,
    ) async {
      await pumpHost(
        tester,
        theme,
        (context) => TextButton(
          onPressed: () => showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 20, minute: 0),
          ),
          child: const Text('open'),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsOneWidget);
      final surface = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(TimePickerDialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(surface.color, theme.timePickerTheme.backgroundColor);
    });
  }

  group('MxDropdown', () {
    const options = <MxDropdownOption<int>>[
      MxDropdownOption<int>(value: 0, label: 'Front'),
      MxDropdownOption<int>(value: 1, label: 'Back'),
    ];

    testWidgets('disabled is a null handler, and it says so', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpHost(
        tester,
        buildLightTheme(),
        (_) =>
            const MxDropdown<int>(value: 0, options: options, onChanged: null),
      );
      final button = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>),
      );
      expect(button.onChanged, isNull);
      final node = tester.getSemantics(find.byType(DropdownButton<int>));
      expect(node.flagsCollection.isEnabled, isNot(Tristate.isTrue));
      handle.dispose();
    });

    testWidgets('has no error slot — the row owns validation', (tester) async {
      // The decision is structural: the constructor takes value, options and
      // onChanged, and nothing else a caller could paint an error with.
      await pumpHost(
        tester,
        buildLightTheme(),
        (_) => MxDropdown<int>(value: 0, options: options, onChanged: (_) {}),
      );
      expect(find.byType(DropdownButtonHideUnderline), findsOneWidget);
      expect(find.byType(InputDecorator), findsNothing);
    });
  });
}
