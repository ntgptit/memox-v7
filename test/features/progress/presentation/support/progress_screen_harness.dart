import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'fake_progress_repository.dart';

/// Pumps Progress by Deck with a repository under it, at a chosen size, scale,
/// theme and locale.
///
/// Two ways in, the same split the deck harness makes:
///
/// * [pumpProgressApp] mounts the **real router and shell**, so the bottom bar,
///   the nested `/progress/:deckId` route and Back behaviour are the production
///   ones. Everything about navigation is asserted through this.
/// * [pumpProgressScreen] mounts one screen alone, for the state matrix where a
///   router adds nothing but harder finders.
///
/// The clock and the zone offset are always fixed. Every figure on this screen
/// is defined by a window measured from `now` in a local zone, so a harness that
/// let either come from the machine would make the suite depend on when and
/// where it ran.
const Duration progressTestOffset = Duration(hours: 7);

/// Pumps the whole app — real router, real shell — with [repository] behind it.
Future<GoRouter> pumpProgressApp(
  WidgetTester tester, {
  required ProgressRepository repository,
  String initialLocation = RoutePaths.progress,
  Size surface = const Size(393, 852),
  double textScale = 1,
  bool isDark = false,
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = createAppRouter(initialLocation: initialLocation);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        progressRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => progressTestNow),
        utcOffsetProvider.overrideWithValue(() => progressTestOffset),
      ],
      // **`copyWith`, not a fresh `MediaQueryData`.** Building one from scratch
      // sets every other field to its default — `size` included — so
      // `MediaQuery.sizeOf` returns `Size.zero` below it and every
      // width-dependent decision in the tree silently takes its narrowest
      // branch. The screen gutter is one of those, so a gutter test under a
      // replaced MediaQuery would measure the compact value at every width and
      // pass whatever the screen did.
      child: Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            platformBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
          child: MemoxApp(router: router),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();

  // Returned so a test can assert *where* a tap landed rather than only that
  // something happened — which is the whole of a drill-down's behaviour.
  return router;
}

/// Pumps one screen on its own, without the router.
Future<void> pumpProgressScreen(
  WidgetTester tester, {
  required ProgressRepository repository,
  required Widget screen,
  Size surface = const Size(393, 852),
  double textScale = 1,
  bool isDark = false,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        progressRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => progressTestNow),
        utcOffsetProvider.overrideWithValue(() => progressTestOffset),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Builder(
          // `copyWith` for the reason `pumpProgressApp` states: a fresh
          // `MediaQueryData` drops `size`, and every width-dependent decision
          // below then reads zero.
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: screen,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}
