import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_durations.dart';

/// Handoff Dialog enter: a scale from 0.94 to 1 with a fade.
const double _enterScale = 0.94;

/// A Material dialog route with the handoff's enter motion (M100.93).
///
/// Everything else — the barrier, the safe area, the captured themes — is
/// `DialogRoute`'s own.
class MxDialogRoute<T> extends DialogRoute<T> {
  MxDialogRoute({
    required super.context,
    required super.builder,
    required super.themes,
    required super.barrierColor,
    required super.animationStyle,
    super.barrierDismissible,
    super.barrierLabel,
  });

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppDurations.standard,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: _enterScale, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}

/// `showDialog` with the handoff's motion: 200ms on the standard curve, and no
/// animation at all under reduced motion. The same root navigator and theme
/// capture `showDialog` uses.
Future<T?> showMxDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(
    MxDialogRoute<T>(
      context: context,
      builder: builder,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierColor: DialogTheme.of(context).barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      animationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: AppDurations.normal,
              reverseDuration: AppDurations.normal,
            ),
    ),
  );
}
