import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';

/// What a compact icon button spends of a row. The height stays at
/// `AppSpacing.minimumTouchTarget`.
const double _kCompactWidth = 36;

/// An action with no visible label.
///
/// [semanticLabel] is **required**, and that is the entire reason this widget
/// exists rather than `IconButton`. An icon-only control with no label is a
/// blank button to a screen reader — the user is told there is something
/// tappable and nothing about what it does. Making the label optional means it
/// gets omitted, because omitting it changes nothing anyone can see.
///
/// The label is carried by the `Icon`, not by a `Semantics` wrapper. A wrapper
/// with `excludeSemantics` would take the button's own node with it and lose
/// "button", "enabled" and the tap action; the icon's label merges into that
/// node instead and leaves all three intact.
///
/// Size comes from `AppIconSize` and the 48×48 minimum from
/// `IconButtonThemeData`. [isCompact] is the one adjustment, and it gives up
/// **width only**: the button spends 36 of a row instead of 48 and keeps the
/// full 48 of height, so a thumb still has the whole bar to land in vertically.
/// It exists for the study session's top bar, where the close button shares a
/// row with a progress track that has to read as a measure — see
/// `AppIconSize.mdCompact`. There is no parameter that shrinks both axes.
class MxIconButton extends StatelessWidget {
  const MxIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tooltip,
    this.isCompact = false,
    super.key,
  });

  final IconData icon;

  /// Already-localized. What the action does, not what the glyph looks like.
  final String semanticLabel;

  /// `null` disables the button. A disabled button invokes nothing — Flutter
  /// drops the gesture, so there is no path from a tap to the callback.
  final VoidCallback? onPressed;

  /// Already-localized. Only when the visible hover/long-press text should read
  /// differently from [semanticLabel]; otherwise the label serves both and the
  /// two cannot drift apart.
  final String? tooltip;

  /// Narrows the button to 36 wide, keeping its 48 of height.
  ///
  /// For a control sharing a row with something that needs the width. The
  /// glyph drops to [AppIconSize.mdCompact] with it — a 24px icon in a 36px box
  /// leaves six pixels either side and reads as cramped rather than compact.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip ?? semanticLabel,
      constraints: isCompact
          ? const BoxConstraints.tightFor(
              width: _kCompactWidth,
              height: AppSpacing.minimumTouchTarget,
            )
          : null,
      padding: isCompact ? EdgeInsets.zero : null,
      icon: Icon(
        icon,
        size: isCompact ? AppIconSize.mdCompact : AppIconSize.md,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
