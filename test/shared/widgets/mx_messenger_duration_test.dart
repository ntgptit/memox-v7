import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_messenger.dart';
import 'package:memox/shared/widgets/mx_undo_snack_bar.dart';

/// A20.1 P2-20 — one duration policy: a button to reach earns the undo bar's
/// time; a plain message keeps the default.
void main() {
  Future<void> show(WidgetTester tester, {bool withAction = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showMxMessage(
                context,
                'Saved',
                actionLabel: withAction ? 'View' : null,
                onAction: withAction ? () {} : null,
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
  }

  testWidgets('a plain message keeps 4 s', (tester) async {
    await show(tester);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).duration,
      kMxMessageDuration,
    );
    expect(kMxMessageDuration, const Duration(seconds: 4));
  });

  testWidgets('an actionable message holds as long as undo', (tester) async {
    await show(tester, withAction: true);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).duration,
      kMxUndoDuration,
    );
    expect(kMxActionableMessageDuration, kMxUndoDuration);
  });
}
