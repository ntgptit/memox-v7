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
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../deck/presentation/support/fake_deck_repository.dart';

/// The instant every Progress widget test is anchored to.
///
/// Wednesday 12 August 2026, midday UTC. A fixed clock is not tidiness: the
/// chart's row labels are weekday names, so a suite that read the wall clock
/// would assert different words depending on the day it ran.
final DateTime progressTestNow = DateTime.utc(2026, 8, 12, 12);

/// A **non-zero** offset, for the tests whose subject is that the offset is
/// threaded at all.
///
/// The screen harness below defaults to zero so a fixture's calendar dates and
/// the dates the screen renders are the same by construction; that is the right
/// default for reading a rendered week, and useless for proving the value moved.
/// Anything asserting the offset reached the repository uses this instead.
const Duration progressTestOffset = Duration(hours: 7);

/// Pumps `ProgressScreen` on its own, for the state matrix.
///
/// No router: the screen has no route of its own to push and nothing to
/// navigate to except the Study branch, which [pumpProgressApp] exercises for
/// real.
Future<void> pumpProgressScreen(
  WidgetTester tester, {
  required ProgressRepository repository,

  /// Which Progress surface to mount.
  ///
  /// Defaults to the composed `/progress` screen. A level test passes
  /// `ProgressDeckScreen(deckId: ...)` instead — the two arrived as separate
  /// features with a harness each, and one harness with a parameter is what
  /// stops them drifting into two ways of standing the same providers up.
  Widget screen = const ProgressScreen(),

  /// Zero unless a test's subject is the offset itself — see
  /// [progressTestOffset].
  Duration utcOffset = Duration.zero,
  Size surface = const Size(393, 852),
  double textScale = 1,
  bool isDark = false,
  Locale? locale,

  /// A movable clock, for the one case that needs time to pass on screen: the
  /// local-midnight rollover (UC-12 A4). Every other test pins the instant,
  /// because a screen that read the wall clock would render different weekday
  /// labels depending on the day the suite ran.
  DateTime Function()? clock,
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        progressRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(clock ?? () => progressTestNow),
        // Zero, so a fixture day and the day the screen renders it in are the
        // same by construction. The offset arithmetic itself is tested where it
        // belongs — against the domain and against real SQLite.
        utcOffsetProvider.overrideWithValue(() => utcOffset),
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
        // `copyWith`, never a fresh `MediaQueryData`. Constructing one from
        // scratch here replaces `size` with `Size.zero`, which silently makes
        // every width-dependent decision take its narrowest branch — the
        // compact gutter fires at 412, and a geometry test written against it
        // would then pin the wrong number and stay green forever.
        home: Builder(
          builder: (context) => MediaQuery(
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

/// Pumps the whole app on `/progress` — real router, real shell, real bottom
/// bar.
///
/// Everything about navigation is asserted through this: the empty face's call
/// to action has to *arrive* somewhere, and a fake callback would prove only
/// that a closure ran.
Future<GoRouter> pumpProgressApp(
  WidgetTester tester, {
  required ProgressRepository repository,

  /// Where the app opens. A drill-down test needs `/progress/:deckId`, and
  /// asserting on a level means arriving at it the way the user does.
  String initialLocation = RoutePaths.progress,
  Size surface = const Size(393, 852),
  double textScale = 1,
  bool isDark = false,
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // Set on the platform dispatcher rather than in a `MediaQuery` above the
  // app: `WidgetsApp` builds its own `MediaQuery` from the view, so an ancestor
  // one does not reach the screen and a scale set that way would be measuring
  // nothing.
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.platformBrightnessTestValue = isDark
      ? Brightness.dark
      : Brightness.light;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

  final router = createAppRouter(initialLocation: initialLocation);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        progressRepositoryProvider.overrideWithValue(repository),
        // The Study branch reads the deck tree when it opens, so arriving there
        // needs a deck repository even though nothing here asserts on decks.
        deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
        clockProvider.overrideWithValue(() => progressTestNow),
        utcOffsetProvider.overrideWithValue(() => Duration.zero),
      ],
      child: MemoxApp(router: router),
    ),
  );
  await tester.pump();
  await tester.pump();

  return router;
}
