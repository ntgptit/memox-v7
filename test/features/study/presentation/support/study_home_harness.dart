import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/di/deck_template_provider.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_template_repository.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/models/study_home_deck_model.dart';

import '../../../deck/presentation/support/fake_deck_repository.dart';
import '../../domain/support/fake_study_home_repository.dart';
import '../../domain/support/fake_study_repository.dart';

/// One way to put Study Home on screen, shared by every test that measures it.
///
/// **Pumped through the real router inside the real shell**, because half of
/// what these files assert — the gutter, the clearance above the bottom bar,
/// where a tap lands — is a property of what the screen is mounted *in*. A bare
/// pump would measure a layout the app never renders, and a navigation asserted
/// against a callback says nothing about whether the route exists. The fixture
/// this screen replaced was exactly that failure: a constant naming a deck that
/// was not there.
///
/// Its own file because four test files need it and the guard caps a source file
/// at 400 lines — a cap that split them, and a shared harness is what keeps the
/// four from drifting into four slightly different screens.
final class StudyHomeHarness {
  /// The instant every render measures against, unless a test moves [clockNow].
  ///
  /// Fixed, because the split between overdue and due today turns on the local
  /// day (BR-162) and a screen measured against the wall clock renders
  /// differently depending on when the suite runs.
  static final DateTime now = DateTime.utc(2026, 8, 13, 9);

  /// What `clockProvider` answers. Mutable for the one case that needs the
  /// screen re-read at a *different* instant.
  ///
  /// A pinned constant is right everywhere else and wrong there:
  /// `StudyHomeNow.refresh()` assigns the clock's value, so with a frozen clock
  /// it assigns the value already present, Riverpod sees no change, and nothing
  /// reloads — a reload test written against it passes whatever the screen does.
  DateTime clockNow = now;

  /// The repository behind the screen most recently pumped.
  late FakeStudyHomeRepository home;

  /// The session repository, kept so a test can assert nothing opened one.
  late FakeStudyRepository sessions;

  Future<void> dispose() => home.dispose();

  /// Puts Study Home on screen and returns the router driving it.
  ///
  /// [repository] replaces the default snapshot wholesale; [decks], [resume] and
  /// [failing] shape the default one. [locale] and [surface] are what the
  /// responsive and localisation cases vary.
  Future<GoRouterHandle> pump(
    WidgetTester tester, {
    FakeStudyHomeRepository? repository,
    List<StudyHomeDeckModel>? decks,
    bool hasResume = true,
    bool failing = false,
    bool pending = false,
    Size surface = const Size(393, 852),
    double textScale = 1,
    Locale? locale,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Forced through the platform dispatcher rather than through a parameter on
    // `MemoxApp`: production has exactly one way to resolve a locale, and a
    // test-only override on the app root would make the thing under test
    // different from the thing that ships.
    if (locale != null) {
      tester.platformDispatcher.localesTestValue = <Locale>[locale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    }

    home =
        repository ??
        FakeStudyHomeRepository(
          initial: fakeStudyHome(
            resume: hasResume ? fakeStudyHomeResume() : null,
            decks: decks,
          ),
          failure: failing ? StateError('read failed') : null,
          isPending: pending,
        );
    sessions = FakeStudyRepository();

    final router = createAppRouter(initialLocation: RoutePaths.study);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          studyRepositoryProvider.overrideWithValue(sessions),
          studyHomeRepositoryProvider.overrideWithValue(home),
          clockProvider.overrideWithValue(() => clockNow),
          utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
          // The starter catalog is a *destination* of this screen, so it has to
          // be able to build: a route asserted by name that lands on a screen
          // which throws is the same dead action the fixture was.
          deckTemplateCatalogProvider.overrideWith(
            (ref) async => <DeckTemplate>[],
          ),
          deckTemplateRepositoryProvider.overrideWithValue(
            const _EmptyTemplateRepository(),
          ),
        ],
        child: MediaQuery(
          // **`fromView`, then `copyWith`** — not a bare `MediaQueryData`. A
          // fresh one carries `Size.zero`, which makes every breakpoint read as
          // compact: the first version of the geometry test measured a 12dp
          // gutter on a 393dp screen, a number that is right about a screen the
          // app never renders.
          data: MediaQueryData.fromView(
            tester.view,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: MemoxApp(router: router),
        ),
      ),
    );
    // `pump`, not `pumpAndSettle`, for a read that never lands: settling on a
    // spinner that spins forever times out on a screen behaving correctly.
    if (pending) {
      await tester.pump();
      return router;
    }
    await tester.pumpAndSettle();

    return router;
  }
}

/// The router type, re-exported so a test file need not import go_router just to
/// name the return of [StudyHomeHarness.pump].
typedef GoRouterHandle = GoRouter;

/// The template contract, answering "nothing installed" and nothing else.
///
/// Study Home's tests are about Study Home; what the starter catalog contains is
/// `starter_library_test.dart`'s subject. This exists so the destination route
/// can render at all.
final class _EmptyTemplateRepository implements DeckTemplateRepository {
  const _EmptyTemplateRepository();

  @override
  Future<DeckTemplateInstallOutcome> installTemplate(
    DeckTemplate template, {
    SchedulerType? schedulerType,
    bool allowDuplicate = false,
  }) => throw UnimplementedError('Study Home never installs a template');

  @override
  Future<Set<({String templateId, int version})>>
  installedTemplateKeys() async => const <({String templateId, int version})>{};
}
