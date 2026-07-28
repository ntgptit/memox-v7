---
name: flutter-navigation
description: GoRouter setup and navigation rules for this Flutter app — centralised route declarations, typed routes and path constants, StatefulShellRoute for bottom navigation, auth redirect guards, 404 handling, deep links, and correct back behaviour on Android and iOS. Use this skill when adding a screen or route, wiring bottom navigation or nested navigation, implementing login redirects or route guards, handling deep links or cold-start links, passing data between screens, or debugging a wrong back-button or duplicated-stack behaviour. Covers checklist phase 8.
---

# Navigation

Covers checklist Phase 8. Router configuration lives in `app/router/`.

```
app/router/
├── app_router.dart      # GoRouter instance, redirect logic
├── route_paths.dart     # path + name constants
└── route_guards.dart    # auth and onboarding guards
```

## Routes are declared centrally, referenced by name

No widget contains a path string. Paths live in one place; screens navigate by
name so a path change is a one-line edit rather than a grep-and-pray.

```dart
abstract final class RoutePaths {
  static const splash = '/';
  static const login = '/login';
  static const decks = '/decks';
  static const deckDetail = '/decks/:deckId';   // pattern
  static const settings = '/settings';
}

abstract final class RouteNames {
  static const splash = 'splash';
  static const login = 'login';
  static const decks = 'decks';
  static const deckDetail = 'deckDetail';
  static const settings = 'settings';
}
```

```dart
context.goNamed(RouteNames.deckDetail, pathParameters: {'deckId': id});  // yes
context.go('/decks/$id');                                                // no
```

`go_router_builder` typed routes are worth adopting if the route table grows —
they make parameter mistakes compile errors instead of runtime 404s. Either
approach satisfies the checklist; the thing that does not is a raw string in a
widget.

## Pass IDs, not objects

Route extras are not part of the URL, so anything passed that way is absent on
a cold-start deep link and lost on state restoration. A screen that receives a
`Deck` object works when reached by tapping and shows a blank page when reached
from a notification.

Pass the ID, load from the repository on the target screen. The list already
cached the data, so the load is usually instant anyway. Use `extra` only for
things that genuinely cannot be re-derived and only matter in-session.

## Shell routes and bottom navigation

`StatefulShellRoute.indexedStack` gives each tab its own `Navigator` and
preserves its stack across tab switches — which is what users expect: switching
away and back should not reset a scroll position or pop a detail screen.

Nest detail routes *inside* the branch that owns them so the tab bar stays
visible and the branch's back stack is correct.

## Guards

Put auth redirection in the router's `redirect`, not in screen `initState`. A
guard in `initState` means the protected screen is built and briefly visible
before the redirect fires, and every new screen has to remember to add it.

```dart
redirect: (context, state) {
  final isSignedIn = ref.read(authStateProvider).isSignedIn;
  final isOnAuthRoute = state.matchedLocation == RoutePaths.login;

  if (!isSignedIn && !isOnAuthRoute) {
    // Preserve where they were headed so login can return them there.
    return Uri(
      path: RoutePaths.login,
      queryParameters: {'from': state.matchedLocation},
    ).toString();
  }
  if (isSignedIn && isOnAuthRoute) return RoutePaths.decks;
  return null;   // null means "no redirect", not "block"
}
```

Two things this must get right or it will loop forever: the guard must exempt
the route it redirects *to*, and it must return `null` (not the current path)
when no redirect is needed.

Rebuild the router on auth change with `refreshListenable`, driven from the auth
provider. Without it, signing out leaves the user sitting on a protected screen
until they navigate.

## 404 and errors

Set `errorBuilder` to a real screen with a route back to a known-good location.
The default red error page is a dead end for the user and leaks framework
detail.

## Deep links

A deep link must work on cold start, which is the case that breaks: the app
launches, the router evaluates the redirect before auth state has loaded, and
the user lands on login instead of the deep-linked screen.

Handle it by having the splash route hold until auth resolves, and by preserving
the intended destination through the login flow (the `from` parameter above).

Test each supported link cold (app not running), warm (backgrounded), and while
already on the target screen.

## Back behaviour

Android's system back and iOS's edge swipe must both do the sensible thing.

- Never push a duplicate of the current route — repeated taps on a list item
  while the push animates is the usual cause. Guard with a debounce or check
  the current location.
- Dialogs and bottom sheets participate in the back stack. Dismissing one should
  not exit the screen behind it.
- Use `PopScope` for unsaved-changes confirmation, and make sure the callback
  handles a declined pop correctly rather than popping anyway.
- After `await`ing a navigation result, check `context.mounted` before using
  the context — the analyzer's `use_build_context_synchronously` rule catches
  most of these but not all.

## Checks before navigation is done

- [ ] No path string outside `route_paths.dart`.
- [ ] Every route reachable by name.
- [ ] Auth guard covers all protected routes and cannot loop.
- [ ] 404 screen offers a way back.
- [ ] Each deep link tested cold, warm, and while already open.
- [ ] Tab state survives tab switching.
- [ ] Back works on Android and iOS, including from dialogs and sheets.
- [ ] No route receives a domain object where an ID would do.
