import 'package:flutter/material.dart';

import '../../core/theme/app_button_themes.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';

/// How much weight a button carries on its screen.
///
/// An enum, not a `Color` parameter. The moment a caller can pass a colour, the
/// design system stops being enforceable — every screen becomes free to invent
/// a shade, and no reviewer can tell an intentional variant from a typo.
enum MxActionButtonVariant {
  /// The one action a screen wants the user to take.
  primary,

  /// Everything else. Alternatives, "not now", secondary paths.
  secondary,

  /// Deletes something, or discards work. Added for `MxConfirmDialog` in M4.8
  /// rather than as a second button widget: two button systems is how a screen
  /// ends up with two different "delete" looks.
  ///
  /// Carried by the enum and not by an `isDestructive` flag plus a colour — a
  /// flag beside a colour lets a caller pass one without the other, and the
  /// mismatch is invisible in review.
  destructive,
}

/// The app's button.
///
/// Takes no `Color` and no `TextStyle`. Appearance comes from [variant] and the
/// theme; that is the whole point of having this widget instead of using
/// `FilledButton` directly.
class MxActionButton extends StatelessWidget {
  const MxActionButton({
    required this.label,
    required this.onPressed,
    this.variant = MxActionButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.shouldAutofocus = false,
    super.key,
  });

  /// Already-localized. The screen owns the copy; the button never reads ARB.
  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  final MxActionButtonVariant variant;

  /// While true the button is disabled and shows a spinner — but keeps its
  /// size. A button that shrinks to spinner width moves everything beside it,
  /// so the layout jumps exactly when the user is waiting to see what happened.
  final bool isLoading;

  final IconData? icon;

  /// Whether this button takes focus when its route opens.
  ///
  /// Exists for `MxConfirmDialog`: on a destructive dialog focus starts on
  /// cancel so a stray Enter cannot delete anything.
  final bool shouldAutofocus;

  @override
  Widget build(BuildContext context) {
    // Disabled while loading: without this a second tap queues a second
    // submit, which is the double-submit bug in its most common form.
    final effectiveOnPressed = isLoading ? null : onPressed;
    final child = _buildChild(context);

    return switch (variant) {
      MxActionButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        autofocus: shouldAutofocus,
        child: child,
      ),
      MxActionButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        autofocus: shouldAutofocus,
        child: child,
      ),
      // `error` / `onError`, not a token read directly: the scheme pair is
      // already contrast-checked against each other in `app_theme_test.dart`,
      // and A2 maps `error` onto the `danger` token so the two cannot diverge.
      //
      // **`buildFilledStyle`, not `FilledButton.styleFrom`.** `styleFrom` builds
      // a flat `WidgetStatePropertyAll`, and a non-null property on the widget
      // shadows the theme's for every state at once — so the destructive button
      // did not darken on press and stayed fully red when disabled while its
      // label faded to 38%. A control that looks armed and is inert is worse
      // than one that looks disabled. The same builder the primary variant
      // resolves through, with the error pair substituted for the accent.
      MxActionButtonVariant.destructive => FilledButton(
        onPressed: effectiveOnPressed,
        autofocus: shouldAutofocus,
        style: buildFilledStyle(
          context.colors,
          context.semanticColors,
          fill: context.colors.error,
          label: context.colors.onError,
        ),
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
        // Two lines before ellipsis. One line ellipsizes "Endgültig löschen"
        // down to "End…" at textScaler 3.0, which on a destructive dialog
        // leaves the user approving an action they can no longer read.
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (!isLoading) return content;

    // The label stays laid out and merely invisible, so the button keeps the
    // width it had before the tap. Replacing the child with a spinner would
    // resize it.
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // `alwaysIncludeSemantics` because `RenderOpacity` drops its child from
        // the semantics tree at alpha 0. Without it a submitting button
        // announces as "button, disabled" with no name at all — the user is
        // told something is unavailable and never told what. The spinner
        // contributes `role: loadingSpinner` to the same node, so the busy
        // state is carried without inventing a string that no ARB file owns.
        Opacity(opacity: 0, alwaysIncludeSemantics: true, child: content),
        // Its own layer, so the spin repaints the arc and not the form around
        // it. This one matters more than the full-screen loading state: a
        // submitting button sits inside a form or a dialog, so without the
        // boundary every frame of the animation repaints the fields the user is
        // still looking at.
        const RepaintBoundary(
          child: SizedBox.square(
            dimension: AppIconSize.sm,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ],
    );
  }
}
