import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';

/// How much weight a button carries on its screen.
///
/// An enum, not a `Color` parameter. The moment a caller can pass a colour, the
/// design system stops being enforceable — every screen becomes free to invent
/// a shade, and no reviewer can tell an intentional variant from a typo.
enum AppButtonVariant {
  /// The one action a screen wants the user to take.
  primary,

  /// Everything else. Alternatives, "not now", secondary paths.
  secondary,
}

/// The app's button.
///
/// Takes no `Color` and no `TextStyle`. Appearance comes from [variant] and the
/// theme; that is the whole point of having this widget instead of using
/// `FilledButton` directly.
class AppButtonWidget extends StatelessWidget {
  const AppButtonWidget({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  /// Already-localized. The screen owns the copy; the button never reads ARB.
  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  final AppButtonVariant variant;

  /// While true the button is disabled and shows a spinner — but keeps its
  /// size. A button that shrinks to spinner width moves everything beside it,
  /// so the layout jumps exactly when the user is waiting to see what happened.
  final bool isLoading;

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Disabled while loading: without this a second tap queues a second
    // submit, which is the double-submit bug in its most common form.
    final effectiveOnPressed = isLoading ? null : onPressed;
    final child = _buildChild(context);

    return switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
    };
  }

  Widget _buildChild(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: AppIconSize.sm),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    if (!isLoading) return content;

    // The label stays laid out and merely invisible, so the button keeps the
    // width it had before the tap. Replacing the child with a spinner would
    // resize it.
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Opacity(opacity: 0, child: content),
        const SizedBox.square(
          dimension: AppIconSize.sm,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }
}
