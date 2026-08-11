import 'package:flutter/material.dart';

import '../../core/theme/theme_context_extension.dart';

/// How much width one destination may claim before the row stops growing.
///
/// `NavigationBar` divides its width evenly, so with two destinations on a phone
/// they land at the quarter and three-quarter marks — one hard against each
/// edge, with a void between them that reads as a missing tab rather than as
/// space. Capping the row and centring it puts them either side of the middle.
///
/// Multiplied by the destination count, so **the cap disarms itself**: at four
/// destinations the row wants more width than a phone has, the screen becomes
/// the binding constraint, and the bar fills it edge to edge — which is the
/// arrangement Material designed the even split for. A fixed maximum would
/// instead have to be revisited every time a tab is added. The `Flexible` in
/// the build is what hands the screen's width down so the cap can lose to it;
/// without it the row believes the width is unbounded and four destinations
/// overflow a 393dp surface by 87px (M99.7).
///
/// Seamless because `navigationBarTheme.backgroundColor` and
/// `scaffoldBackgroundColor` are the same token: the bar paints the page colour,
/// so narrowing it leaves no band edge to notice.
///
/// This is `--nav-width-per-destination` in `design_system/tokens/layout.css`,
/// and it is public for that reason: a private copy is a token the CSS/Dart
/// parity check cannot see, which is how it sat outside parity until M4.10ap.
const double widthPerNavigationDestination = 120;

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
/// `app_theme.dart`. The one thing set here is how wide the destination row is
/// allowed to grow — see [widthPerNavigationDestination] — because `NavigationBarThemeData`
/// has no property for it and the alternative is every caller solving it again.
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

    // **The hairline lives here, not in the theme**, because
    // `NavigationBarThemeData` has no border slot. It is needed *because* of the
    // choices above it: the bar paints the page colour and carries no elevation,
    // so without a line the chrome and the content share an edge with nothing on
    // it, and a list scrolled to the bottom runs straight into the tabs. The
    // design draws the same 1px `--color-border-subtle` for the same reason.
    //
    // Full width even though the destinations are capped at 120dp each — the
    // edge being marked is the screen's, not the row's.
    //
    // A `Row`, not an `Align` or a `Center`: both of those expand to fill, and in
    // the Scaffold's `bottomNavigationBar` slot that made the bar claim the whole
    // body — the list then scrolled underneath it and the destinations stopped
    // hit-testing. A `Row` stretches only across, and takes its height from the
    // bar itself.
    // `foreground`, not the default `background`: `NavigationBar` paints its own
    // fill, so a border drawn behind it survives only either side of the
    // destination row. The first render of this showed exactly that — a line at
    // both edges and a gap in the middle where the bar sat on top of it.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.semanticColors.borderSubtle),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // `Flexible`, because a `Row` gives a plain child unbounded width:
          // the cap then always wins, and the moment it exceeds the screen —
          // four destinations at 120dp on a 393dp phone — the row overflows.
          // Loose flex hands the child the screen's width as a *maximum*
          // instead, so the bar takes min(cap, screen): capped and centred
          // with two destinations, edge to edge with four.
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: destinations.length * widthPerNavigationDestination,
              ),
              // `labelBehavior` deliberately not set here: `navigationBarTheme`
              // owns it, and a second spelling of the same decision is how the
              // two drift apart.
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: destinations,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
