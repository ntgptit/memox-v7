import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_alert_dialog.dart';
import 'package:memox/shared/widgets/mx_dialog_route.dart';
import 'package:memox/shared/widgets/mx_dialog_tone.dart';

/// The handoff Dialog (G): enters on a fade and a scale from 0.94 over 200ms,
/// opens at full scale under reduced motion, and an alert sits at md 320 with
/// radius 20 and no edge (D5, D19).
void main() {
  Future<void> open(
    WidgetTester tester, {
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showMxDialog<void>(
                  context,
                  builder: (dialogContext) => MxAlertDialog(
                    title: 'Heads up',
                    message: 'Body',
                    dismissLabel: 'OK',
                    onDismiss: () => Navigator.of(dialogContext).pop(),
                    tone: MxDialogTone.info,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
  }

  double scaleOf(WidgetTester tester) => tester
      .widget<ScaleTransition>(find.byType(ScaleTransition).last)
      .scale
      .value;

  testWidgets('scales in from 0.94 over 200ms', (tester) async {
    await open(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(scaleOf(tester), inExclusiveRange(0.94, 1.0));

    await tester.pump(const Duration(milliseconds: 120));
    expect(scaleOf(tester), 1.0);
  });

  testWidgets('reduced motion opens at full scale on the first frame', (
    tester,
  ) async {
    await open(tester, disableAnimations: true);
    await tester.pump();
    expect(find.text('Heads up'), findsOneWidget);
    expect(scaleOf(tester), 1.0);
  });

  testWidgets('an alert dialog is md 320 at most, radius 20, no edge', (
    tester,
  ) async {
    await open(tester);
    await tester.pumpAndSettle();
    // The dialog's surface, not the AlertDialog itself: its root is the
    // inset padding, which spans the whole view.
    final surface = find
        .descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(Material),
        )
        .first;
    expect(
      tester.getSize(surface).width,
      lessThanOrEqualTo(AppSizing.dialogMd),
    );
    final shape =
        buildLightTheme().dialogTheme.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(AppRadius.card));
    expect(shape.side, BorderSide.none);
  });
}
