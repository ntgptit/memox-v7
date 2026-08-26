import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_alert_dialog.dart';
import 'package:memox/shared/widgets/mx_dialog_tone.dart';

/// The one-button shape: what it announces, where focus lands, and that its
/// tone is not decoration.
void main() {
  Future<void> pumpAlert(
    WidgetTester tester, {
    MxDialogTone tone = MxDialogTone.error,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMxAlert(
                context,
                title: 'Export failed',
                message: 'The file could not be written to that folder.',
                dismissLabel: 'OK',
                tone: tone,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the single action takes focus', (tester) async {
    await pumpAlert(tester);

    final focus = Focus.maybeOf(tester.element(find.text('OK')), scopeOk: true);

    expect(
      focus?.hasFocus ?? false,
      isTrue,
      reason:
          'with one action there is nothing less destructive to focus — the '
          'rule that keeps focus off a confirm button is about choosing '
          'between two',
    );
  });

  testWidgets('Enter dismisses it', (tester) async {
    await pumpAlert(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the button dismisses it', (tester) async {
    await pumpAlert(tester);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the message is announced once, not twice', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpAlert(tester);

    expect(
      tester.getSemantics(
        find.text('The file could not be written to that folder.'),
      ),
      isNot(isSemantics(isLiveRegion: true)),
      reason:
          'AlertDialog already names the route and marks its content a '
          'semantics container, so the message is read on open; a live region '
          'would read it a second time',
    );
    handle.dispose();
  });

  testWidgets('the tone reaches the glyph and the palette owns the colour', (
    tester,
  ) async {
    await pumpAlert(tester, tone: MxDialogTone.error);

    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Icon),
      ),
    );

    expect(icon.icon, Icons.error_outline);
    expect(icon.color, const AppSemanticColors.light().danger);
  });

  testWidgets('a success alert is a different glyph and a different token', (
    tester,
  ) async {
    await pumpAlert(tester, tone: MxDialogTone.success);

    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Icon),
      ),
    );

    expect(icon.icon, Icons.check_circle_outline);
    expect(icon.color, const AppSemanticColors.light().success);
  });
}
