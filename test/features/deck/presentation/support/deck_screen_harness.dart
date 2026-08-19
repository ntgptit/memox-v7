import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';

import '../../../../database/support/test_database.dart';
import '../../../../features/settings/domain/support/fake_app_settings_repository.dart';

/// Pumps a deck screen with a repository under it, at a chosen size and scale.
///
/// Two ways in, on purpose:
///
/// * [pumpDeckApp] mounts the **real router and shell**, so the bottom bar, the
///   nested deck route and Back behaviour are the production ones. Everything
///   about navigation is asserted through this.
/// * [pumpDeckScreen] mounts one screen alone, for the state matrix where a
///   router adds nothing but harder finders.
///
/// Both take a repository rather than building one. Presentation tests use the
/// fake; what the writes actually do to the tree is asserted against real
/// SQLite in `test/features/deck/data/`. Driving a real Drift database from a
/// widget test was tried and dropped: the stream-notification timer is still
/// pending when the tree is torn down, so `flutter_test` fails the test for a
/// teardown detail rather than for the behaviour under test.
///
/// The clock is always fixed. A due count measured against the wall clock would
/// make the suite depend on when it runs.
final DateTime deckTestNow = testNow;

/// Pumps the whole app — real router, real shell — with [repository] behind it.
Future<GoRouter> pumpDeckApp(
  WidgetTester tester, {
  required DeckRepository repository,
  String? initialLocation,
  Size surface = const Size(393, 852),
  double textScale = 1,
  bool isDark = false,
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = initialLocation == null
      ? createAppRouter()
      : createAppRouter(initialLocation: initialLocation);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appSettingsRepositoryProvider.overrideWithValue(
          FakeAppSettingsRepository(),
        ),
        envConfigProvider.overrideWithValue(EnvConfig.development),
        deckRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => deckTestNow),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          platformBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        child: MemoxApp(router: router),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();

  // Returned so a test can assert *where* a tap landed rather than only that a
  // callback fired. The breadcrumb is the case that needs it: what it navigates
  // to is the whole of its behaviour.
  return router;
}

/// Pumps one screen on its own, without the router.
///
/// For the state matrix, where a router adds nothing and a pushed route would
/// only make the finders harder to write.
Future<void> pumpDeckScreen(
  WidgetTester tester, {
  required DeckRepository repository,
  required Widget screen,
  Size surface = const Size(393, 852),
  double textScale = 1,
  bool isDark = false,
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appSettingsRepositoryProvider.overrideWithValue(
          FakeAppSettingsRepository(),
        ),
        envConfigProvider.overrideWithValue(EnvConfig.development),
        deckRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => deckTestNow),
      ],
      child: MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: screen,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// The text field of the deck **form** — create or rename.
///
/// **Named rather than reached for by type.** Every deck level now carries a
/// search field as well, so `find.byType(TextField)` resolves to two and every
/// `.single` behind it throws "Bad state: Too many elements". Which of the two a
/// test means is exactly the thing worth saying out loud: these tests are about
/// the form, and a finder that says so keeps working the next time the screen
/// grows another input.
Finder get deckFormField => find.descendant(
  of: find.byType(MxTextField),
  matching: find.byType(TextField),
);
