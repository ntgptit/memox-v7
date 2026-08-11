import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/progress/presentation/screens/progress_placeholder_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

/// The Progress placeholder, pumped on its own.
///
/// **No `ProviderScope`, and that is the assertion behind every assertion.**
/// AD-19 makes the placeholder presentation-only: it may read no provider, no
/// repository and no database. A screen that grew a `ref` would throw the
/// moment this file pumps it without a scope, so the boundary is enforced by
/// the harness rather than by review.
void main() {
  final english = AppLocalizationsEn();

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size surface = const Size(393, 852),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const ProgressPlaceholderScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('is built from the shared components', (tester) async {
    // Not a re-test of those components' layout — this asserts the placeholder
    // did not grow its own Scaffold and its own column, which is how a
    // placeholder ends up looking like a different app than the one around it.
    await pumpScreen(tester);

    expect(find.byType(MxContentShell), findsOneWidget);
    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('says the feature is being developed, and that study activity '
      'is kept', (tester) async {
    await pumpScreen(tester);

    expect(find.text(english.progressTitle), findsOneWidget);
    expect(find.text(english.progressPlaceholderTitle), findsOneWidget);
    expect(find.text(english.progressPlaceholderMessage), findsOneWidget);
    expect(find.byIcon(Icons.insights_outlined), findsOneWidget);
  });

  testWidgets('shows no fake progress data', (tester) async {
    // AD-19: the placeholder must not read as a working feature. No chart, no
    // figure, no progress bar — a number on this screen would be an invented
    // statistic, and invented data is the rejected alternative of AD-19.
    await pumpScreen(tester);

    // A predicate, not `byType`: `ProgressIndicator` is abstract and `byType`
    // matches the concrete runtime type only.
    expect(
      find.byWidgetPredicate((widget) => widget is ProgressIndicator),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            RegExp(r'\d').hasMatch(widget.data!),
      ),
      findsNothing,
    );
  });

  testWidgets('no overflow at 320x568', (tester) async {
    await pumpScreen(tester, surface: const Size(320, 568));

    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow at 320x568 with textScaler 2.0', (tester) async {
    await pumpScreen(tester, surface: const Size(320, 568), textScale: 2);

    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
