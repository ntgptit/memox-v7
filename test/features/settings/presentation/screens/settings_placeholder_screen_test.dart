import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/settings/presentation/screens/settings_placeholder_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

/// The Settings placeholder, pumped on its own.
///
/// **No `ProviderScope`, deliberately** — see the Progress companion for the
/// reasoning. The placeholder is presentation-only (AD-19); pumping it without
/// a scope is what makes a future provider read fail here instead of shipping.
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
          child: const SettingsPlaceholderScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('is built from the shared components', (tester) async {
    await pumpScreen(tester);

    expect(find.byType(MxContentShell), findsOneWidget);
    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('says settings are being developed, and offers no dead control', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text(english.settingsTitle), findsOneWidget);
    expect(find.text(english.settingsPlaceholderTitle), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    // AD-19: no fake preference, no toggle that persists nothing. A switch on
    // this screen would read as a working setting and silently discard the
    // user's choice.
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(Slider), findsNothing);
    // A predicate, not `byType`: `ButtonStyleButton` is abstract and `byType`
    // matches the concrete runtime type only.
    expect(
      find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
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
