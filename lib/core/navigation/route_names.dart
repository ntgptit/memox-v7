/// The names every navigation call uses.
///
/// **In `core/` because both sides of a navigation need it and neither owns it.**
/// `app/router/` registers these names on the route table; a feature screen passes
/// one to `goNamed`. They used to live under `app/router/`, which made every
/// screen that navigates import `app/` — a feature depending on the shell.
/// Inverting it was not an option either: the router cannot take its names *from*
/// the features, because a route belongs to the table, not to one screen.
///
/// So the names are a vocabulary in `core/`, which no feature owns and every
/// feature may read, exactly like `clockProvider`. `RoutePaths` deliberately did
/// **not** come along: a path is the app's URL contract and only the route table
/// asserts it, so no feature has any business seeing one.
///
/// UI navigates by name, never by path. A path is a public URL contract that
/// changes for reasons that have nothing to do with the code — a marketing
/// redirect, a deep-link scheme, a nesting change — and a hardcoded deck path
/// spread over twenty screens turns each of those into a twenty-file edit that
/// the compiler cannot help with.
///
/// A name also fails loudly: `goNamed` on an unregistered name throws at the
/// call, while a mistyped path quietly lands on the 404 screen and looks like a
/// routing decision somebody made on purpose.
abstract final class RouteNames {
  /// The root deck list. Branch 0 of the shell, and the app's initial
  /// destination (UC-06).
  static const String decks = 'decks';

  /// One deck's contents. A child of [decks], so it stays inside the Decks
  /// branch and the bottom bar remains visible.
  static const String deckDetail = 'deckDetail';

  /// The review surface. Branch 1 of the shell; still a placeholder until the
  /// real session screen lands in M5.4.
  static const String review = 'review';
}

/// Names of the path parameters routes carry.
///
/// Constants because a path parameter is read by a different file than the one
/// that writes it — `context.goNamed(..., pathParameters: {'deckId': id})` in a
/// screen, `state.pathParameters['deckId']` in the route table. A typo in either
/// half compiles, and surfaces as a null id at runtime.
abstract final class RoutePathParams {
  static const String deckId = 'deckId';
}
