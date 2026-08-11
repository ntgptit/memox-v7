import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n_extension.dart';
import '../../shared/widgets/mx_navigation_bar.dart';

/// The chrome that stays put while the branches change.
///
/// It owns the [StatefulNavigationShell], the outer `Scaffold`, the bottom bar
/// and the branch-switching callback — and nothing else. It reads no provider,
/// touches no repository and holds no state of its own: the selected index
/// lives in the router, which is what makes a deep link to `/study` open on
/// the Study tab instead of opening Decks and then jumping.
///
/// **Two Scaffolds, on purpose.** This one carries the bottom bar; each screen
/// carries its own `MxContentShell`, which is a `Scaffold` with the app bar. It
/// is the structure `StatefulShellRoute` is designed around, and it is what
/// makes the bar's inset handling work: a `Scaffold` with a
/// `bottomNavigationBar` removes that height from its body's `MediaQuery`, so
/// the last row of a list ends above the bar rather than under it. Collapsing
/// the two would mean every screen declaring its own bottom bar.
///
/// It lives under `app/` rather than in a feature because it belongs to no
/// feature: it is the frame two features are shown inside, and putting it in
/// either one would make that feature a dependency of the other.
class AppNavigationShell extends StatelessWidget {
  const AppNavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: MxNavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        // Outlined when idle, filled when selected. The pair is not decoration:
        // it is the second, non-colour signal that says which tab is current,
        // alongside the always-visible label. Colour alone fails for a
        // colour-blind user and in high-contrast modes.
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder),
            label: context.l10n.navigationDecksLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school),
            label: context.l10n.navigationStudyLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: context.l10n.navigationProgressLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: context.l10n.navigationSettingsLabel,
          ),
        ],
      ),
    );
  }

  /// Switches branch, keeping each branch's own navigation stack.
  ///
  /// `initialLocation` is true only when the current tab is tapped again, which
  /// is what makes re-selecting a tab pop back to its root instead of doing
  /// nothing. Passing it unconditionally would reset the stack on every switch
  /// and throw away the state the shell exists to preserve.
  void _goBranch(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );
}
