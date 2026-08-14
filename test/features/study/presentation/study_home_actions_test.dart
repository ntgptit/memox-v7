import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_home_deck_model.dart';
import 'package:memox/features/study/presentation/widgets/items/study_home_deck_item_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_home_resume_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../domain/support/fake_study_home_repository.dart';
import 'support/study_home_harness.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/deck/presentation/screens/starter_library_screen.dart';
import 'package:memox/features/study/presentation/controllers/study_home_now_controller.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

/// What Study Home does when it is touched — and what it refuses to do when it
/// is not (UC-12, BR-182, BR-101).
///
/// **Driven through the real router.** Three of the four actions are
/// navigations, and a navigation asserted against a callback is an assertion
/// that a callback fires: it says nothing about whether the route exists. The
/// fixture this screen replaced was exactly that failure in production.
void main() {
  final english = AppLocalizationsEn();

  late StudyHomeHarness harness;

  setUp(() => harness = StudyHomeHarness());
  tearDown(() => harness.dispose());

  /// The Study verb *inside a row*, never the tab label or the app-bar title.
  ///
  /// All three read "Study", so an unscoped `find.text` matches the chrome and
  /// would keep passing after the rows stopped rendering at all.
  final studyButton = find.descendant(
    of: find.byType(StudyHomeDeckItemWidget),
    matching: find.text(AppLocalizationsEn().studyHomeStudyAction),
  );

  group('actions', () {
    testWidgets('Study opens the deck entry inside the Study branch', (
      tester,
    ) async {
      final router = await harness.pump(tester);

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
      await harness.pump(
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
      final router = await harness.pump(tester);

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
      final router = await harness.pump(tester);

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
      await harness.pump(
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
      await harness.pump(tester);

      await tester.drag(find.byType(StudyHomeScreen), const Offset(0, -200));
      await tester.pumpAndSettle();

      // The session repository is the one that could have been written to, and
      // it is the harness's — so this asks the object that would know.
      expect(harness.sessions.opened, isEmpty);
    });

    testWidgets('a failure after the first snapshot reaches the error state', (
      tester,
    ) async {
      // **A transition that only exists since the DAO forwards `onError`.**
      // Before, an error on the update bus was swallowed and the tab sat on
      // stale counts indefinitely; now it arrives, and BR-184 wants it on
      // screen with a retry. The other error test fails at *subscribe*, which
      // is a different moment and a different code path.
      await harness.pump(tester);
      expect(find.byType(StudyHomeDeckItemWidget), findsNWidgets(2));

      harness.home.emitError(StateError('update bus failed'));
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
      await harness.pump(
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
      harness.clockNow = StudyHomeHarness.now.add(const Duration(minutes: 7));
      container.read(studyHomeNowProvider.notifier).refresh();
      expect(container.read(studyHomeNowProvider), harness.clockNow);

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
      await harness.pump(
        tester,
        repository: FakeStudyHomeRepository(
          initial: fakeStudyHome(resume: fakeStudyHomeResume()),
        ),
      );

      expect(find.byType(StudyHomeResumeSectionWidget), findsOneWidget);

      // What a finished session looks like from here: the stream re-emits
      // without the resume.
      harness.home.emit(fakeStudyHome());

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
