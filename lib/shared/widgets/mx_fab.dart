import 'package:flutter/material.dart';

/// The screen-level create/primary action.
///
/// **Exists so no feature builds a `FloatingActionButton` again** — the guard's
/// `no_raw_widget` rule bans the raw widget in `lib/features/`, and this is the
/// door it points at. Everything visual comes from
/// `FloatingActionButtonThemeData`: the brand pair, the house corner, the
/// per-brightness elevation and the state washes are all decisions the theme
/// already made and this widget deliberately cannot override — it takes no
/// `Color`, no shape and no elevation, for the same reason `MxActionButton`
/// takes none.
///
/// **[label] is required and does double duty**: it is the tooltip a long-press
/// shows and the name a screen reader announces for the glyph. A FAB is an icon
/// with no adjacent text, so an unlabeled one is a control TalkBack can only
/// call "button" — the same rule `MxIconButton` enforces with its required
/// `semanticLabel`.
///
/// One screen, one FAB, one verb. A screen that wants two floating actions is
/// asking a different design question, and it should be asked in review rather
/// than answered by a second parameter here.
class MxFab extends StatelessWidget {
  const MxFab({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;

  /// Already-localized. Tooltip and accessible name in one, because for an
  /// icon-only control they are the same sentence.
  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: label,
      child: Icon(icon, semanticLabel: label),
    );
  }
}
