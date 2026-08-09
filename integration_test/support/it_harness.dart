import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/bootstrap.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/di/repository_bindings.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/app_database_provider.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';

/// The fixed instant every time-dependent scenario is measured against.
///
/// `00-agent-execution-guide.md` §4 pins it, and the guide's own rule is that a
/// run which cannot pin the clock reports `BLOCKED` rather than `FAIL` — so the
/// value lives in one place and every fixture derives from it rather than
/// re-deriving "now".
final DateTime kT0 = DateTime.parse('2026-08-05T09:00:00+09:00').toUtc();

/// Drives the IT scenario suite against the real app on a real device.
///
/// **It mounts `buildRootWidget`, not a hand-assembled tree.** That function is
/// the composition root: it binds each repository contract to its
/// implementation and installs the provider observer. A harness that rebuilt
/// that wiring would be testing a second app that merely resembles the one
/// users run, and the two would drift apart at the first binding change.
///
/// The database and the clock go in through `buildRootWidget`'s own parameters,
/// not an outer `ProviderScope`. The outer arrangement was tried first and
/// fails in a way worth remembering: a provider nobody overrides is hosted by
/// the outermost container, so `deckList` resolved `deckRepositoryProvider`
/// where no binding existed and every screen rendered its error state.
///
/// The database is the app's own file, opened through `AppDatabase.open()`.
/// An in-memory database would make persistence and restart unprovable, and
/// those are exactly the claims this suite exists to make.
final class ItHarness {
  ItHarness._(this._tester);

  final WidgetTester _tester;
  AppDatabase? _database;
  DateTime _now = kT0;

  /// Opens the harness for one scenario, wipes leftover data and returns it
  /// ready to mount.
  ///
  /// Cleanup runs at both ends deliberately. A scenario that fails mid-way
  /// leaves rows behind, and the next scenario's setup would then start from a
  /// state its preconditions never described — which reads as a second, phantom
  /// failure in an unrelated ID.
  static Future<ItHarness> open(WidgetTester tester) async {
    final harness = ItHarness._(tester);
    await harness._openDatabase();
    await harness.wipeAllData();

    return harness;
  }

  AppDatabase get database => _database!;

  /// Moves the harness clock. Fixtures that describe a due date relative to
  /// `T0` stay readable this way rather than each computing an offset.
  void setNow(DateTime value) => _now = value;

  /// Advances the harness clock by [step].
  ///
  /// A frozen clock stamps every row created in a scenario with the same
  /// instant, and `ORDER BY created_at DESC, id DESC` then falls through to
  /// the id tie-breaker — a random UUID comparison, so "newest first" becomes
  /// a coin flip per run (IT-CARD-008 failed on exactly this). Every write
  /// the robot drives ticks the clock first, the way wall time would.
  void tick([Duration step = const Duration(seconds: 1)]) =>
      _now = _now.add(step);

  Future<void> _openDatabase() async {
    _database = AppDatabase.open();
  }

  /// Mounts the real application and settles the first frame.
  ///
  /// The router is sent back to the deck list first. `appRouter` is a global
  /// built once per process, so it survives from one scenario to the next: the
  /// previous test left it on `/decks/<id>`, `wipeAllData` then deleted that
  /// deck, and the next scenario opened on "Deck not found" before its first
  /// step ran. A real cold start begins at the deck list, and this is the only
  /// place that difference can be reset.
  Future<void> launchApp() async {
    appRouter.goNamed(RouteNames.decks);
    await _tester.pumpWidget(
      buildRootWidget(
        EnvConfig.development,
        database: _database,
        now: () => _now,
        // **The suite owns its data.** `wipeAllData` runs before this, and the
        // development fixture seed would copy the shipped decks back in one
        // frame later — so a scenario asserting an empty library found
        // "Everyday English", and whether it did came down to which finished
        // first. A scenario that wants content loads it through `ItFixtures`.
        shouldSeedFixtures: false,
      ),
    );
    await settle();
  }

  /// Closes the app and the database, then opens both again on the same file.
  ///
  /// This is what `UI-RESTART` means inside one test process: the widget tree
  /// is discarded, the executor is closed, and the next read comes off disk
  /// rather than out of a live stream. It is not a process restart — the guide
  /// asks for one, and the difference is recorded in the run report rather than
  /// papered over. What it does prove is the claim those scenarios actually
  /// rest on: the data outlived the objects that wrote it.
  Future<void> restartApp() async {
    await _tester.pumpWidget(const SizedBox.shrink());
    await _tester.pump();
    await _closeDatabase();
    await _openDatabase();
    await launchApp();
  }

  /// Closes the database without being able to hang.
  ///
  /// Unmounting the tree already queued a close: the keep-alive provider's
  /// `onDispose` calls `close()` unawaited. Awaiting a second close on the
  /// same executor then raced the first and, twice now, never returned —
  /// 20-plus minutes of silence in the middle of a restart. The timeout keeps
  /// the second close an assist rather than a hostage.
  Future<void> _closeDatabase() async {
    final db = _database;
    if (db == null) return;
    try {
      await db.close().timeout(const Duration(seconds: 5));
    } on Object {
      // Already closing via the provider's own dispose; moving on is safe —
      // the next open works on a new executor either way.
    }
  }

