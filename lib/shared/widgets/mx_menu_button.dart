import 'package:flutter/material.dart';

import '../../core/theme/app_ink.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_context_extension.dart';
import 'mx_icon.dart';

/// One action in an [MxMenuButton]'s menu.
class MxMenuAction {
  const MxMenuAction({
    required this.label,
    required this.onSelected,
    this.icon,
    this.isDestructive = false,
    this.isSelected = false,
  });

  /// Already-localized words for the action.
  final String label;

  final VoidCallback onSelected;

  /// Optional leading glyph. Menus mix labeled-only and glyph rows freely —
  /// the sort menu is words alone, the tag menu carries glyphs.
  final IconData? icon;

  /// Destructive actions read in the error ink, glyph and words together.
  final bool isDestructive;

  /// The currently-active choice, for menus that pick one of a set. Material
  /// highlights it when the menu opens.
  final bool isSelected;
}

/// The overflow / picker menu.
///
/// **Exists so no feature builds a `PopupMenuButton` again.** Four sites used
/// to, and they disagreed about the one thing a menu is — how a row looks:
/// two hand-wrote a private `_MenuRow` (muted glyph + words), one built the
/// same row inline with a destructive tint, one used a bare [Text]. This
/// widget makes the row one spelling: [MxIcon] in `quiet` beside `bodyMedium`
/// in `stated`, both switching to `error` when the action is destructive.
///
/// [tooltip] is required, not optional: an icon-anchored menu without one is
/// an unnamed button, and a list of them is "more options" fifteen times in a
/// row to a screen-reader (the tag catalog names each row's menu after its
/// tag for exactly this reason).
///
/// What stays with the caller: *which* actions exist and what they do —
/// including conditional rows — and any custom anchor via [child].
class MxMenuButton extends StatelessWidget {
  const MxMenuButton({
    required this.tooltip,
    required this.actions,
    this.child,
    this.isEnabled = true,
    super.key,
  });

  /// Names the menu itself — spoken for the anchor, shown on long-press.
  final String tooltip;

  final List<MxMenuAction> actions;

  /// Custom anchor. Defaults to the standard overflow glyph.
  final Widget? child;

  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = actions.indexWhere((action) => action.isSelected);

    return PopupMenuButton<int>(
      enabled: isEnabled,
      tooltip: tooltip,
      icon: child == null ? const Icon(Icons.more_vert) : null,
      initialValue: selectedIndex < 0 ? null : selectedIndex,
      onSelected: (index) => actions[index].onSelected(),
      itemBuilder: (menuContext) => <PopupMenuEntry<int>>[
        for (var index = 0; index < actions.length; index++)
          PopupMenuItem<int>(
            value: index,
            child: _MenuRow(action: actions[index]),
          ),
      ],
      child: child,
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.action});

  final MxMenuAction action;

  @override
  Widget build(BuildContext context) {
    final ink = action.isDestructive ? AppInk.error : AppInk.stated;
    final label = Text(
      action.label,
      style: context.texts.bodyMedium!.inked(context, ink),
    );
    if (action.icon == null) {
      return label;
    }

    return Row(
      children: <Widget>[
        MxIcon(
          action.icon!,
          ink: action.isDestructive ? AppInk.error : AppInk.quiet,
        ),
        const SizedBox(width: AppSpacing.md),
        // Expanded, not bare: a long localized label wraps instead of
        // overflowing the menu's fixed width.
        Expanded(child: label),
      ],
    );
  }
}
