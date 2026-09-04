import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

/// A20.1 P1-15 — the shell keeps its bar, and the way back, while a screen is
/// loading or has failed.
const Duration _routeTransition = Duration(seconds: 1);

void main() {
  Future<void> pushShell(WidgetTester tester, Widget body) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MxContentShell(body: body),
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
    await tester.pump();
    // The body is a spinner, so `pumpAndSettle` would never return; the
    // route transition is what has to finish.
    await tester.pump(_routeTransition);
  }

  testWidgets('a pushed screen with no title still draws a bar with Back', (
    tester,
  ) async {
    await pushShell(tester, const MxLoadingState(semanticsLabel: 'Loading'));

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('tapping that Back leaves the screen', (tester) async {
    await pushShell(tester, const MxLoadingState(semanticsLabel: 'Loading'));
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(_routeTransition);

    expect(find.text('open'), findsOneWidget);
    expect(find.byType(MxContentShell), findsNothing);
  });

  testWidgets('a root screen with nothing to say draws no bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: const MxContentShell(body: SizedBox()),
      ),
    );
    expect(find.byType(AppBar), findsNothing);
  });
}
