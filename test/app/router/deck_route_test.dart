// `material`, not `widgets`: the title assertion below reaches for `AppBar`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';

import '../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../features/study/domain/support/fake_study_home_repository.dart';
import '../../features/study/domain/support/fake_study_repository.dart';
import '../../features/settings/domain/support/fake_app_settings_repository.dart';

/// The nested deck route, exercised through the real app root.
///
/// Split from `app_router_test.dart` so neither file outgrows the project's
/// file-size limit. The shared pump helper lives in both because it is short and
/// duplicating four lines beats a third file that exists only to hold them.
void main() {
  final english = AppLocalizationsEn();

  /// The tab label, not the screen title.
  ///
  /// Scoped to the bar because a tab label and a screen title are allowed to
  /// collide — `decksTitle` and `navigationDecksLabel` were both "Decks" until
  /// the Library rename, and a bare `find.text` matched the app bar and the
  /// tab at once, making every tap ambiguous. The scoping keeps these tests
  /// about navigation whether or not the two strings currently differ.
  Finder tab(String label) => find.descendant(
    of: find.byType(MxNavigationBar),
    matching: find.text(label),
  );

  /// Which destination the bar is currently showing as selected.
  int selectedTab(WidgetTester tester) => tester
      .widget<MxNavigationBar>(find.byType(MxNavigationBar))
      .selectedIndex;

  /// Pumps the real root with a router nobody else holds.
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    String? initialLocation,
    FakeDeckRepository? repository,
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
          // The Study branch is Study Home since UC-14, which reads its own
          // contract — a screen with no method that could open a session.
          studyHomeRepositoryProvider.overrideWithValue(
            FakeStudyHomeRepository(),
          ),
          studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
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

  /// The deck list at a particular level.
  ///
  /// `find.byType` no longer separates the two screens — there is only one, and
  /// the level is an argument. So the route tests ask the question they actually
  /// mean: which level is on screen.
  Finder levelFor(String? parentDeckId) => find.byWidgetPredicate(
    (Widget widget) =>
        widget is DeckListScreen && widget.parentDeckId == parentDeckId,
  );

  group('the deck detail route', () {
    /// A repository that can serve one deck, so the nested route has something
    /// to render.
    ///
    /// The root level and the deck level come from the same builder, told apart
    /// by the parent id — the same way the real repository tells them apart.
    FakeDeckRepository servingDeck() => FakeDeckRepository(
      deckList: (String? id) => Stream<DeckListSnapshot>.value(
        id == null
            ? const DeckListSnapshot(
                ancestors: <DeckPathSegment>[],
                parent: null,
                decks: <DeckSummary>[],
                nextDueAt: null,
                nextOverdueTickAt: null,
              )
            : DeckListSnapshot(
                ancestors: const <DeckPathSegment>[],
                parent: fakeRootDeck(id: id, name: 'Japanese N5'),
                decks: const <DeckSummary>[],
                nextDueAt: null,
                nextOverdueTickAt: null,
              ),
      ),
    );

    testWidgets('a deep link to /decks/<id> opens that deck', (tester) async {
      await pumpApp(
        tester,
        initialLocation: '/decks/deck-1',
        repository: servingDeck(),
      );

      expect(levelFor('deck-1'), findsOneWidget);
      // In the app bar: the deck's name is also the breadcrumb's last step now,
      // and what this test is about is that the deep link landed on the deck —
      // which the title is the evidence for.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Japanese N5'),
        ),
        // Twice: the bar's title and the path's last step, which is the bar's
        // subline since the header became one block (owner review,
        // 2026-08-20).
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('it stays inside the Decks branch, bar and all', (
      tester,
    ) async {
      // A child route rather than a top-level one. As a top-level route the deck
      // screen would open with no bottom bar and no branch to go back into.
      await pumpApp(
        tester,
        initialLocation: '/decks/deck-1',
        repository: servingDeck(),
      );

      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(selectedTab(tester), 0);
    });

    testWidgets('goNamed with a path parameter reaches it', (tester) async {
      // By name and by parameter constant, so neither half is a literal that the
      // compiler cannot check against the other.
      final router = await pumpApp(tester, repository: servingDeck());

      router.goNamed(
        RouteNames.deckDetail,
        pathParameters: <String, String>{RoutePathParams.deckId: 'deck-9'},
      );
      await tester.pumpAndSettle();

      expect(levelFor('deck-9'), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/decks/deck-9',
      );
    });

    testWidgets('back returns to the root deck list', (tester) async {
      final router = await pumpApp(tester, repository: servingDeck());

      router.goNamed(
        RouteNames.deckDetail,
        pathParameters: <String, String>{RoutePathParams.deckId: 'deck-1'},
      );
      await tester.pumpAndSettle();
      expect(levelFor('deck-1'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();

      expect(levelFor(null), findsOneWidget);
      expect(levelFor('deck-1'), findsNothing);
    });

    testWidgets('switching to Review and back keeps the deck open', (
      tester,
    ) async {
      // The branch stack, which is what `indexedStack` buys. A plain route set
      // would drop the pushed deck screen on the way out.
      final router = await pumpApp(tester, repository: servingDeck());
      router.goNamed(
        RouteNames.deckDetail,
        pathParameters: <String, String>{RoutePathParams.deckId: 'deck-1'},
      );
      await tester.pumpAndSettle();

      await tester.tap(tab(english.navigationStudyLabel));
      await tester.pumpAndSettle();
      await tester.tap(tab(english.navigationDecksLabel));
      await tester.pumpAndSettle();

      expect(levelFor('deck-1'), findsOneWidget);
    });

    testWidgets('a deck that no longer exists shows the not-found state', (
      tester,
    ) async {
      // UC-03 E1 through the route: a stale deep link must not crash or land on
      // a blank screen.
      await pumpApp(
        tester,
        initialLocation: '/decks/gone',
        repository: FakeDeckRepository.missingDeck(),
      );

      expect(find.text(english.deckDetailNotFoundTitle), findsOneWidget);
      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
