import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_menu_button.dart';

/// What the menu owns: each action's callback fires from its row, the anchor
/// is named, and a disabled menu opens nothing.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('an action fires its own callback', (tester) async {
    var renames = 0;
    var deletes = 0;
    await tester.pumpWidget(
      host(
        MxMenuButton(
          tooltip: 'Tag menu',
          actions: <MxMenuAction>[
            MxMenuAction(
              icon: Icons.edit_outlined,
              label: 'Rename',
              onSelected: () => renames += 1,
            ),
            MxMenuAction(
              icon: Icons.delete_outline,
              label: 'Delete tag',
              isDestructive: true,
              onSelected: () => deletes += 1,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(MxMenuButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete tag'));
    await tester.pumpAndSettle();

    expect(renames, 0);
    expect(deletes, 1);
  });

  testWidgets('the anchor carries the required tooltip', (tester) async {
    await tester.pumpWidget(
      host(
        MxMenuButton(
          tooltip: 'Sort',
          actions: <MxMenuAction>[
            MxMenuAction(label: 'Newest', onSelected: () {}),
          ],
        ),
      ),
    );

    expect(find.byTooltip('Sort'), findsOneWidget);
  });

  testWidgets('a custom anchor replaces the overflow glyph', (tester) async {
    await tester.pumpWidget(
      host(
        MxMenuButton(
          tooltip: 'Sort',
          actions: <MxMenuAction>[
            MxMenuAction(label: 'Newest', onSelected: () {}),
          ],
          child: const Text('anchor'),
        ),
      ),
    );

    expect(find.text('anchor'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('disabled opens nothing', (tester) async {
    await tester.pumpWidget(
      host(
        MxMenuButton(
          tooltip: 'More',
          isEnabled: false,
          actions: <MxMenuAction>[
            MxMenuAction(label: 'Import', onSelected: () {}),
          ],
        ),
      ),
    );

    await tester.tap(find.byType(MxMenuButton), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Import'), findsNothing);
  });
}
