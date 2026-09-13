import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_elevation.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

/// Handoff FloatingActionButton (B): extended only, 52 tall, radius 16,
/// `primary` / `onPrimary`, `shadow-fab`. The kit has no circular variant.
void main() {
  for (final (name, theme) in <(String, ThemeData)>[
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    testWidgets('$name: extended, labelled, 52 tall, primary, shadow-fab', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            floatingActionButton: MxFab(
              icon: Icons.add,
              label: 'New deck',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('New deck'), findsOneWidget);
      final fab = find.byType(FloatingActionButton);
      expect(tester.getSize(fab).height, AppSizing.fab);

      final material = tester.widget<Material>(
        find.descendant(of: fab, matching: find.byType(Material)).first,
      );
      expect(material.color, theme.colorScheme.primary);
      expect(material.elevation, AppElevation.none);
      expect(
        (material.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(AppRadius.lg),
      );

      final shadow = tester.widget<DecoratedBox>(
        find.ancestor(of: fab, matching: find.byType(DecoratedBox)).first,
      );
      expect(
        (shadow.decoration as BoxDecoration).boxShadow,
        shadowsFor(AppElevation.overlay, theme.colorScheme),
      );
    });

    testWidgets('$name: keyboard focus draws the onPrimary ring', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            floatingActionButton: MxFab(
              icon: Icons.add,
              label: 'New deck',
              onPressed: () {},
            ),
          ),
        ),
      );

      Material fabMaterial() => tester.widget<Material>(
        find
            .descendant(
              of: find.byType(FloatingActionButton),
              matching: find.byType(Material),
            )
            .first,
      );

      expect((fabMaterial().shape! as OutlinedBorder).side, BorderSide.none);

      // A real Tab, so the theme's shape travels the SDK path: the FAB hands
      // it to `RawMaterialButton`, which resolves it with the focused state.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final side = (fabMaterial().shape! as OutlinedBorder).side;
      expect(side.color, theme.colorScheme.onPrimary);
      expect(side.width, AppStroke.focus);
    });
  }
}
