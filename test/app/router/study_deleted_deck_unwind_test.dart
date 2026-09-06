import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../features/settings/domain/support/fake_app_settings_repository.dart';
import '../../features/study/domain/support/fake_study_home_repository.dart';
import '../../features/study/domain/support/fake_study_repository.dart';

/// Deleting the deck a Study Entry is scoped to must take the screen with it.
///
/// **Through the real router, because the defect is a routing one.** The screen
/// is inside `StatefulShellRoute.indexedStack`, which keeps every branch mounted
/// behind the others — that is the whole reason the stale route could survive.
/// A test that pumped `StudyEntryScreen` on its own would have no branch, no
/// shell and nothing to unwind, and would agree with the broken code.
///
/// What was broken, in two halves:
///
/// - `watchDeckContext` filtered its `null` — the one emission that says the
///   deck is gone was the one it refused to carry, so the screen kept the last
///   good name for as long as the branch stayed mounted, which is forever;
/// - `studyEntryCounts` resolved `:deckId` to a root without excluding
///   tombstones, so a deleted sub-deck went on reporting the counts of the rest
///   of its tree — a stale title over live numbers belonging to other decks.
void main() {
  final AppLocalizationsEn english = AppLocalizationsEn();

  /// The entry screen's title, and **only** the entry screen's.
  ///
  /// The two fakes are independent: Study Home lists `root-a` as 'Everyday
  /// Korean' from its own fixture, and the entry titles itself from the study
  /// repository. Giving them different names is what makes `findsNothing`
  /// mean 'the entry is gone' rather than 'the home row is gone too' — with
  /// one name the assertion passed for the wrong reason on a screen that had
  /// correctly unwound, and would have failed on one that had not.
  const String entryTitle = 'Tiếng Hàn hằng ngày';

  /// The whole app on the real router, opened on the Study tab.
  Future<FakeStudyRepository> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = createAppRouter(initialLocation: RoutePaths.study);
    addTearDown(router.dispose);

    final repository = FakeStudyRepository()..deckName = entryTitle;
    addTearDown(repository.deckContextChanges.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(
            FakeAppSettingsRepository(),
          ),
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          studyHomeRepositoryProvider.overrideWithValue(
            FakeStudyHomeRepository(),
          ),
          studyRepositoryProvider.overrideWithValue(repository),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    return repository;
  }

  /// Opens `root-a` from Study Home the way a user does — by pressing its row's
  /// own action, not by driving the router.
  Future<void> openDeck(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(RegExp('Study Everyday Korean')));
    await tester.pumpAndSettle();
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(MxNavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a deck deleted under the open Study Entry unwinds the route', (
    tester,
  ) async {
    final repository = await pumpApp(tester);
    await openDeck(tester);

    expect(find.byType(StudyEntryScreen), findsOneWidget);
    expect(find.text(entryTitle), findsWidgets);

    // The deletion, arriving the way it does in the app: from somewhere else
    // entirely, as a `null` on the watched read.
    repository.deleteDeck();
    await tester.pumpAndSettle();

    expect(find.byType(StudyEntryScreen), findsNothing);
    expect(find.byType(StudyHomeScreen), findsOneWidget);
    // Not merely "the screen left" — the deck's name must be gone with it. The
    // stale title is what a user would have seen, so it is what the test looks
    // for.
    expect(find.text(entryTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the branch is still mounted, so the unwind waits for it', (
    tester,
  ) async {
    // **The scenario the shell makes possible, and the one a naive fix breaks.**
    // Study/Deck A is deleted while the user is standing in Library. The screen
    // is still mounted — `indexedStack` keeps it — and a `goNamed` fired the
    // moment the stream emits would drag the user out of the tab they are in,
    // mid-gesture, to watch a screen they cannot see leave.
    final repository = await pumpApp(tester);
    await openDeck(tester);
    expect(find.byType(StudyEntryScreen), findsOneWidget);

    await tapTab(tester, english.navigationDecksLabel);
    expect(find.byType(StudyHomeScreen), findsNothing);

    repository.deleteDeck();
    await tester.pumpAndSettle();

    // Still in Library. Nothing moved the user.
    expect(
      find.byType(StudyHomeScreen),
      findsNothing,
      reason: 'the deletion must not switch branches under the user',
    );
    expect(tester.takeException(), isNull);

    // Coming back is when it unwinds.
    await tapTab(tester, english.navigationStudyLabel);

    expect(find.byType(StudyEntryScreen), findsNothing);
    expect(find.byType(StudyHomeScreen), findsOneWidget);
    expect(find.text(entryTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('and it lands there once, not repeatedly', (tester) async {
    final repository = await pumpApp(tester);
    await openDeck(tester);

    repository.deleteDeck();
    await tester.pumpAndSettle();
    // A sticky `null`: the stream keeps reporting the deck is gone, and Study
    // Home is itself deck-scoped-free, so a second unwind would be a navigation
    // to a route the app is already on — harmless in this test and a loop in a
    // shell with a redirect. Pumping again is what would surface it.
    await tester.pumpAndSettle();

    expect(find.byType(StudyHomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed read is not a deletion either', (tester) async {
    // **The distinction the screen is switched on, tested.** `AsyncError`
    // keeps whatever value it had, so a check written `hasValue && value ==
    // null` — or one that treated "not data" as absence — would send the user
    // away from a database hiccup they could have retried, and take the deck
    // they were studying with it. Only `AsyncData(null)` means deleted.
    final repository = await pumpApp(tester);
    await openDeck(tester);

    repository.deckContextChanges.addError(
      const DatabaseFailure(message: 'read failed'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StudyEntryScreen), findsOneWidget);
    expect(find.byType(StudyHomeScreen), findsNothing);
  });

  testWidgets('a rename is still not a deletion', (tester) async {
    // The guard on the guard: the same stream carries both, and a screen that
    // read any change as absence would leave on every rename.
    final repository = await pumpApp(tester);
    await openDeck(tester);

    repository.renameDeck('root-a', 'Bộ thẻ đã đổi tên');
    await tester.pumpAndSettle();

    expect(find.byType(StudyEntryScreen), findsOneWidget);
    expect(find.text('Bộ thẻ đã đổi tên'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
