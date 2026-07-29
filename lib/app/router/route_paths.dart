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

  /// The review branch. A real path rather than a sub-path of `/` so that a
  /// deep link can open the app directly on the Review tab.
  static const String review = '/review';
}
