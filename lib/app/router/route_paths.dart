/// URL paths the app answers to.
///
/// Separate from [RouteNames] because they answer different questions. A path is
/// what a browser or a deep link says; a name is what code says. Keeping both in
/// one place lets a path change without every call site changing with it, which
/// is the whole reason navigation goes through names.
///
/// **Only paths with a real caller live here.** Declaring `/decks`, `/settings`
/// or `/login` in advance would fix a URL shape before the screen exists to
/// argue with it, and a constant nobody uses reads as a decision that has been
/// made when it has not.
abstract final class RoutePaths {
  /// The app's home. Review is the only feature in the MVP, so it is the root
  /// rather than a sub-path.
  static const String review = '/';
}
