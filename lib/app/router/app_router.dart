import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/card/presentation/providers/card_use_case_provider.dart';
import '../../features/card/presentation/screens/card_editor_screen.dart';
import '../../features/card/presentation/screens/card_import_screen.dart';
import '../../features/card/presentation/screens/card_list_screen.dart';
import '../../features/deck/presentation/screens/deck_list_screen.dart';
import '../../features/deck/presentation/screens/starter_library_screen.dart';
import '../../features/progress/presentation/screens/progress_deck_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/study/presentation/screens/study_entry_screen.dart';
import '../../features/study/presentation/screens/study_home_screen.dart';
import '../fallback/route_not_found_screen.dart';
import '../shell/app_navigation_shell.dart';
import '../../core/navigation/route_names.dart';
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
/// **Four branches, one shell.** `StatefulShellRoute.indexedStack` keeps a
/// separate `Navigator` per branch, so each tab keeps its own stack and its own
/// scroll position while another is on screen. A plain set of top-level
/// routes would rebuild the destination from scratch on every tab switch, which
/// before the content is. Settings was one until M99.23, and swapping its
/// branch ahead of its feature (AD-19): it holds a single presentation-only
/// deep-link contract and the tab order before the content existed; Progress has
/// is the "why did my place in the list disappear" bug. Progress and Settings
/// is the "why did my place in the list disappear" bug. Progress is still a
/// placeholder route, so the deep-link contract and the tab order are settled
/// screen for the real one touched nothing in this file but the widget name.
/// since been filled in by UC-12 and Settings is still a placeholder.
/// were both branches ahead of their features (AD-19), which is what settled the
GoRouter createAppRouter({String initialLocation = RoutePaths.decks}) {
  // Declared so the import wizard can mount on the root navigator, above
  // the shell. Created per call: a shared GlobalKey across two routers (as
  // tests build them) would be one key in two trees.
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
                // No `parentDeckId`: the root level. The same screen the
                // child route builds — a deck list is a deck list, and the
                // depth is an argument rather than a different widget.
                builder: (context, state) => const DeckListScreen(),
                routes: <RouteBase>[
                  // The starter catalog, a sibling of the deck detail so an
                  // empty library can offer content without leaving the
                  // branch (UC-01).
                  GoRoute(
                    path: RoutePaths.starterLibraryRelative,
                    name: RouteNames.starterLibrary,
                    builder: (context, state) => const StarterLibraryScreen(),
                  ),
                  // A child route, so a deck screen pushes onto the Decks
                  // branch: the bottom bar stays, Back returns to the list, and
                  // switching to Review and back finds the deck still open.
                  GoRoute(
                    path: RoutePaths.deckDetailRelative,
                    name: RouteNames.deckDetail,
                    // A card-type deck holds no sub-decks, so its detail level
                    // forwards straight into its card list (BR-63, W1).
                    redirect: _cardDeckRedirect,
                    // `pathParameters` is a non-nullable map in go_router and
                    // the segment is required by the pattern, so a match cannot
                    // occur without it. No fallback: inventing a deck id would
                    // open somebody else's deck rather than fail.
                    builder: (context, state) => DeckListScreen(
                      parentDeckId:
                          state.pathParameters[RoutePathParams.deckId],
                    ),
                    routes: <RouteBase>[
                      // Studying one deck, nested so it pushes onto the Decks
                      // branch: Back returns to the deck the session started
                      // from, and the bottom bar stays. The Study *tab* is a
                      // different thing — it has no deck of its own.
                      GoRoute(
                        path: RoutePaths.deckStudyRelative,
                        name: RouteNames.deckStudy,
                        builder: (context, state) => StudyEntryScreen(
                          deckId: state.pathParameters[RoutePathParams.deckId]!,
                        ),
                      ),
                      // The card list of a card-type deck, nested so its URL is
                      // `/decks/<id>/cards` and it stays inside the Decks branch.
                      // A deck screen sends the user here (BR-63); the card
                      // feature owns the screen and the deck feature never
                      // imports it (AD-13).
                      GoRoute(
                        path: RoutePaths.cardListRelative,
                        name: RouteNames.cardList,
                        builder: (context, state) => CardListScreen(
                          deckId: state.pathParameters[RoutePathParams.deckId]!,
                        ),
                        routes: <RouteBase>[
                          // The editor, two routes onto one screen: `new`
                          // creates, `:cardId/edit` edits. Separate names
                          // because GoRouter requires each to be unique; the
                          // screen branches on whether `cardId` is present.
                          GoRoute(
                            path: RoutePaths.cardCreateRelative,
                            name: RouteNames.cardEditor,
                            builder: (context, state) => CardEditorScreen(
                              deckId:
                                  state.pathParameters[RoutePathParams.deckId]!,
                            ),
                          ),
                          // The import wizard (UC-10): a sibling of the
                          // editor under the card list, so Back and the
                          // post-import "View cards" both land on the list
                          // whose Drift stream already shows the new rows.
                          GoRoute(
                            path: RoutePaths.cardImportRelative,
                            name: RouteNames.cardImport,
                            // On the root navigator (M4.12 I1): the wizard is
                            // a full-screen task, so it covers the shell and
                            // its bottom bar instead of rendering inside a
                            // branch. The URL keeps its nested shape.
                            parentNavigatorKey: rootNavigatorKey,
                            builder: (context, state) => CardImportScreen(
                              deckId:
                                  state.pathParameters[RoutePathParams.deckId]!,
                            ),
                          ),
                          GoRoute(
                            path: RoutePaths.cardEditRelative,
                            name: RouteNames.cardEditorEdit,
                            builder: (context, state) => CardEditorScreen(
                              deckId:
                                  state.pathParameters[RoutePathParams.deckId]!,
                              cardId:
                                  state.pathParameters[RoutePathParams.cardId],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.study,
                name: RouteNames.study,
                // The tab's own screen at last (UC-14). It stood on a fixture
                // deck id since M5.7 — a constant naming a row the seeder
                // happened to write — so the Study tab showed one hard-coded
                // deck in production and nothing at all in a database that
                // never had it. Study Home reads the real library.
                builder: (context, state) => const StudyHomeScreen(),
                routes: <RouteBase>[
                  // The deck the user picked, pushed onto the Study branch so
                  // Back returns to the list that offered it and the bottom bar
                  // stays. The same screen `deckStudy` builds — a study entry is
                  // a study entry, and only the branch differs.
                  GoRoute(
                    path: RoutePaths.studyDeckRelative,
                    name: RouteNames.studyDeck,
                    // `pathParameters` is non-nullable in go_router and the
                    // segment is required by the pattern, so a match cannot
                    // occur without it.
                    builder: (context, state) => StudyEntryScreen(
                      deckId: state.pathParameters[RoutePathParams.deckId]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          //
          // Progress is still scaffolded (AD-19): one route, and the screen is
          // Progress, at two levels (UC-12, UC-13). `/progress` is the one
          // The branch around it did not move: same path, same name, same
          // `/progress/:deckId` is one deck's level, nested so drilling in
          // both features together cost this one `builder` plus one child route.
          // header, then the range selector, the totals and the deck rows.
          // index. That is what AD-19 scaffolded the branch early to buy, and
          // level above, and switching tabs and back finds the deck still open.
          // no repository, open no session and write nothing.
          // presentation-only — entering, leaving or switching to it must read
          // pushes onto this branch — the bottom bar stays, Back returns to the
          // screen the owner settled on: the overview's three sections as a
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.progress,
                name: RouteNames.progress,
                // No `deckId`: the library level, with the overview on top.
                builder: (context, state) => const ProgressScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: RoutePaths.progressDeckRelative,
                    name: RouteNames.progressDeck,
                    // `pathParameters` is non-nullable in go_router and the
                    // segment is required by the pattern, so a match cannot
                    // occur without it. No fallback: inventing a deck id would
                    // open somebody else's deck rather than fail.
                    //
                    // The overview is deliberately absent here: streak, today
                    // and the seven-day chart are properties of the whole
                    // library, so repeating them under one deck would answer a
                    // question nobody asked at this level.
                    builder: (context, state) => ProgressDeckScreen(
                      deckId: state.pathParameters[RoutePathParams.deckId],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Settings left that state at M99.23 (UC-12). The path, the name and
          // The one branch still scaffolded ahead of its feature (AD-19). Its
          // must read no repository and write nothing.
          // of it, which is what AD-19 was betting on.
          // screen is presentation-only: entering, leaving or switching to it
          // the branch order are unchanged — replacing the screen was the whole
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.settings,
                name: RouteNames.settings,
                builder: (context, state) => const SettingsScreen(),
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

/// Forwards a `card`-type deck's detail route into its card list (BR-63, W1).
///
/// A card deck holds no sub-decks, so its detail level has nothing of its own to
/// show — the card list belongs to the card screen the card feature owns (AD-13).
/// Rather than land on an empty deck screen and make the user tap through, the
/// route resolves the deck's content type once and redirects.
///
/// **Async, and read through the card feature's own use case.** go_router awaits
/// a `Future`-returning redirect; the deck's content type is a database read, so
/// this asks `ReadDeckHoldsCardsUseCase` — the same card-side seam the header uses
/// — via the root [ProviderScope] container the running app is wrapped in.
///
/// **It fires only when landing *on* the deck.** [GoRouterState.topRoute] being
/// anything deeper — the card list itself, the editor — means we are already past
/// the deck, so returning null there is what stops the redirect chasing its own
/// target into a loop. The forward target is built from the same relative segment
/// the card route is mounted under, so moving the route moves this with it.
Future<String?> _cardDeckRedirect(
  BuildContext context,
  GoRouterState state,
) async {
  if (state.topRoute?.name != RouteNames.deckDetail) return null;
  final deckId = state.pathParameters[RoutePathParams.deckId];
  if (deckId == null) return null;

  final container = ProviderScope.containerOf(context);
  final holdsCards = await _deckHoldsCards(container, deckId);
  if (!holdsCards) return null;

  return '${state.matchedLocation}/${RoutePaths.cardListRelative}';
}

/// The content-type read, guarded so a failure never blocks navigation.
///
/// If the read throws — a database error, or a test that has not wired the card
/// repository — the honest outcome is to stay on the deck's own screen, which
/// renders its own error, not a stuck navigation. So a failure resolves to "does
/// not hold cards": no forward. `on Object` because any thrown type must be
/// absorbed here; nothing about a redirect is worth crashing the app for.
Future<bool> _deckHoldsCards(ProviderContainer container, String deckId) async {
  try {
    return await container.read(readDeckHoldsCardsUseCaseProvider)(deckId);
  } on Object {
    return false;
  }
}
