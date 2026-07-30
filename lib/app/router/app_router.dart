import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/deck/presentation/deck_detail_screen.dart';
import '../../features/deck/presentation/root_deck_list_screen.dart';
import '../../features/review/presentation/review_placeholder_screen.dart';
import '../fallback/route_not_found_screen.dart';
import '../shell/app_navigation_shell.dart';
import 'route_names.dart';
import 'route_paths.dart';

/// Composition of the route table, and nothing else.
///
/// No screen is built here beyond naming the widget that renders it: a layout
/// written inside a route definition cannot be pumped on its own, so the first
/// test of that screen has to go through the router to reach it. The shell is
/// the one exception the structure forces — `StatefulShellRoute` hands the
/// builder a `StatefulNavigationShell` that only it can create — and even
/// there the builder does nothing but pass it to [AppNavigationShell].

/// The router the running app uses.
///
/// Built once, at first access, and never inside `build()`. A `GoRouter` created
/// during a rebuild is a new router with a new navigation stack: back history is
/// lost and the current route is re-entered, which shows up as a screen that
/// flickers back to the start whenever anything above it rebuilds.
final GoRouter appRouter = createAppRouter();

/// A fresh router, for tests that need one nobody else is holding.
///
/// Every test gets its own so navigation performed in one cannot arrive in the
/// next. [initialLocation] lets a test start at a location that does not exist,
/// which is the only way to reach [RouteNotFoundScreen] without asking the
/// production code to accept a bad path.
///
/// **Two branches, one shell.** `StatefulShellRoute.indexedStack` keeps a
/// separate `Navigator` per branch, so each tab keeps its own stack and its own
/// scroll position while the other is on screen. A plain set of top-level
/// routes would rebuild the destination from scratch on every tab switch, which
/// is the "why did my place in the list disappear" bug.
GoRouter createAppRouter({String initialLocation = RoutePaths.decks}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: appRedirect,
    errorBuilder: (context, state) => const RouteNotFoundScreen(),
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppNavigationShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.decks,
                name: RouteNames.decks,
                builder: (context, state) => const RootDeckListScreen(),
                routes: <RouteBase>[
                  // A child route, so a deck screen pushes onto the Decks
                  // branch: the bottom bar stays, Back returns to the list, and
                  // switching to Review and back finds the deck still open.
                  GoRoute(
                    path: RoutePaths.deckDetailRelative,
                    name: RouteNames.deckDetail,
                    builder: (context, state) => DeckDetailScreen(
                      // Non-null by construction: the path segment is required,
                      // so a match cannot occur without it. `!` rather than a
                      // fallback because a fallback would invent a deck id and
                      // open somebody else's deck.
                      deckId: state.pathParameters[RoutePathParams.deckId]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.review,
                name: RouteNames.review,
                builder: (context, state) => const ReviewPlaceholderScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Where an auth guard will go (AD-03), and nothing until it does.
///
/// Returning `null` means "navigate as asked". The hook exists now so that
/// adding auth later is a change inside one function rather than a change to
/// every route — but it is deliberately empty: a guard written against an
/// authentication system that does not exist yet would be guessing at the shape
/// of a session, and the MVP has one local profile and no login (AD-03).
///
/// Nothing here may log [state]. A location can carry identifiers, and once deep
/// links exist it can carry card content; navigation logging is how private data
/// reaches a log file nobody thought of as private.
String? appRedirect(BuildContext context, GoRouterState state) {
  return null;
}
