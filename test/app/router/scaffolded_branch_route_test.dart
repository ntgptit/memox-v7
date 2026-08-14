import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/progress/presentation/screens/progress_placeholder_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';

import '../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../features/study/domain/support/fake_study_repository.dart';
import '../../features/settings/domain/support/fake_app_settings_repository.dart';

/// The two scaffolded branches (AD-19), exercised through the real app root.
///
/// A separate file from `app_router_test.dart` for the same reason
/// `deck_route_test.dart` is: one file per routing concern, each with its own
/// router so navigation performed in one test cannot arrive in the next.
///
/// What AD-19 promises and these tests hold it to: Progress and Settings are
/// real `StatefulShellBranch`es — deep-linkable, tab-selecting, stack-keeping.
///
/// **Settings stopped being presentation-only at M99.23** (UC-12): it reads and
/// writes `app_settings`. The presentation-only claim below is now Progress's
/// alone, and the Settings half of it has been narrowed to what still holds and
/// still matters — visiting the branch opens no study session and writes
/// nothing through the **deck or study** contracts.
void main() {
  final english = AppLocalizationsEn();

  /// The tab label, scoped to the bar — see `app_router_test.dart` for why a
  /// bare `find.text` is ambiguous here.
  Finder tab(String label) => find.descendant(
    of: find.byType(MxNavigationBar),
    matching: find.text(label),
  );

  int selectedTab(WidgetTester tester) => tester
      .widget<MxNavigationBar>(find.byType(MxNavigationBar))
      .selectedIndex;

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    String? initialLocation,
    FakeDeckRepository? repository,
    FakeStudyRepository? studyRepository,
  }) async {
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
          studyRepositoryProvider.overrideWithValue(
            studyRepository ?? FakeStudyRepository(),
          ),
          deckRepositoryProvider.overrideWithValue(
            repository ?? FakeDeckRepository(),
          ),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  testWidgets('tapping Progress opens the placeholder on its own tab', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(tab(english.navigationProgressLabel));
    await tester.pumpAndSettle();

    expect(find.byType(ProgressPlaceholderScreen), findsOneWidget);
    expect(selectedTab(tester), 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping Settings opens the settings screen on its own tab', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(tab(english.navigationSettingsLabel));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(selectedTab(tester), 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a deep link to /progress opens on the Progress tab', (
    tester,
  ) async {
    // The reason Progress has a real path rather than living under `/`:
    // opening Decks first and then jumping would be visible, and the back
    // button would land somewhere the user never chose to be.
    await pumpApp(tester, initialLocation: RoutePaths.progress);

    expect(find.byType(ProgressPlaceholderScreen), findsOneWidget);
    expect(find.byType(DeckListScreen), findsNothing);
    expect(selectedTab(tester), 2);
  });

  testWidgets('a deep link to /settings opens on the Settings tab', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: RoutePaths.settings);

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(DeckListScreen), findsNothing);
    expect(selectedTab(tester), 3);
  });

  testWidgets('goNamed reaches both placeholder routes and moves the tab', (
    tester,
  ) async {
    // Proves the names are actually registered — a path-based test would
    // pass even if `name:` had been left off the routes entirely.
    final router = await pumpApp(tester);

    router.goNamed(RouteNames.progress);
    await tester.pumpAndSettle();
    expect(find.byType(ProgressPlaceholderScreen), findsOneWidget);
    expect(selectedTab(tester), 2);

    router.goNamed(RouteNames.settings);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(selectedTab(tester), 3);
  });

  testWidgets('visiting the placeholders opens no study session and writes '
      'nothing', (tester) async {
    // AD-19's hard boundary: a placeholder is presentation-only. The fake
    // records every write-shaped call the contract has, so all of them
    // staying empty is what "no session, no write" means at this level. The
    // host-database half of the same claim lives in
    // `test/integration/widgets/navigation_widget_test.dart`.
    final study = FakeStudyRepository();
    await pumpApp(tester, studyRepository: study);

    await tester.tap(tab(english.navigationProgressLabel));
    await tester.pumpAndSettle();
    await tester.tap(tab(english.navigationSettingsLabel));
    await tester.pumpAndSettle();
    await tester.tap(tab(english.navigationDecksLabel));
    await tester.pumpAndSettle();

    expect(study.opened, isEmpty);
    expect(study.answers, isEmpty);
    expect(study.ended, isEmpty);
  });

  testWidgets('switching through the placeholders keeps the deck branch '
      'state', (tester) async {
    // Same measurement as the two-branch round trip in `app_router_test.dart`:
    // one subscription for the whole tour means the deck screen stayed
    // mounted while the placeholders were on top.
    final repository = FakeDeckRepository();
    await pumpApp(tester, repository: repository);

    expect(repository.deckListCallCount, 1);

    await tester.tap(tab(english.navigationProgressLabel));
    await tester.pumpAndSettle();
    await tester.tap(tab(english.navigationSettingsLabel));
    await tester.pumpAndSettle();
    await tester.tap(tab(english.navigationDecksLabel));
    await tester.pumpAndSettle();

    expect(repository.deckListCallCount, 1);
    expect(find.byType(DeckListScreen), findsOneWidget);
  });

  testWidgets('re-selecting Progress stays on its initial location', (
    tester,
  ) async {
    // Same shape as the Decks re-selection test: with one route per branch
    // the observable fact is that the re-selection is handled rather than
    // throwing or navigating elsewhere.
    final router = await pumpApp(tester, initialLocation: RoutePaths.progress);

    await tester.tap(tab(english.navigationProgressLabel));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      RoutePaths.progress,
    );
    expect(find.byType(ProgressPlaceholderScreen), findsOneWidget);
    expect(selectedTab(tester), 2);
    expect(tester.takeException(), isNull);
  });
}