  /// Delivers a location the way the **operating system** delivers one.
  ///
  /// Not [openLocation], and the difference is the entire point of
  /// `IT-PLAT-004`. `appRouter.go` is the app calling itself; a deep link
  /// arrives on the `flutter/navigation` channel as `pushRouteInformation`,
  /// crosses into the framework, and reaches `GoRouter` through
  /// `RouteInformationProvider` — a path with three seams in it that
  /// `openLocation` skips entirely.
  ///
  /// What this still does **not** prove is the Android intent filter that
  /// decides the OS hands the URL to MemoX at all. Nothing inside
  /// `flutter test` can prove that: the handoff happens before the process
  /// this code runs in exists. That half is `adb shell am start -a
  /// android.intent.action.VIEW -d URL`, and it is written down as owed in
  /// `docs/wbs-study.md` rather than papered over here.
  Future<void> deliverDeepLink(String location) async {
    await _tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(
        MethodCall('pushRouteInformation', <String, Object?>{
          'location': location,
        }),
      ),
      (_) {},
    );
    await settle();
  }

  /// Presses the Android system back button.
  ///
  /// Goes through the platform channel the OS itself uses, so what is tested is
  /// the same path a hardware back press takes — not `Navigator.pop`, which
  /// would skip whatever the router does with a back intent.
  Future<void> pressBack() async {
    // Bounded like every other await in this harness. After a restart plus a
    // last-card delete, one `handlePopRoute` future simply never completed —
    // the engine acknowledged nothing — and an un-timed await there turned a
    // walk of five backs into the fourth multi-round hang of this suite. On
    // timeout the pop either landed or it did not; the caller's next check
    // reads the screen and decides, which is all a back press ever promised.
    // The system dispatch, bounded. Going through the delegate directly was
    // tried when this future froze after a restart — but `popRoute` on the
    // delegate collapses a run of same-route pushes in one call, which turned
    // "one level up" into "back at the root". The OS path pops one page and is
    // what IT-NAV-003 verifies; the timeout keeps the one post-restart freeze
    // from ever holding the suite again.
    try {
      await _tester.binding.handlePopRoute().timeout(
        const Duration(seconds: 3),
      );
    } on Object {
      // Frozen or empty; the caller reads the screen and decides.
    }
    await settle();
  }

  /// Pumps until the tree stops changing, with a bounded wait.
  ///
  /// `pumpAndSettle` alone throws when something animates forever, and its
  /// timeout message names no scenario. Callers get the same behaviour plus a
  /// frame budget large enough for a Drift stream to deliver its first event on
  /// a cold emulator.
  Future<void> settle() async {
    try {
      await _tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );
    } on FlutterError {
      // Something is animating without end. The screen is still usable and the
      // assertions decide the verdict; three plain pumps let the frame finish.
      // Unbounded, this turned one busy spinner into a ten-minute hang that
      // took every later scenario in the file down as "did not complete".
      await _tester.pump();
      await _tester.pump();
      await _tester.pump();
    }
  }

  /// A container wired like the composition root, for fixture loaders.
  ///
  /// Same database, both repository bindings, and a clock that follows
  /// [setNow] — so a loader can create each card "at" its own instant and the
  /// rows carry the same timestamps real use would have produced.
  ProviderContainer seedContainer() => ProviderContainer(
    overrides: [
      // The whole list, not the two this happens to read. A binding that grows
      // a dependency on a third contract must not be able to break a container
      // that was written before it did — which is exactly how UC-07 turned every
      // scenario red at once.
      ...repositoryBindingOverrides(),
      appDatabaseProvider.overrideWithValue(_database!),
      clockProvider.overrideWithValue(() => _now),
    ],
  );

  /// Deletes every root deck through the repository contract, which cascades to
  /// sub-decks, cards, review states and tags.
  ///
  /// Deliberately not raw SQL. `CLEAN-RESET` is a data contract, not a schema
  /// operation, and routing it through the same delete the product uses means a
  /// cascade that regresses shows up here as leftover rows instead of hiding
  /// behind a `DELETE FROM`.
  Future<void> wipeAllData() async {
    final container = ProviderContainer(
      overrides: [
        // The same list the composition root installs. A contract left unbound
        // is contract-only, and reading it throws — in teardown, where it takes
        // the scenario with it.
        ...repositoryBindingOverrides(),
        appDatabaseProvider.overrideWithValue(_database!),
      ],
    );
    try {
      final repository = container.read(deckRepositoryProvider);
      // Bounded, because this runs in teardown: after one failing scenario the
      // stream sat on a first emission that never came, and an un-timed
      // `.first` turned that single failure into a 34-minute hang that took the
      // whole rest of the suite with it. On timeout, fall through to the raw
      // delete below — teardown is the one place the repository detour may be
      // skipped, and the cascade keeps the wipe complete.
      final roots = await repository.watchRootDecks().first.timeout(
        const Duration(seconds: 10),
        onTimeout: () => const <DeckEntity>[],
      );
      for (final DeckEntity root in roots) {
        await repository.deleteDeck(root.id);
      }
      await _database!.delete(_database!.decks).go();
    } finally {
      container.dispose();
    }
  }

  /// Releases the harness. Safe to call after a failure.
  ///
  /// The tree is torn down *first*, and that ordering is the whole point. A
  /// scenario that fails mid-way leaves whatever it was in — an open editor, a
  /// confirmation sheet, a modal barrier — mounted. Wiping the data underneath a
  /// live screen makes it rebuild against rows that no longer exist, and the
  /// next scenario then inherits both the overlay and a screen retrying a read:
  /// one real failure turned into an eight-minute timeout in an unrelated ID
  /// once already.
  Future<void> dispose() async {
    await _tester.pumpWidget(const SizedBox.shrink());
    await _tester.pump();
    await wipeAllData();
    await _closeDatabase();
    _database = null;
  }
}
