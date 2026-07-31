import 'package:flutter/material.dart';

/// Stand-ins for the surfaces a component is really used on.
///
/// Split from `mx_components_golden_test.dart` at the 400-line guard. A specimen
/// photographed in the wrong place is its own kind of defect — see the class
/// below for the one that made a shared component look broken when it was not —
/// so these belong together and away from the specimen list.

/// The surface a list row is actually used on.
///
/// **A specimen fix, not a component change.** These goldens put `MxListTile`
/// straight onto a bare `Scaffold`, so it photographed as a bare row on the page
/// — which made it look like the one shared component that had not been brought
/// in line with `MxCard`. It has exactly one caller, the move-deck sheet, and a
/// sheet is a `surface`. The row was never wrong; the picture was taken in a
/// place the row never appears.
///
/// The alternative was giving `MxListTile` an opt-in surface, which would have
/// been a capability with no caller — the thing this project refuses on every
/// other component.
class OnSheetSurface extends StatelessWidget {
  const OnSheetSurface({required this.child, super.key});

  final Widget child;

  /// A `Material`, not a `ColoredBox`. Flutter asserts on the latter and the
  /// assertion is right: a `ListTile` paints its background and its ink into the
  /// nearest `Material` ancestor, so a plain coloured box in between hides both.
  /// A sheet *is* a Material, so this is also the more faithful stand-in.
  @override
  Widget build(BuildContext context) =>
      Material(color: Theme.of(context).colorScheme.surface, child: child);
}
