import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/database/app_database.dart';
import '../core/database/app_database_provider.dart';
import '../core/navigation/route_names.dart';
import '../core/state/provider_observer.dart';
import '../core/time/clock_provider.dart';
import 'di/repository_bindings.dart';
import 'app.dart';
import 'config/env_config.dart';
import 'config/env_config_provider.dart';
import 'error_screen_widget.dart';
import 'router/app_router.dart';
import 'startup/fixture_seeder_widget.dart';
import 'startup/reminder_reconciler_widget.dart';

/// Restores the error handlers that were installed before
/// [installErrorHandlers] replaced them.
typedef RestoreErrorHandlers = void Function();

/// Whether this build exists to be driven by the Playwright suite.
///
/// Set by `--dart-define=MEMOX_E2E=true`, which only `e2e/` passes. It is a
/// compile-time constant, so a normal build has the branch below removed
/// entirely rather than carrying a runtime check.
const bool isE2EBuild = bool.fromEnvironment('MEMOX_E2E');

/// Holds the semantics tree open for the whole run.
///
/// **Playwright can only see what semantics publishes.** Flutter Web paints to
/// a canvas; the DOM the driver reads is the semantics tree, and the engine
/// normally builds it only after the user activates the hidden "Enable
/// accessibility" placeholder. Worse for a test, the engine switches back to
/// raw pointer handling once it sees ordinary pointer events — so a suite that
/// enables semantics by clicking that placeholder watches the tree disappear the
/// moment it taps anything, which reads as "the deck was never created" when the
/// deck is plainly on screen.
///
/// `ensureSemantics` takes a handle that keeps the tree alive; the handle is
/// deliberately never released, because the run ends when the page closes.
///
/// **Compiled out of every real build.** Semantics has a real cost — a second
/// tree, rebuilt on every frame — and no user benefits from it being on when no
/// assistive technology asked. `isE2EBuild` is a `const`, so this call does not
/// exist in the shipped binary.
void keepSemanticsOn(WidgetsBinding binding) => binding.ensureSemantics();

/// Single owner of application startup.
///
/// The entrypoints pick a config and call this; they hold no initialisation
/// logic of their own. One startup path is what lets three flavors share the
/// same behaviour, and what lets a test drive startup with a fake config
/// instead of reproducing it.
///
/// Order matters, because later steps report their failures through earlier
/// ones: bindings, then error handlers, then the app. M4.2 will open the
/// database between the handlers and `runApp` — a database that fails to open
/// is a startup failure the user must see, not a silent crash loop.
Future<void> bootstrap(EnvConfig config) async {
  // The zone catches async errors raised outside the Flutter framework, which
  // `PlatformDispatcher.onError` does not always see. Both are installed
  // because each misses what the other catches.
  runZonedGuarded<void>(() {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    installErrorHandlers(logLevel: config.logLevel);
    if (isE2EBuild) keepSemanticsOn(binding);

    try {
      runApp(buildRootWidget(config));
    } on Object catch (error, stackTrace) {
      // `on Object` rather than a bare `catch`: the analyzer requires the
      // clause, and the width is deliberate — nothing thrown during startup may
      // escape, whatever its type.
      //
      // A startup failure must reach the user as a screen. A white window is
      // the worst available outcome because it is indistinguishable from a
      // hang, and the user has nothing to report.
      logStartupFailure(error, stackTrace);
      runApp(const ErrorScreenWidget(kind: AppErrorKind.startup));
    }
  }, (error, stackTrace) => _log('uncaught async error', error, stackTrace));
}

