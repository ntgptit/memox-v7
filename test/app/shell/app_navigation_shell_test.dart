import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/app/shell/app_navigation_shell.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';

import '../../features/deck/presentation/support/fake_deck_repository.dart';

import '../../features/study/domain/support/fake_study_home_repository.dart';
import '../../features/study/domain/support/fake_study_repository.dart';
import '../../features/settings/domain/support/fake_app_settings_repository.dart';

/// The chrome, exercised through the real router.
///
/// `AppNavigationShell` cannot be pumped on its own: `StatefulNavigationShell`
/// is created by GoRouter and there is no public way to build one. That is not
/// a gap in the tests — going through the router is what proves the shell is
/// wired to the branches the app actually ships, rather than to a stand-in
/// assembled here that could drift from it silently.
void main() {
  final english = AppLocalizationsEn();

  Future<void> pumpShell(
    WidgetTester tester,
    FakeDeckRepository repository, {
    String initialLocation = RoutePaths.decks,
    Size surface = const Size(393, 852),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = createAppRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(
            FakeAppSettingsRepository(),
          ),
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(repository),
          // The Study branch reads real data since M5.7, so the shell needs a
          // study repository too. The bar is what this test is about, and it
          // has to survive that branch rendering as well as the deck one.
          // The Study branch is Study Home since UC-14, which reads its own
          // contract — a screen with no method that could open a session.
          studyHomeRepositoryProvider.overrideWithValue(
            FakeStudyHomeRepository(),
          ),
          studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
        ],
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: MemoxApp(router: router),
        ),
      ),
    );
    // `pump`, not `pumpAndSettle`: the loading state spins forever and settling
    // would time out on a screen that is behaving correctly.
    await tester.pump();
    await tester.pump();
  }

  List<DeckSummary> manySummaries() => <DeckSummary>[
    for (var i = 0; i < 30; i++)
      fakeSummary(id: 'deck-$i', name: 'Deck number $i'),
  ];

  group('the bar survives every state of the deck branch', () {
    testWidgets('loading', (tester) async {
      await pumpShell(tester, FakeDeckRepository.pending());

      expect(find.byType(MxLoadingState), findsOneWidget);
      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty', (tester) async {
      await pumpShell(tester, FakeDeckRepository());

      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loaded', (tester) async {
      await pumpShell(
        tester,
        FakeDeckRepository.withSummaries(manySummaries()),
      );

      expect(find.byType(DeckTileWidget), findsWidgets);
      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('error', (tester) async {
      await pumpShell(
        tester,
        FakeDeckRepository.failing(const DatabaseFailure(message: 'x')),
      );

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('and on the study branch', (tester) async {
      await pumpShell(
        tester,
        FakeDeckRepository(),
        initialLocation: RoutePaths.study,
      );

      // The branch shows Study Home since UC-14 — the library, not a fixture
      // deck's entry screen. What this test is about is the bar surviving that
      // branch, so it asserts the screen rendered at all rather than which copy
      // it happens to carry.
      expect(
        find.text(english.studyHomeNextTitle.toUpperCase()),
        findsOneWidget,
      );
      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('layout', () {
    testWidgets('the list ends above the bar rather than under it', (
      tester,
    ) async {
      // The concrete promise of putting the bar on the outer `Scaffold`: it
      // removes its own height from the body's constraints, so the scrollable
      // stops where the bar starts. Painting the bar over the content instead
      // would still look fine on a short list and hide the last row on a long
      // one — which is why this uses thirty decks, not three.
      await pumpShell(
        tester,
        FakeDeckRepository.withSummaries(manySummaries()),
      );

      final list = tester.getRect(find.byType(Scrollable).first);
      final bar = tester.getRect(find.byType(MxNavigationBar));

      expect(list.bottom, lessThanOrEqualTo(bar.top));
    });

    testWidgets('scrolling to the end leaves the last row fully visible', (
      tester,
    ) async {
      await pumpShell(
        tester,
        FakeDeckRepository.withSummaries(manySummaries()),
      );

      // **Jump to the measured end, not a fling of a guessed distance.** This
      // was `fling(-3000)`, which reached the bottom only while the list was
      // short enough; the taller cards of M4.10s put the last row past it and
      // the test failed on 4 pixels of content it had simply not scrolled to.
      // A distance that has to be large enough is a distance that silently
      // stops being large enough.
      // **The list's scrollable, named by the view that owns it.** Neither
      // `.first` nor `.last` of the screen's scrollables is the list: the
      // breadcrumb scrolls horizontally and a search field's `EditableText`
      // brings its own, and their order in the tree is not ours to rely on —
      // `Scaffold` lays the body out *before* the app bar, so moving the
      // breadcrumb into the bar moved it from first to last and this test
      // spent its jumps on a breadcrumb (owner review, 2026-08-20).
      final position = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      // **Until the extent stops moving, not once.** `maxScrollExtent` over a
      // lazily built list is an *estimate* from the items laid out so far, and
      // the body became a `CustomScrollView` whose first two slivers shift it:
      // one jump landed 78px short of the true end, which reads exactly like the
      // list failing to reserve room for the floating action. Jumping again once
      // the real items are built is what asks the question the test means.
      var previous = -1.0;
      while (position.maxScrollExtent != previous) {
        previous = position.maxScrollExtent;
        position.jumpTo(previous);
        await tester.pumpAndSettle();
      }

      final bar = tester.getRect(find.byType(MxNavigationBar));
      final lastRow = tester.getRect(find.byType(DeckTileWidget).last);

      expect(lastRow.bottom, lessThanOrEqualTo(bar.top));

      // **And the floating action does not cover it either** (owner review,
      // 2026-08-20). Create floats again, so the guarantee goes back to being
      // measured: an inset only reserves the *end* of the scroll, and the end
      // of the scroll is exactly where a reader looks for the last deck's
      // Study button.
      final action = tester.getRect(find.byType(FloatingActionButton));
      expect(lastRow.bottom, lessThanOrEqualTo(action.top));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the bar keeps its height across a branch switch', (
      tester,
    ) async {
      // Two Scaffolds are involved. If the inner one ever started contributing
      // its own bottom inset, the bar would change height when the branch
      // changed and the whole frame would jump.
      await pumpShell(tester, FakeDeckRepository());
      final onDecks = tester.getSize(find.byType(MxNavigationBar));

      await tester.tap(
        find.descendant(
          of: find.byType(MxNavigationBar),
          matching: find.text(english.navigationStudyLabel),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(MxNavigationBar)), onDecks);
    });

    testWidgets('exactly one shell, and it owns exactly one bar', (
      tester,
    ) async {
      // Guards against the branch screens each growing their own bar, which is
      // the shape the shell exists to prevent.
      await pumpShell(tester, FakeDeckRepository());

      expect(find.byType(AppNavigationShell), findsOneWidget);
      expect(find.byType(MxNavigationBar), findsOneWidget);
    });
  });

  group('responsive', () {
    const compact = Size(360, 640);

    testWidgets('no overflow at 320x568', (tester) async {
      await pumpShell(
        tester,
        FakeDeckRepository.withSummaries(manySummaries()),
        surface: compact,
      );

      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 320x568 with textScaler 2.0', (tester) async {
      await pumpShell(
        tester,
        FakeDeckRepository.withSummaries(manySummaries()),
        surface: compact,
        textScale: 2,
      );

      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the empty state still clears the bar at textScaler 2.0', (
      tester,
    ) async {
      // The centred states are the ones that overflow for a different reason
      // than a list: a column that no longer fits runs off the bottom, and the
      // bar is what it runs into.
      await pumpShell(
        tester,
        FakeDeckRepository(),
        surface: compact,
        textScale: 2,
      );

      final empty = tester.getRect(find.byType(MxEmptyState));
      final bar = tester.getRect(find.byType(MxNavigationBar));

      expect(empty.bottom, lessThanOrEqualTo(bar.top));
      expect(tester.takeException(), isNull);
    });
  });

  group('stream updates reach the branch while it is on screen', () {
    testWidgets('a later emission still updates the list under the bar', (
      tester,
    ) async {
      final controller = StreamController<DeckListSnapshot>();
      addTearDown(controller.close);

      await pumpShell(
        tester,
        FakeDeckRepository(deckList: (_) => controller.stream),
      );

      controller.add(fakeListSnapshot(const <DeckSummary>[]));
      await tester.pump();
      expect(find.byType(MxEmptyState), findsOneWidget);

      controller.add(fakeListSnapshot(manySummaries()));
      await tester.pump();

      expect(find.byType(DeckTileWidget), findsWidgets);
      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
