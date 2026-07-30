import 'package:flutter/material.dart';

import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';

/// A selectable pill: the app's control for switching between a small, fixed set
/// of views of the same content.
///
/// **Why this is not one of the existing components.** `MxActionButton` performs
/// something — it has a variant ladder built around primary/destructive intent
/// and no selected state, because a button that stays pressed is a different
/// idea. `MxIconButton` has no label. `MxListTile` is a row, not an inline
/// control. Nothing in `shared/widgets/` held "one of N, and you can see which",
/// so this is the missing piece rather than a second spelling of an existing one.
///
/// **It wraps `ChoiceChip`** for the same reason `MxActionButton` wraps
/// `FilledButton` and `MxIconButton` wraps `IconButton`: Material already owns
/// the selection semantics a screen reader needs, and re-implementing them on an
/// `InkWell` is how a control ends up announcing nothing. The shape, colours and
/// border come from `chipTheme` in `app_theme.dart`, so a pill here and a pill in
/// another feature cannot drift.
///
/// The tap target is padded to [AppSpacing.minimumTouchTarget]. A chip's natural
/// height is below it, and a control that is easy to see and hard to hit is worse
/// than one that is neither.
class MxPillButton extends StatelessWidget {
  const MxPillButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
    super.key,
  });

  /// Already-localized. Components never reach for ARB themselves.
  final String label;

  /// Whether this pill is the active one in its group.
  final bool isSelected;

  /// Null disables the pill. A pill with nothing to switch to should not be
  /// rendered at all, so this is for the transient case — a control whose data
  /// has not arrived — rather than for a permanent one.
  final VoidCallback? onPressed;

  /// Optional leading glyph. Decorative: the label is what is announced, and an
  /// icon that repeated it would be read twice.
  final IconData? icon;

  /// Replaces [label] for assistive technology when the visible text is an
  /// abbreviation — `A–Z` reads as two letters, not as "sort by name".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final pressed = onPressed;

    return ChoiceChip(
      // `semanticsLabel` on the Text rather than a `Semantics` wrapper around the
      // chip. Wrapping was tried and is wrong twice over: `excludeSemantics` drops
      // the chip's tap action along with its label, and without it the reader
      // announces the abbreviation *and* the expansion. Relabelling the child
      // leaves Material's own button and selected flags exactly where they were.
      label: Text(label, semanticsLabel: semanticLabel),
      selected: isSelected,
      onSelected: pressed == null ? null : (_) => pressed(),
      avatar: icon == null ? null : Icon(icon, size: AppIconSize.sm),
      // Padded rather than shrinkWrap: `ChoiceChip` is 32 high by default and the
      // guideline minimum is 48.
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
