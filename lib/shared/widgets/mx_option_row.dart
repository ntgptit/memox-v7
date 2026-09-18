import 'package:flutter/material.dart';

import '../../core/theme/extensions/app_ink.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import '../../core/theme/foundations/app_decorations.dart';
import '../../core/theme/foundations/app_spacing.dart';
import '../../core/theme/foundations/app_stroke.dart';
import '../../core/theme/states/app_interaction_states.dart';
import 'mx_pressable.dart';

/// A single pick-one-of-N row with its own radio ring.
///
/// v3's OptionRow — algorithm, study mode, direction and new-card-order
/// pickers. **Not `MxRadioRows`**: that widget owns the app's existing radio
/// rows (settings, the scheduler picker), built on the ambient
/// `ListTileThemeData` (56 min height, 4/16 padding) and the stock M3 `Radio`
/// (a fixed 16dp dot-in-ring — the outer diameter is a private SDK constant,
/// not a theme slot). This contract's geometry — 48 min height, 12/16
/// padding, a 20dp ring that only ever thickens, never fills — cannot be
/// reached through either, so the row is drawn directly rather than forced
/// through a widget whose numbers already belong to other screens.
///
/// A plain row, not a group: the caller renders one per choice and owns
/// which `isSelected`, the same shape `MxListTile.isSelected` already uses
/// for "one of N" (study direction, restore target) — picking, focus order
/// and business rules stay the caller's.
class MxOptionRow extends StatelessWidget {
  const MxOptionRow({
    required this.title,
    required this.isSelected,
    required this.onSelect,
    this.subtitle,
    this.trailing,
    this.isLast = false,
    super.key,
  });

  /// Already-localized.
  final String title;

  /// Already-localized second line.
  final String? subtitle;

  /// Presentational content in the row's own trailing slot.
  final Widget? trailing;

  final bool isSelected;

  /// `null` locks the row: no ripple, no tap, dimmed to `op-disabled`.
  final VoidCallback? onSelect;

  /// Omits the bottom divider — for the caller's last row in a group.
  final bool isLast;

  static const double _radioColumnWidth = 22;
  static const double _radioDiameter = 20;

  /// The ring's selected width. No [AppStroke] step is 6 — the nearest,
  /// [AppStroke.selectionControl], is the *unselected* width here, and this
  /// is the first control in the app whose ring thickens on selection
  /// instead of filling a dot, so there is no shared step for the heavier
  /// one to reuse.
  static const double _selectedRingWidth = 6;

  static const double _titleSubtitleGap = 2;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final textStyles = context.textStyles;
    final subtitle = this.subtitle;
    final trailing = this.trailing;
    final isEnabled = onSelect != null;

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: _radioColumnWidth,
            child: Center(
              child: Container(
                width: _radioDiameter,
                height: _radioDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? scheme.primary : scheme.outline,
                    width: isSelected
                        ? _selectedRingWidth
                        : AppStroke.selectionControl,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: textStyles.optionRowTitle.inked(
                    context,
                    AppInk.stated,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: _titleSubtitleGap),
                  Text(
                    subtitle,
                    style: textStyles.optionRowDescription.inked(
                      context,
                      AppInk.quiet,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            trailing,
          ],
        ],
      ),
    );

    final Widget divided = DecoratedBox(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: AppDecorations.hairlineEdge(scheme)),
      ),
      child: content,
    );

    final Widget row = Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      enabled: isEnabled,
      child: ExcludeFocus(
        excluding: !isEnabled,
        child: MxPressable(onTap: onSelect, child: divided),
      ),
    );

    return isEnabled
        ? row
        : Opacity(opacity: AppStateOpacity.disabled, child: row);
  }
}
