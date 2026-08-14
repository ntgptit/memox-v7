import 'dart:async';

import 'package:flutter/widgets.dart';
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
import 'package:memox/features/deck/presentation/screens/starter_library_screen.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/presentation/controllers/study_home_now_controller.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/models/study_home_deck_model.dart';
import 'package:memox/features/study/domain/models/study_day_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/repositories/study_home_repository.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/study/presentation/widgets/items/study_home_deck_item_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_resume_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

import '../../deck/presentation/support/fake_deck_repository.dart';
import '../domain/support/fake_study_home_repository.dart';
import '../domain/support/fake_study_repository.dart';

/// Study Home, pumped through the real router (UC-12).
///
/// **Through the router, not as a bare widget.** Three of the four things this
/// screen does are navigations, and a navigation asserted against a callback is
/// an assertion that a callback fires — it says nothing about whether the route
/// exists. The fixture this screen replaced was exactly that failure mode in
/// production: a constant naming a deck that was not there.
void main() {
  final english = AppLocalizationsEn();

  /// The instant every render measures against. Fixed, because the split
  /// between overdue and due today turns on the local day (BR-162).
  final now = DateTime.utc(2026, 8, 13, 9);

  /// What `clockProvider` answers, advanced by the one test that needs the
  /// screen to be re-read at a *different* instant.
  ///
  /// A pinned constant is right for every other test here and wrong for that
  /// one: `StudyHomeNow.refresh()` assigns the clock's value, so with a frozen
  /// clock it assigns the value already there, Riverpod sees no change and
  /// nothing reloads — a reload test written against it passes whatever the
  /// screen does.
  late DateTime clockNow;

  setUp(() => clockNow = now);

  final starterCatalogOverrides = [
    deckTemplateCatalogProvider.overrideWith((ref) async => <DeckTemplate>[]),
    deckTemplateRepositoryProvider.overrideWithValue(
      const _EmptyTemplateRepository(),
    ),
  ];

  late FakeStudyHomeRepository homeRepository;

  setUp(() => homeRepository = FakeStudyHomeRepository());
  tearDown(() => homeRepository.dispose());

  /// The Study verb *inside a row*, never the tab label or the app-bar title.
  ///
  /// All three read "Study", so an unscoped `find.text` matches the chrome and
  /// would keep passing after the rows stopped rendering at all.
  final studyButton = find.descendant(
    of: find.byType(StudyHomeDeckItemWidget),
    matching: find.text(english.studyHomeStudyAction),
  );

  Future<GoRouter> pumpHome(
    WidgetTester tester, {
    FakeStudyHomeRepository? repository,
  }) async {
    if (repository != null) {
      // The one built in `setUp` is replaced rather than left open beside it:
      // an unclosed controller is a subscription nothing ever cancels.
      await homeRepository.dispose();
      homeRepository = repository;
    }
    final router = createAppRouter(initialLocation: RoutePaths.study);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
          studyHomeRepositoryProvider.overrideWithValue(homeRepository),
          clockProvider.overrideWithValue(() => clockNow),
          utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
          // The starter catalog is a *destination* of this screen, so it has to
          // be able to build: a route asserted by name that lands on a screen
          // which throws is the same dead action the fixture was.
          ...starterCatalogOverrides,
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  group('states', () {
    testWidgets('the first read shows a labelled spinner, not a blank tab', (
      tester,
    ) async {
      final router = createAppRouter(initialLocation: RoutePaths.study);
      addTearDown(router.dispose);
      // A repository whose stream never delivers: the loading state is the one
      // state that cannot be reached by settling.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            envConfigProvider.overrideWithValue(EnvConfig.development),
            deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
            studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
            studyHomeRepositoryProvider.overrideWithValue(
              _PendingStudyHomeRepository(),
            ),
            clockProvider.overrideWithValue(() => clockNow),
            utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
          ],
          child: MemoxApp(router: router),
        ),
      );
      await tester.pump();

      expect(find.byType(MxLoadingState), findsOneWidget);
    });

    testWidgets('a resume and a mixed library render both bands', (
      tester,
    ) async {
      await pumpHome(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(resume: fakeStudyHomeResume()),
        ),
      );

      expect(find.byType(StudyHomeResumeSectionWidget), findsOneWidget);
      expect(find.byType(StudyHomeDeckItemWidget), findsNWidgets(2));
      expect(find.text(english.studyHomeNextTitle), findsOneWidget);
    });

    testWidgets('no open session means no resume card at all', (tester) async {
      await pumpHome(tester);

      // Not an empty card and not a disabled button: with nothing to continue,
      // the band would be a heading over nothing.
      expect(find.byType(StudyHomeResumeSectionWidget), findsNothing);
      expect(find.text(english.studyHomeResumeTitle), findsNothing);
    });

    testWidgets('every count shows, zeroes included', (tester) async {
      await pumpHome(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(
            decks: <StudyHomeDeckModel>[
              fakeStudyHomeDeck(
                deckId: 'a',
                deckName: 'Quiet deck',
                totalCardCount: 30,
              ),
            ],
          ),
        ),
      );

      // An absent metric is ambiguous in exactly the way the line exists to
      // prevent — "no overdue count" could mean none, or could mean untracked.
      expect(find.text(english.studyHomeOverdueLabel(0)), findsOneWidget);
      expect(find.text(english.studyHomeDueTodayLabel(0)), findsOneWidget);
      expect(find.text(english.studyHomeNewLabel(0)), findsOneWidget);
      // And the row keeps its way in: BR-29 makes nothing due the schedule
      // working rather than a locked door. Scoped to the row, because the tab
      // label and the screen title are the same word — an unscoped finder would
      // pass on the chrome alone.
      expect(studyButton, findsOneWidget);
      expect(find.text(english.studyHomeNothingDueMessage), findsOneWidget);
    });

    testWidgets('the supporting line matches whether there is a resume', (
      tester,
    ) async {
      await pumpHome(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(resume: fakeStudyHomeResume()),
        ),
      );

      expect(find.text(english.studyHomeSupportingCopy), findsOneWidget);
      expect(find.text(english.studyHomeSupportingCopyNoResume), findsNothing);
    });

    testWidgets('with nothing open it stops promising somewhere to carry on', (
      tester,
    ) async {
      // BR-182 needs four conditions at once, so no open session is the
      // ordinary state — and the line above the list said "or carry on where
      // you stopped" over a screen with no Resume card on it.
      await pumpHome(tester);

      expect(
        find.text(english.studyHomeSupportingCopyNoResume),
        findsOneWidget,
      );
      expect(find.text(english.studyHomeSupportingCopy), findsNothing);
    });

    testWidgets('the list heading is a heading to a screen reader', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpHome(tester);

      // The `xl` above it builds the section break visually; without this the
      // break is invisible to TalkBack, which hears the resume card run
      // straight into the first deck and cannot jump by heading.
      expect(
        tester.getSemantics(find.text(english.studyHomeNextTitle)),
        matchesSemantics(label: english.studyHomeNextTitle, isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('an empty library offers the starter catalog', (tester) async {
      await pumpHome(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(decks: const <StudyHomeDeckModel>[]),
        ),
      );

      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(find.text(english.studyHomeEmptyLibraryTitle), findsOneWidget);
      expect(find.text(english.studyHomeStarterAction), findsOneWidget);
    });

    testWidgets('decks with no cards is a different state from no decks', (
      tester,
    ) async {
      await pumpHome(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(
            decks: <StudyHomeDeckModel>[
              fakeStudyHomeDeck(deckId: 'a', deckName: 'A', totalCardCount: 0),
            ],
          ),
        ),
      );

      expect(find.text(english.studyHomeNoCardsTitle), findsOneWidget);
      // The library, not the catalog: the decks already exist.
      expect(find.text(english.studyHomeOpenLibraryAction), findsOneWidget);
      expect(find.text(english.studyHomeStarterAction), findsNothing);
      // And no invented workload for a deck that holds nothing.
      expect(find.byType(StudyHomeDeckItemWidget), findsNothing);
    });

    testWidgets('a failed read offers a retry that re-reads', (tester) async {
      final failing = FakeStudyHomeRepository(failure: StateError('nope'));
      addTearDown(failing.dispose);
      await pumpHome(tester, repository: failing);

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.studyHomeErrorTitle), findsOneWidget);

      final before = failing.subscriptions;
      await tester.tap(find.text(english.retryAction));
      await tester.pumpAndSettle();

      expect(failing.subscriptions, greaterThan(before));
    });
  });

  group('actions', () {
    testWidgets('Study opens the deck entry inside the Study branch', (
      tester,
    ) async {
      final router = await pumpHome(tester);

      await tester.tap(studyButton.first);
      await tester.pumpAndSettle();

      expect(find.byType(StudyEntryScreen), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/study/root-a',
      );
    });

    testWidgets('Resume opens the session screen, not the deck entry', (
      tester,
    ) async {
      await pumpHome(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(resume: fakeStudyHomeResume()),
        ),
      );

      await tester.tap(find.text(english.studyHomeResumeAction));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // The entry screen is where the *choice* between learning and reviewing is
      // made; a resume has already made it (BR-103).
      expect(find.byType(StudyEntryScreen), findsNothing);
      expect(find.byType(StudyHomeScreen), findsNothing);
    });

    testWidgets('two taps in one frame open one screen', (tester) async {
      final router = await pumpHome(tester);

      final study = studyButton.first;
      await tester.tap(study);
      await tester.tap(study, warnIfMissed: false);
      await tester.pumpAndSettle();

      // One entry screen, not two stacked on the branch. BR-101: a session
      // exists because the user asked for one, not because a finger bounced.
      expect(find.byType(StudyEntryScreen), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/study/root-a',
      );
    });

    testWidgets('two taps a frame apart still open one screen', (tester) async {
      // The guard only spans one frame, so a real double tap — a hundred
      // milliseconds apart — goes through it. BR-182 promises one open either
      // way, and what actually delivers that is `go` to a location already
      // current replacing the same match list rather than pushing a second
      // route. Asserted here so the promise does not rest on the guard alone.
      final router = await pumpHome(tester);

      await tester.tap(studyButton.first);
      await tester.pump(const Duration(milliseconds: 120));
      await tester.tap(studyButton.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(StudyEntryScreen), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/study/root-a',
      );
    });

    testWidgets('the starter action reaches the real catalog route', (
      tester,
    ) async {
      await pumpHome(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(decks: const <StudyHomeDeckModel>[]),
        ),
      );

      await tester.tap(find.text(english.studyHomeStarterAction));
      await tester.pumpAndSettle();

      // A real route, not a snackbar saying it is not built yet.
      expect(find.byType(StarterLibraryScreen), findsOneWidget);
    });
  });

  group('the screen is a read', () {
    testWidgets('rendering and scrolling open no session', (tester) async {
      final sessionRepository = FakeStudyRepository();
      final router = createAppRouter(initialLocation: RoutePaths.study);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            envConfigProvider.overrideWithValue(EnvConfig.development),
            deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
            studyRepositoryProvider.overrideWithValue(sessionRepository),
            studyHomeRepositoryProvider.overrideWithValue(homeRepository),
            clockProvider.overrideWithValue(() => clockNow),
            utcOffsetProvider.overrideWithValue(() => const Duration(hours: 7)),
          ],
          child: MemoxApp(router: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(StudyHomeScreen), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(sessionRepository.opened, isEmpty);
    });

    testWidgets('a failure after the first snapshot reaches the error state', (
      tester,
    ) async {
      // **A transition that only exists since the DAO forwards `onError`.**
      // Before, an error on the update bus was swallowed and the tab sat on
      // stale counts indefinitely; now it arrives, and BR-184 wants it on
      // screen with a retry. The other error test fails at *subscribe*, which
      // is a different moment and a different code path.
      await pumpHome(tester);
      expect(find.byType(StudyHomeDeckItemWidget), findsNWidgets(2));

      homeRepository.emitError(StateError('update bus failed'));
      await tester.pumpAndSettle();

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.studyHomeErrorTitle), findsOneWidget);
      expect(find.text(english.retryAction), findsOneWidget);
    });

    testWidgets('re-measuring the clock does not blank the tab', (
      tester,
    ) async {
      // Coming back to the foreground, and every due boundary, moves
      // `studyHomeNowProvider` — which this stream watches, so Riverpod calls it
      // a *reload* rather than a refresh. With the shared default the whole tab
      // became a spinner and the list lost its scroll offset, for a re-read that
      // asks the same question one instant later.
      await pumpHome(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(
            resume: fakeStudyHomeResume(),
            decks: <StudyHomeDeckModel>[
              for (var i = 0; i < 12; i++)
                fakeStudyHomeDeck(
                  deckId: 'deck-$i',
                  deckName: 'Deck number $i',
                  newCount: 12 - i,
                ),
            ],
          ),
        ),
      );

      // Scrolled first, because the claim is about two things and the second —
      // that the list keeps its place — cannot be observed at offset zero.
      final position = Scrollable.of(
        tester.element(find.byType(StudyHomeDeckItemWidget).first),
      ).position;
      position.jumpTo(400);
      await tester.pumpAndSettle();
      expect(position.pixels, 400);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(StudyHomeScreen)),
      );
      // A *different* instant, so the notifier's state genuinely changes and
      // the stream provider is genuinely reloaded. Assigning the same value
      // changes nothing and would make this test agree with any implementation.
      clockNow = now.add(const Duration(minutes: 7));
      container.read(studyHomeNowProvider.notifier).refresh();
      expect(container.read(studyHomeNowProvider), clockNow);

      await tester.pump();
      expect(find.byType(MxLoadingState), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(MxLoadingState), findsNothing);
      // The list was never torn down, so it never went back to the top.
      expect(
        Scrollable.of(
          tester.element(find.byType(StudyHomeDeckItemWidget).first),
        ).position.pixels,
        400,
      );
    });

    testWidgets('a new snapshot replaces the counts without a spinner', (
      tester,
    ) async {
      await pumpHome(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(resume: fakeStudyHomeResume()),
        ),
      );

      expect(find.byType(StudyHomeResumeSectionWidget), findsOneWidget);

      // What a finished session looks like from here: the stream re-emits
      // without the resume.
      homeRepository.emit(fakeStudyHome());

      // Frame by frame, because the claim is about what is on screen *during*
      // the refresh: `skipLoadingOnRefresh` is what keeps a populated tab from
      // being replaced by a spinner, and settling first would step over the one
      // frame that could show one.
      await tester.pump();
      expect(find.byType(MxLoadingState), findsNothing);
      await tester.pump();
      expect(find.byType(MxLoadingState), findsNothing);

      expect(find.byType(StudyHomeResumeSectionWidget), findsNothing);
      expect(find.byType(StudyHomeDeckItemWidget), findsNWidgets(2));
    });
  });
}

/// The template contract, answering "nothing installed" and nothing else.
///
/// Study Home's tests are about Study Home; what the starter catalog *contains*
/// is `starter_library_test.dart`'s subject. This exists so the destination
/// route can render at all.
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

/// A repository whose read never lands — the only way to hold the loading state
/// still long enough to assert on it.
///
/// A controller that is never fed, not `Stream.empty()`: an empty stream closes
/// at once, and a closed stream with no value is a state Riverpod is entitled to
/// treat differently from one still in flight.
final class _PendingStudyHomeRepository implements StudyHomeRepository {
  @override
  Stream<StudyHomeModel> watchStudyHome(StudyDayModel day) =>
      StreamController<StudyHomeModel>().stream;
}
