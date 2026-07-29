import 'package:flutter/material.dart';

/// The app's bottom navigation bar.
///
/// **Render-only, and deliberately ignorant.** It takes a selected index, a
/// callback and a list of destinations; it does not know GoRouter, does not
/// know what a deck or a review is, and never navigates. A shared widget that
/// knew the route table would drag routing into every widget test in the
/// project — the same argument that keeps `RouteNotFoundScreen` out of
/// `shared/` — and it would stop being usable by any shell with a different
/// set of destinations.
///
/// Labels arrive already localized, like every other component here. The
/// destinations are built by [AppNavigationShell], which owns the copy.
///
/// Material 3 [NavigationBar], never the legacy `BottomNavigationBar`: the
/// legacy widget has its own colour and elevation model that does not read the
/// M3 `ColorScheme`, so it would need hardcoded colours to match the rest of
/// the app.
///
/// Height, colours and the indicator come from `navigationBarTheme` in
/// `app_theme.dart`. Nothing is set here, so a spacing decision cannot differ
/// between this widget and the theme that is supposed to own it.
class MxNavigationBar extends StatelessWidget {
  const MxNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    super.key,
  });

  /// Which destination is current. Out-of-range values are the caller's bug and
  /// are not silently clamped — a bar that shows tab 0 when the router says 3
  /// is a navigation bug wearing a working UI.
  final int selectedIndex;

  final ValueChanged<int> onDestinationSelected;

  /// Already-localized, and at least two: a one-destination bar is a bar with
  /// nothing to navigate between.
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    assert(
      destinations.length >= 2,
      'A navigation bar needs at least two destinations.',
    );

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
      // Labels always visible, on every destination. The M3 default hides the
      // unselected ones, which leaves three unlabelled icons and one labelled
      // — and makes selection readable only as a colour difference, which is
      // exactly what an accessibility review rejects.
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    );
  }
}
