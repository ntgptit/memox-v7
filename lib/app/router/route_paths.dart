/// URL paths the app answers to.
///
/// Separate from [RouteNames] because they answer different questions. A path is
/// what a browser or a deep link says; a name is what code says. Keeping both in
/// one place lets a path change without every call site changing with it, which
/// is the whole reason navigation goes through names.
///
/// **Only paths with a real caller live here.** Declaring `/settings`,
/// `/statistics` or `/library` in advance would fix a URL shape before the
/// screen exists to argue with it, and a constant nobody uses reads as a
/// decision that has been made when it has not.
abstract final class RoutePaths {
  /// The app's home, and the initial branch of the navigation shell: content
  /// management is what the user opens the app into.
  static const String decks = '/';

  /// One deck's contents, as a **relative** sub-route of [decks].
  ///
  /// Relative on purpose: GoRouter appends it to the parent route's path, which
  /// is what puts `/decks/:deckId` inside the Decks branch. A leading slash here
  /// would make it a top-level route, and the deck screen would then open with
  /// no bottom bar and no branch to go back into.
  ///
  /// The full location is `/decks/<id>` even though the branch root is `/`; the
  /// list is the app's home, and a deck is addressable under a named collection
  /// so the URL says what it points at.
  static const String deckDetailRelative = 'decks/:deckId';

  /// A card-type deck's card list, **relative** to [deckDetailRelative] so the
  /// full location is `/decks/<id>/cards` and it nests inside the deck route —
  /// the bottom bar stays and Back returns to the deck tree.
  static const String cardListRelative = 'cards';

  /// The card editor, **relative** to [cardListRelative]: create at
  /// `/decks/<id>/cards/new`, edit at `/decks/<id>/cards/<cardId>/edit`. Two
  /// patterns, one screen, told apart by whether a card id is present.
  static const String cardCreateRelative = 'new';
  static const String cardEditRelative = ':cardId/edit';

  /// The study branch. A real path rather than a sub-path of `/` so that a
  /// deep link can open the app directly on the Study tab.
  static const String study = '/study';
}
