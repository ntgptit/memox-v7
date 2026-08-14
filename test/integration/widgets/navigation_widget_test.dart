import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/fallback/route_not_found_screen.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_placeholder_screen.dart';

import '../../helpers/app_harness/host_widget_app.dart';
import '../../helpers/fixtures/study_fixtures.dart';

/// `HOST-WIDGET` for the navigation scenarios — IT-NAV-001, IT-NAV-003,
/// IT-NAV-005 and IT-NAV-011.
///
/// **These were classed `UI` and therefore ran only on an emulator, and not one
/// of them needs a device.** What each asserts is where GoRouter put the user,
/// and GoRouter is a Dart object: it resolves the same route table on a host as
/// on a phone. The only navigation fact a phone knows and a host does not is how
/// the *operating system* hands a link or a back gesture over, and that is what
/// `IT-PLAT-004` and `IT-PLAT-005` are for.
void main() {
  testWidgets('IT-NAV-001 · a cold start lands on the deck list', (
    tester,
  ) async {
    await runHostApp(tester, now: fixtureNow, (app) async {
      expect(app.router.state.uri.toString(), RoutePaths.decks);
      expect(
        tester.takeException(),
        isNull,
        reason:
            'a first frame that throws is the failure a user reports as '
            '"the app does not open"',
      );
    });
  });

  testWidgets('IT-NAV-005 · an unknown route lands somewhere with a way out', (
    tester,
  ) async {
    // The half of the scenario that is the router's: the 404 page and its
    // recovery. An OS-originated deep link is `IT-PLAT-004`, and it is the only
    // part of this that a device can show and a host cannot.
    await runHostApp(
      tester,
      now: fixtureNow,
      initialLocation: '/no-such-place',
      (app) async {
        expect(tester.takeException(), isNull);
        // Asserted on what is on screen, not on `router.state`: with no route
        // matched the match list is empty and reading the location throws
        // `Bad state: No element`. Which is itself the finding — a 404 is the
        // one location the router cannot describe, so any code that reaches for
        // `router.state` to decide what to show breaks exactly here.
        expect(find.byType(RouteNotFoundScreen), findsOneWidget);
        // Not "some widget is on screen": a 404 that silently redirected to the
        // deck list would satisfy that and would hide a broken link forever.
        expect(find.byType(DeckListScreen), findsNothing);
        // And it has the way out the scenario is named for.
        expect(find.text('Go home'), findsOneWidget);
      },
    );
  });

  testWidgets('IT-NAV-003 · opening a deck and going back leaves the stack '
      'where it started', (tester) async {
    final db = createHostDatabase();
    final fixture = await deckWithCards(db, cardCount: 2);

    await runHostApp(tester, database: db, now: fixtureNow, (app) async {
      expect(app.router.state.uri.toString(), RoutePaths.decks);

      unawaited(app.router.push('/decks/${fixture.rootId}'));
      await settleHostApp(tester);
      expect(app.router.state.uri.toString(), isNot(RoutePaths.decks));

      // `pop`, not a second `go`: the scenario is about the back affordance,
      // and a `go` would rewrite the stack rather than walk it.
      app.router.pop();
      await settleHostApp(tester);

      expect(app.router.state.uri.toString(), RoutePaths.decks);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('IT-NAV-011 · the Progress screen and the Settings placeholder '
      'render without a session or a database write', (tester) async {
    // The strong half of AD-19's boundary, against the **real** wiring: the
    // fake-repository test in `test/app/router/` proves the two branches call
    // nothing on the study contract, but only a real database can prove no
    // binding underneath them writes on its own. That got sharper at M99.23:
    // Progress now runs a real aggregate query against this database on entry,
    // so "opening the tab changes nothing" (BR-190) is a claim about a screen
    // that genuinely reads. Every table is counted rather than the two obvious
    // ones — the failure this guards against is precisely a write nobody
    // expected.
    final db = createHostDatabase();

    Future<Map<String, int>> rowCounts() async => <String, int>{
      for (final table in db.allTables)
        table.actualTableName: (await db.select(table).get()).length,
    };

    await runHostApp(tester, database: db, now: fixtureNow, (app) async {
      final before = await rowCounts();

      // `go`, not `push`: a tab switch replaces the visible branch, exactly
      // what tapping the destination does — pushing a branch root onto another
      // branch's stack is not a navigation the shell ever performs.
      app.router.go(RoutePaths.progress);
      await settleHostApp(tester);
      expect(app.router.state.uri.toString(), RoutePaths.progress);
      expect(find.byType(ProgressScreen), findsOneWidget);

      app.router.go(RoutePaths.settings);
      await settleHostApp(tester);
      expect(app.router.state.uri.toString(), RoutePaths.settings);
      expect(find.byType(SettingsPlaceholderScreen), findsOneWidget);

      app.router.go(RoutePaths.decks);
      await settleHostApp(tester);

      expect(await rowCounts(), before);
      expect(tester.takeException(), isNull);
    });
  });
}
