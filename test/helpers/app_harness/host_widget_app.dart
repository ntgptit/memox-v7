/// Mounts the **real application** on a host test: real `ProviderScope`, real
/// bindings, real GoRouter, real localizations, real theme — over an in-memory
/// SQLite database and an injected clock.
///
/// This is what a `HOST-WIDGET` scenario runs on. Everything below the widget
/// is the production wiring; the only substitutions are the two an end-to-end
/// run must control, plus a router per test.
///
/// **It calls `buildRootWidget` rather than assembling its own `ProviderScope`,
/// and that is the whole design.** A harness that listed the bindings by hand
/// is exactly how this project lost its integration suite once: a repository
/// binding grew a dependency on a second feature's contract, the hand-written
/// list in the harness did not, and every scenario threw in `setUp`. Reusing
/// the composition root means a binding added to the app is a binding the tests
/// get for free — and a binding the tests cannot silently miss.
///
/// **`shouldSeedFixtures` is false, always.** The development seeder copies the
/// shipped decks in one frame after startup. A test asserting an empty library
/// would find "Everyday English" instead, and whether it did depended on which
/// finished first — which is why those failures used to look intermittent. A
/// test that wants content writes it into [HostWidgetApp.db] before pumping.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/bootstrap.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/core/database/app_database.dart';

import '../../database/support/test_database.dart';

/// What a mounted app hands back to the test that mounted it.
class HostWidgetApp {
  const HostWidgetApp({required this.db, required this.router});

  /// The database the app is reading. Seed it **before** [pumpHostApp], or
  /// write to it during a test and pump again to see the streams react.
  final AppDatabase db;

  /// This test's own router. Read `router.state.uri` to assert where the app
  /// ended up, rather than inferring location from what happens to be on
  /// screen — two routes can render the same widget.
  final GoRouter router;
}

/// Creates the database a test will seed and then hand to [pumpHostApp].
///
/// Separate from mounting because order matters: a stream provider reads at
/// its first build, so rows written after the pump arrive as an update rather
/// than as the first frame — which is a different thing to assert and usually
/// not the thing the scenario means.
AppDatabase createHostDatabase() => openTestDatabase();

/// Mounts the app, runs [body] against it, and takes it down again.
///
/// **The teardown is here rather than in the test, because the app arms real
/// timers and a forgotten teardown does not fail where it was forgotten.** The
/// deck list schedules a one-shot for the next due boundary; flutter_test ends
/// a test by unmounting the tree and asserting no timer is left pending, and
/// Riverpod disposes a scope one microtask later — so the assertion lands
/// first, on a test that did nothing wrong, with a message about a timer it
/// never mentions. Worse, the failure poisons the run: the next test in the
/// file inherits the pending timer and hangs rather than fails.
///
/// So the mount and the unmount are one call. A test cannot take the first
/// without the second.
Future<void> runHostApp(
  WidgetTester tester,
  Future<void> Function(HostWidgetApp app) body, {
  AppDatabase? database,
  DateTime? now,
  String initialLocation = RoutePaths.decks,
  Size surface = const Size(390, 780),
}) async {
  final app = await pumpHostApp(
    tester,
    database: database,
    now: now,
    initialLocation: initialLocation,
    surface: surface,
  );

  try {
    await body(app);
  } finally {
    // Unmount, then give the disposal its microtask and the cancelled timers
    // their frame. One pump is not enough: the scope disposes asynchronously.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Pumps the real app and settles it.
///
/// [now] is the instant the whole tree reads; nothing under `lib/features/`
/// calls `DateTime.now()` (AD-13), so fixing it here fixes it everywhere.
///
/// Prefer [runHostApp]: a test that mounts without unmounting leaves a pending
/// timer behind, and the failure surfaces somewhere else.
Future<HostWidgetApp> pumpHostApp(
  WidgetTester tester, {
  AppDatabase? database,
  DateTime? now,
  String initialLocation = RoutePaths.decks,
  Size surface = const Size(390, 780),
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final db = database ?? createHostDatabase();
  final router = createAppRouter(initialLocation: initialLocation);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    buildRootWidget(
      EnvConfig.development,
      database: db,
      now: now == null ? null : () => now,
      router: router,
      shouldSeedFixtures: false,
    ),
  );
  await settleHostApp(tester);

  return HostWidgetApp(db: db, router: router);
}

/// Pumps until the tree stops changing, or until [limit] frames have passed.
///
/// **Not `pumpAndSettle`, deliberately.** A screen that is genuinely waiting —
/// a spinner over a stream that has not emitted — never stops scheduling
/// frames, and `pumpAndSettle` answers that by blocking for its ten-minute
/// default and then failing with a timeout that says nothing about which
/// screen it was on. A bounded pump gets the same frames and leaves the test to
/// assert what it actually meant, so a stuck screen fails as "the deck list is
/// still loading" rather than as a hung run.
Future<void> settleHostApp(
  WidgetTester tester, {
  int limit = 60,
  Duration frame = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < limit; i++) {
    await tester.pump(frame);
    if (!tester.binding.hasScheduledFrame) return;
  }
}