/// The widget tree `bootstrap` hands to `runApp`.
///
/// Separated from [bootstrap] so a widget test can mount the real root — and
/// assert the config override actually reached it — without going through
/// `runZonedGuarded` and `runApp`. `flutter_test` owns its own zone and its own
/// binding; calling `runApp` inside a fresh zone from a test hangs instead of
/// failing, which costs minutes per run to discover.
///
/// [database] and [now] substitute the two things an end-to-end run must
/// control, and they are named types rather than a list of overrides because
/// riverpod's `Override` is not part of the public API.
///
/// They belong *here* rather than in an outer `ProviderScope`, which looks
/// equivalent and is not: a provider nobody overrides — `deckList`, say — is
/// hosted by the outermost container, so it resolves `deckRepositoryProvider`
/// there, where the bindings below have not been installed, and the screen
/// renders "a provider that is in error state" instead of its data.
/// [shouldSeedFixtures] false stops the development fixture seed from running.
///
/// **The end-to-end suite owns its own data, and the seed writes into it.**
/// `CLEAN-RESET` wipes the library before a scenario; the seeder then copies the
/// shipped decks back in one frame later, so a scenario asserting an empty
/// library found "Everyday English" instead — and whether it did depended on
/// which of the two finished first, which is why the failures looked
/// intermittent. A scenario that wants content loads it explicitly through
/// `ItFixtures`.
Widget buildRootWidget(
  EnvConfig config, {
  AppDatabase? database,
  DateTime Function()? now,
  GoRouter? router,
  bool shouldSeedFixtures = true,
}) => ProviderScope(
  overrides: [
    envConfigProvider.overrideWithValue(config),
    // The composition root binding a contract to an implementation. Each
    // feature declares its provider as the domain type and never names the
    // `*Impl`; `repositoryBindingOverrides` is the list that does.
    ...repositoryBindingOverrides(),
    if (database != null) appDatabaseProvider.overrideWithValue(database),
    if (now != null) clockProvider.overrideWithValue(now),
  ],
  // Provider failures are always reported: Riverpod 3 retries a failed provider
  // ten times and shows `AsyncLoading` throughout, so without this a broken read
  // is thirteen seconds of spinner and no exception anywhere. State transitions
  // are chatter by comparison, so they follow the configured log level.
  observers: [
    MemoxProviderObserver(
      shouldLogStateChanges: config.logLevel == LogLevel.debug,
    ),
  ],
  // The fixture seed sits inside the scope so it reads the bindings above,
  // and wraps rather than replaces the app so the first frame is the deck
  // list rather than a spinner waiting on assets.
  // [router] is the third seam, and it is a test-only one for the reason
  // `MemoxApp.router` documents: a `GoRouter` carries navigation history, so
  // one shared instance lets a route entered by one test decide where the next
  // one starts. Production passes nothing and gets the single `appRouter`.
  // The reminder reconciler wraps the seeder rather than the other way round:
  // it is the outermost startup concern and the only one that must run in every
  // flavor, while the seed is development-only. Both sit inside the scope so
  // they read the bindings above.
  //
  // `router ?? appRouter` is evaluated **inside** the closure so a test that
  // supplies its own router never constructs the global one — and so a tapped
  // reminder navigates the router the app is actually running (BR-189).
  child: ReminderReconcilerWidget(
    onOpenStudy: () => (router ?? appRouter).goNamed(RouteNames.study),
    child: shouldSeedFixtures
        ? FixtureSeederWidget(child: MemoxApp(router: router))
        : MemoxApp(router: router),
  ),
);

/// Installs the three error boundaries and returns a callback that puts the
/// previous ones back.
///
/// The restore callback exists for tests: these are global, so a test that
/// installs them without restoring changes the behaviour of every test that
/// runs afterwards, and the resulting failure appears in an unrelated file.
RestoreErrorHandlers installErrorHandlers({required LogLevel logLevel}) {
  final previousFlutterOnError = FlutterError.onError;
  final previousPlatformOnError = PlatformDispatcher.instance.onError;
  final previousErrorWidgetBuilder = ErrorWidget.builder;

  // Framework errors, including build errors.
  FlutterError.onError = (details) {
    _log('flutter error', details.exception, details.stack);
    // Keep the framework's own reporting in debug: it prints the widget
    // hierarchy, which is the part that actually locates the bug.
    if (kDebugMode) FlutterError.presentError(details);
  };

  // Uncaught async errors that reach the platform.
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    _log('platform error', error, stackTrace);
    return true;
  };

  // Replaces the red screen. In release it would otherwise show the exception
  // text to the user; in debug the red screen is genuinely useful, so it stays.
  ErrorWidget.builder = (details) {
    _log('widget build error', details.exception, details.stack);
    if (kDebugMode) return _debugErrorWidget(details);

    return const ErrorScreenWidget(kind: AppErrorKind.render);
  };

  return () {
    FlutterError.onError = previousFlutterOnError;
    PlatformDispatcher.instance.onError = previousPlatformOnError;
    ErrorWidget.builder = previousErrorWidgetBuilder;
  };
}

/// Reports a failure that happened before the app could render.
@visibleForTesting
void logStartupFailure(Object error, StackTrace? stackTrace) =>
    _log('startup failure', error, stackTrace);

/// In debug builds the developer is the audience, so show the real error.
Widget _debugErrorWidget(FlutterErrorDetails details) =>
    ErrorWidget(details.exception);

/// Minimal structured logging via `dart:developer`.
///
/// Deliberately not a logging abstraction — that is M7's job, and building one
/// now would be a guess at requirements that do not exist yet. `print` is
/// banned by `analysis_options.yaml`; this is the supported alternative and it
/// is stripped from release output by the VM service being absent.
void _log(String context, Object error, StackTrace? stackTrace) {
  developer.log(
    context,
    name: 'memox.bootstrap',
    error: error,
    stackTrace: stackTrace,
    level: 1000, // SEVERE
  );
}
