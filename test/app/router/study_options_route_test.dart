import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../features/settings/domain/support/fake_app_settings_repository.dart';
import '../../features/study/domain/support/fake_study_home_repository.dart';
import '../../features/study/domain/support/fake_study_repository.dart';

/// The study options route (UC-15, BR-147, BR-148): its two mounts, its URL,
/// and the branch each one lands in.
///
/// **The screen had no location at all until this route existed** (A8 P2-15).
/// `StudyEntryScreen` pushed it with a `MaterialPageRoute` on the branch
/// navigator, so `GoRouterState` went on naming the entry screen for as long as
/// the options were the thing on screen, and nothing deep-linked into them.
/// The rendered chrome is unchanged — it was inside the shell before and it is
/// inside the shell now — so what these tests pin is the half that moved: a
/// location, in the branch the push came from.
///
/// **Two mounts rather than one, and that is the assertion with teeth.** The
/// entry screen is reached from two branches (`deckStudy` under Library,
/// `studyDeck` under Study), and `StatefulNavigationShell` takes its index from
/// the branch that owns the matched route. A single options route would
/// therefore move the bottom bar's selected tab whenever it was opened from the
/// other branch, and Back would return into a branch the user never chose. The
/// `selectedTab` expectations below are what would catch that.
void main() {
  final english = AppLocalizationsEn();

  /// The tune action in the study entry's app bar, matched on its accessible
  /// name rather than on the glyph — the label is the promise that has to keep
  /// pointing at this screen.
  final optionsAction = find.byWidgetPredicate(
    (widget) =>
        widget is MxIconButton &&
        widget.semanticLabel == english.studyOptionsTitle,
  );

  int selectedTab(WidgetTester tester) => tester
      .widget<MxNavigationBar>(find.byType(MxNavigationBar))
      .selectedIndex;

  Future<GoRouter> pumpAt(WidgetTester tester, String location) async {
    final router = createAppRouter(initialLocation: location);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          appSettingsRepositoryProvider.overrideWithValue(
            FakeAppSettingsRepository(),
          ),
          // The Library branch sits under the entry route, so its deck list
          // builds and reads this contract even when the test never looks at
          // it.
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          studyHomeRepositoryProvider.overrideWithValue(
            FakeStudyHomeRepository(),
          ),
          studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  /// The location of the route on top, which is where a pushed match records
  /// itself. `uri` keeps the base location through a push — the same split
  /// `card_import_route_test.dart` reads.
  String topLocation(GoRouter router) =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;

  group('inside the Library branch', () {
    testWidgets('the tune action gives the options a URL under the deck', (
      tester,
    ) async {
      final router = await pumpAt(tester, '/decks/deck-1/study');
      expect(find.byType(StudyEntryScreen), findsOneWidget);
      expect(selectedTab(tester), 0);

      await tester.tap(optionsAction);
      await tester.pumpAndSettle();

      expect(find.byType(StudyOptionsScreen), findsOneWidget);
      expect(topLocation(router), '/decks/deck-1/study/options');
      // The point of the second mount: the push stayed in the branch it came
      // from, so the bar still says Library.
      expect(selectedTab(tester), 0);
      expect(find.byType(MxNavigationBar), findsOneWidget);
    });

    testWidgets('Back returns to the entry screen it was opened from', (
      tester,
    ) async {
      final router = await pumpAt(tester, '/decks/deck-1/study');

      await tester.tap(optionsAction);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(StudyOptionsScreen), findsNothing);
      expect(find.byType(StudyEntryScreen), findsOneWidget);
      expect(topLocation(router), '/decks/deck-1/study');
      expect(selectedTab(tester), 0);
    });

    testWidgets('a deep link opens the options directly', (tester) async {
      // What the imperative push could not do at all: arrive here from
      // outside. The entry screen is underneath, so Back has somewhere to go.
      await pumpAt(tester, '/decks/deck-1/study/options');

      expect(find.byType(StudyOptionsScreen), findsOneWidget);
    });
  });

  group('inside the Study branch', () {
    testWidgets('the tune action gives the options a URL under /study', (
      tester,
    ) async {
      final router = await pumpAt(tester, '/study/deck-1');
      expect(find.byType(StudyEntryScreen), findsOneWidget);
      expect(selectedTab(tester), 1);

      await tester.tap(optionsAction);
      await tester.pumpAndSettle();

      expect(find.byType(StudyOptionsScreen), findsOneWidget);
      expect(topLocation(router), '/study/deck-1/options');
      expect(selectedTab(tester), 1);
    });

    testWidgets('Back returns to the entry screen it was opened from', (
      tester,
    ) async {
      final router = await pumpAt(tester, '/study/deck-1');

      await tester.tap(optionsAction);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(StudyOptionsScreen), findsNothing);
      expect(find.byType(StudyEntryScreen), findsOneWidget);
      expect(topLocation(router), '/study/deck-1');
      expect(selectedTab(tester), 1);
    });

    testWidgets('a deep link opens the options directly', (tester) async {
      await pumpAt(tester, '/study/deck-1/options');

      expect(find.byType(StudyOptionsScreen), findsOneWidget);
    });
  });

  testWidgets('both names are registered and resolve to their own branch', (
    tester,
  ) async {
    // By name rather than by path, because a name is what every call site
    // speaks: a path-based check would pass with `name:` left off the route.
    final router = await pumpAt(tester, '/decks/deck-1/study');

    router.goNamed(
      RouteNames.studyDeckOptions,
      pathParameters: <String, String>{RoutePathParams.deckId: 'deck-1'},
    );
    await tester.pumpAndSettle();

    expect(find.byType(StudyOptionsScreen), findsOneWidget);
    expect(selectedTab(tester), 1);

    router.goNamed(
      RouteNames.deckStudyOptions,
      pathParameters: <String, String>{RoutePathParams.deckId: 'deck-1'},
    );
    await tester.pumpAndSettle();

    expect(find.byType(StudyOptionsScreen), findsOneWidget);
    expect(selectedTab(tester), 0);
    expect(tester.takeException(), isNull);
  });
}
