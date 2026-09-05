import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

/// A20.1 P1-15, corrective pass — the chrome policy is explicit: `none`
/// draws no bar however the route arrived; `auto` keeps the bar for the way
/// back, as P1-15 asks.
void main() {
  const routeTransition = Duration(seconds: 1);

  Future<void> pushShell(WidgetTester tester, Widget shell) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => shell)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(routeTransition);
  }

  testWidgets('none draws no bar and no Back on a pushed route', (
    tester,
  ) async {
    await pushShell(
      tester,
      const MxContentShell(
        chrome: MxShellChrome.none,
        body: MxLoadingState(semanticsLabel: 'Loading'),
      ),
    );
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('auto keeps the bar and Back on a pushed route', (tester) async {
    await pushShell(
      tester,
      const MxContentShell(body: MxLoadingState(semanticsLabel: 'Loading')),
    );
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('none refuses bar content', (tester) async {
    expect(
      () => MxContentShell(
        chrome: MxShellChrome.none,
        title: 'Title',
        body: const SizedBox(),
      ),
      throwsAssertionError,
    );
  });
}
