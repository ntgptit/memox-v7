import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_decorations.dart';
import '../../core/theme/foundations/app_derived_colors.dart';
import '../../core/theme/foundations/app_effects.dart';
import '../../core/theme/foundations/app_radius.dart';
import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/foundations/app_spacing.dart';

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
/// Seamless because the `Row` this constrains still fills the wrapper's full
/// width (its default `mainAxisSize.max`, unchanged by the cap) — the glass
/// card is one continuous surface with the destinations centred inside it,
/// not a card that shrinks down to them. Before v3 the bar painted the page
/// colour edge to edge instead, so "seamless" meant matching the page; now it
/// means the flanking space and the destination row share one glass fill.
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
/// **A floating glass bar since v3 (spec bottom-nav), not an edge-to-edge
/// one.** The wrapper below paints `chrome-glass` (`surface` at
/// [AppEffects.glassOpacity]) behind a live blur, clips it to [AppRadius.lg]
/// and draws `border-ghost` around all four sides — the component's own
/// geometry, per the contract. `navigationBarTheme` still owns the
/// indicator, the label style and the icon step; it hands this widget a
/// transparent [NavigationBar] background so the glass shows through
/// instead of a second opaque fill sitting on top of it.
///
/// The painted bar is a fixed [AppSizing.bottomBarHeight] regardless of the
/// device's gesture inset — see the safe-area handling in [build]. The one
/// thing set here beyond that is how wide the destination row is allowed to
/// grow — see [widthPerNavigationDestination] — because `NavigationBarThemeData`
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

    final ColorScheme scheme = Theme.of(context).colorScheme;

    // The wrapper's own bottom padding carries the device's gesture inset —
    // read here, from the *real* MediaQuery, before it is zeroed for the
    // `NavigationBar` below. `.padding`, not `.viewPadding`: that is what
    // `NavigationBar`'s own (now-removed) internal `SafeArea` read by
    // default, and matching it keeps the on-device position of the
    // destinations unchanged from before this wrapper existed.
    final double gestureInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      // Wrapper padding, FIXED by the contract: 4 top, 8 sides, 12 + the
      // gesture inset on the bottom. It is what keeps the bar in flow —
      // never overlapping the scroll — while the painted bar itself stays a
      // constant [AppSizing.bottomBarHeight] no matter how much inset a
      // device contributes.
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md + gestureInset,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        // **Blurs whatever is behind this widget, and today that is the
        // Scaffold's own flat background** — `AppNavigationShell`'s
        // `Scaffold` does not set `extendBody`, so the branch content never
        // paints under this slot for the blur to soften. Turning it on is
        // the caller's call, not this component's: it stops the Scaffold
        // reserving the bar's height from the body's `MediaQuery`, so every
        // branch would need its own clearance for a floating bar instead of
        // getting it for free — exactly the "quyết định bố cục" M100.100
        // named and left blocked. Until that lands, a solid `chrome-glass`
        // fill is the stated fallback (the component contract's own
        // HTML/JSX translation note): correct today, and the blur is already
        // wired for the day the caller decides to extend the body.
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppEffects.glassBlurSigma,
            sigmaY: AppEffects.glassBlurSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              // `chrome-glass` — `surface` at `op-glass`, read DIRECT per the
              // v3 theme-prerequisite spec. Translucent on purpose: it
              // composites over whatever the blur above already softened,
              // not over a pre-flattened page colour.
              color: AppDerivedColors.chromeGlass(scheme),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              // `border-ghost`, around all four sides now that the bar is a
              // floating rounded card rather than an edge-to-edge strip —
              // the top-only hairline this replaced marked the screen's
              // edge; a floating card marks its own.
              border: Border.fromBorderSide(
                AppDecorations.hairlineEdge(scheme),
              ),
            ),
            // A `Row`, not an `Align` or a `Center`: both of those expand to
            // fill, and in the Scaffold's `bottomNavigationBar` slot that made
            // the bar claim the whole body — the list then scrolled underneath
            // it and the destinations stopped hit-testing. A `Row` stretches
            // only across, and takes its height from the bar itself.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // `Flexible`, because a `Row` gives a plain child unbounded
                // width: the cap then always wins, and the moment it exceeds
                // the screen — four destinations at 120dp on a 393dp phone —
                // the row overflows. Loose flex hands the child the screen's
                // width as a *maximum* instead, so the bar takes
                // min(cap, screen): capped and centred with two destinations,
                // edge to edge with four.
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth:
                          destinations.length * widthPerNavigationDestination,
                    ),
                    // `NavigationBar` wraps itself in a `SafeArea` and grows
                    // past its own `height` to hold the device's bottom
                    // inset — exactly the space this wrapper's padding
                    // already reserved above. Zeroing it here is what keeps
                    // the painted bar at a true, constant
                    // `AppSizing.bottomBarHeight` instead of double-counting
                    // the inset.
                    child: MediaQuery.removePadding(
                      context: context,
                      removeBottom: true,
                      child: NavigationBar(
                        height: AppSizing.bottomBarHeight,
                        selectedIndex: selectedIndex,
                        onDestinationSelected: onDestinationSelected,
                        destinations: destinations,
                        // `labelBehavior` deliberately not set here:
                        // `navigationBarTheme` owns it, and a second
                        // spelling of the same decision is how the two
                        // drift apart.
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
