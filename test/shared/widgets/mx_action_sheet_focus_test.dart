import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_action_sheet.dart';

/// A20.1 P2-04 — the action sheet's rows carry the row overlay and the
/// focus ring like every other row.
void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: MxActionSheet(
            title: 'Sort by',
            actions: <MxActionSheetAction>[
              MxActionSheetAction(label: 'Name', onPressed: () {}),
              MxActionSheetAction(label: 'Newest', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('the title is a heading', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(find.text('Sort by')).flagsCollection.isHeader,
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('a row takes the app overlay and draws the ring under focus', (
    tester,
  ) async {
    await pump(tester);
    final scheme = buildLightTheme().colorScheme;
    final overlay = AppInteractionStates.rowOverlay(scheme);
    final tile = tester.widget<ListTile>(find.byType(ListTile).first);
    expect(
      tile.focusColor,
      overlay.resolve(const <WidgetState>{WidgetState.focused}),
    );
    expect(
      tile.splashColor,
      overlay.resolve(const <WidgetState>{WidgetState.pressed}),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final rings = find.byWidgetPredicate(
      (Widget w) =>
          w is DecoratedBox &&
          w.position == DecorationPosition.foreground &&
          (w.decoration as BoxDecoration).border != null,
    );
    expect(rings, findsOneWidget, reason: 'no ring on the focused row');
  });
}
