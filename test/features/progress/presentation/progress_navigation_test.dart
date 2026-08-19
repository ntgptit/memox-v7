import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';
import 'package:memox/features/progress/domain/models/progress_path_segment_model.dart';
import 'package:memox/features/progress/presentation/screens/progress_deck_screen.dart';
import 'package:memox/features/progress/presentation/widgets/items/progress_deck_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';

/// Drilling into the tree through the **real router and shell**, because that is
/// the only place the answers live: which branch a level pushes onto, what Back
/// does at depth, and whether a deep link resolves to the same place.
void main() {
  final english = AppLocalizationsEn();

  /// A repository serving a two-level tree: the library holds `root`, `root`
  /// holds `branch`, and `branch` holds nothing.
  FakeProgressRepository tree() => FakeProgressRepository(
    // **The overview has to answer too, now that `/progress` is one screen.**
    // The library level renders under the overview's three sections, so a fake
    // that answers only the level read leaves the tab stuck on its spinner and
    // every assertion about *where* navigation landed finds nothing. That is
    // the composed screen's real contract, not a test detail.
    initial: progressOverviewFixture(
      totals: const <int>[1, 0, 2, 0, 3, 0, 4],
      streakDays: 1,
    ),
    activity: (String? deckId) =>
        Stream<DeckActivitySnapshot>.value(switch (deckId) {
          null => activitySnapshot(
            decks: <DeckActivity>[
              deckActivity(
                deckId: 'root',
                name: 'Spanish',
                last7Days: activityMetrics(activeCards: 9, activeDays: 3),
              ),
            ],
            scopeLast7Days: activityMetrics(activeCards: 9, activeDays: 3),
          ),
          'root' => activitySnapshot(
            decks: <DeckActivity>[
              deckActivity(
                deckId: 'branch',
                name: 'Grammar',
                path: const <ProgressPathSegment>[
                  ProgressPathSegment(id: 'root', name: 'Spanish'),
                ],
                last7Days: activityMetrics(activeCards: 9, activeDays: 3),
              ),
            ],
            scopeDeckId: 'root',
            scopeName: 'Spanish',
            scopeLast7Days: activityMetrics(activeCards: 9, activeDays: 3),
          ),
          _ => activitySnapshot(
            decks: const <DeckActivity>[],
            scopeDeckId: 'branch',
            scopeName: 'Grammar',
            scopePath: const <ProgressPathSegment>[
              ProgressPathSegment(id: 'root', name: 'Spanish'),
            ],
            scopeLast7Days: activityMetrics(activeCards: 9, activeDays: 3),
          ),
        }),
  );

  /// The level currently mounted for [deckId].
  ///
  /// **Screens, not the URL.** `go_router` keeps `currentConfiguration.uri` at
  /// the base location for an *imperative* push inside a shell branch, so the
  /// path is not the observable here — which level is on screen is. Deep links
  /// are the exception and are asserted by path below, because there the URL is
  /// the input rather than the result.
  Finder levelFor(String? deckId) => find.byWidgetPredicate(
    (Widget widget) => widget is ProgressDeckScreen && widget.deckId == deckId,
  );

  testWidgets('the Progress tab opens the library level', (tester) async {
    final router = await pumpProgressApp(tester, repository: tree());

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      RoutePaths.progress,
    );
    expect(levelFor(null), findsOneWidget);
    // Two: the app-bar title and the tab label, which say the same word on
    // purpose — the tab and its screen have to read as one place.
    expect(find.text(english.progressTitle), findsNWidgets(2));
    expect(find.byType(MxNavigationBar), findsOneWidget);
  });

  testWidgets('tapping a row opens that deck inside the Progress branch', (
    tester,
  ) async {
    await pumpProgressApp(tester, repository: tree());

    // `dragUntilVisible`, not `ensureVisible`: the rows live in a `SliverList`
    // below the overview header, so an off-screen row has no element yet and
    // `ensureVisible` throws `Bad state: No element` before it can scroll.
    await tester.dragUntilVisible(
      find.byType(ProgressDeckRowWidget),
      find.byType(CustomScrollView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ProgressDeckRowWidget).first);
    await tester.pumpAndSettle();

    expect(levelFor('root'), findsOneWidget);
    expect(find.text('Spanish'), findsWidgets);
    // The bar stays: drilling is a push inside the branch, not a jump out of it.
    expect(find.byType(MxNavigationBar), findsOneWidget);
  });

  testWidgets('Back from level three lands on level two, not the library', (
    tester,
  ) async {
    // The failure `pushNamed` exists to prevent: every level is the same route
    // with a different id, so `go` would replace the location and Back would
    // skip straight past the level the user came from.
    final router = await pumpProgressApp(tester, repository: tree());

    // `dragUntilVisible`, not `ensureVisible`: the rows live in a `SliverList`
    // below the overview header, so an off-screen row has no element yet and
    // `ensureVisible` throws `Bad state: No element` before it can scroll.
    await tester.dragUntilVisible(
      find.byType(ProgressDeckRowWidget),
      find.byType(CustomScrollView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ProgressDeckRowWidget).first);
    await tester.pumpAndSettle();
    // `dragUntilVisible`, not `ensureVisible`: the rows live in a `SliverList`
    // below the overview header, so an off-screen row has no element yet and
    // `ensureVisible` throws `Bad state: No element` before it can scroll.
    await tester.dragUntilVisible(
      find.byType(ProgressDeckRowWidget),
      find.byType(CustomScrollView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ProgressDeckRowWidget).first);
    await tester.pumpAndSettle();

    expect(levelFor('branch'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    expect(levelFor('root'), findsOneWidget);
    expect(levelFor('branch'), findsNothing);
  });

  testWidgets('a deep link to one deck opens it on the Progress tab', (
    tester,
  ) async {
    final router = await pumpProgressApp(
      tester,
      repository: tree(),
      initialLocation: '/progress/branch',
    );

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/progress/branch',
    );
    expect(levelFor('branch'), findsOneWidget);
    expect(find.text('Grammar'), findsWidgets);
  });

  testWidgets('a level whose deck is gone offers the way back to the library', (
    tester,
  ) async {
    final router = await pumpProgressApp(
      tester,
      repository: FakeProgressRepository(
        // **The overview has to answer too, now that `/progress` is one screen.**
        // The library level renders under the overview's three sections, so a fake
        // that answers only the level read leaves the tab stuck on its spinner and
        // every assertion about *where* navigation landed finds nothing. That is
        // the composed screen's real contract, not a test detail.
        initial: progressOverviewFixture(
          totals: const <int>[1, 0, 2, 0, 3, 0, 4],
          streakDays: 1,
        ),
        activity: (String? deckId) => deckId == null
            ? Stream<DeckActivitySnapshot>.value(
                activitySnapshot(decks: const <DeckActivity>[]),
              )
            : Stream<DeckActivitySnapshot>.error(
                const NotFoundFailure(message: 'gone'),
              ),
      ),
      initialLocation: '/progress/ghost',
    );

    expect(find.text(english.progressDeckMissingTitle), findsOneWidget);

    await tester.tap(find.text(english.progressDeckMissingBackAction));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      RoutePaths.progress,
    );
  });
}
