import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_spacing.dart';

/// What the shell knows about the bottom of a scrolling body — whether a
/// floating action sits over it.
///
/// **The shell owns the clearance** (A20.1 P2-18). The deck list carried
/// `AppSpacing.fabScrollClearance` as a private constant and the search list
/// carried `AppSpacing.lg` as another, each deciding for itself how far its
/// last row had to sit from the edge. Only the shell knows whether there is a
/// button to clear, so only the shell can answer.
class MxScrollEndInsetScope extends InheritedWidget {
  const MxScrollEndInsetScope({
    required this.hasFloatingAction,
    required super.child,
    super.key,
  });

  final bool hasFloatingAction;

  @override
  bool updateShouldNotify(MxScrollEndInsetScope oldWidget) =>
      hasFloatingAction != oldWidget.hasFloatingAction;
}

/// The inset a scrolling list leaves after its last row.
///
/// Under a floating action it is the clearance the button needs plus the
/// gesture inset — on a device with a home indicator the last row would
/// otherwise end under it. Without one it is the ordinary end gap. Outside a
/// shell there is no button to clear, so a body pumped on its own gets the
/// ordinary gap too.
double mxScrollEndInsetOf(BuildContext context) {
  final scope = context
      .dependOnInheritedWidgetOfExactType<MxScrollEndInsetScope>();
  if (scope == null || !scope.hasFloatingAction) return AppSpacing.lg;
  return AppSpacing.fabScrollClearance +
      MediaQuery.viewPaddingOf(context).bottom;
}
