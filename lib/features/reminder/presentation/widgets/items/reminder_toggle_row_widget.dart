import 'package:flutter/material.dart';

import '../../../../../shared/widgets/mx_switch_row.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';

/// The on/off row of the reminder card (M6 W3).
///
/// **A `Switch` beside its own label rather than `SwitchListTile`.** The row has
/// to state its value in words as well as in the switch (M6 R7), and the tile's
/// own semantics wrap the whole row into one node — which makes the spoken value
/// the label rather than "on"/"off".
///
/// **The label is the tap target for nothing.** Only the switch toggles; tapping
/// the row does not. A row that flips a setting when the user meant to read it
/// is the wrong trade for something that then asks the OS for a permission.
class ReminderToggleRowWidget extends StatelessWidget {
  const ReminderToggleRowWidget({
    required this.isEnabled,
    required this.isChangeable,
    required this.onChanged,
    super.key,
  });

  /// The stored value, which is what the switch shows.
  final bool isEnabled;

  /// Whether the control accepts input at all — false while a command runs and
  /// on a platform without reminders (BR-229).
  final bool isChangeable;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The screen gutter, not a fixed `lg`: the time row below takes its
      // horizontal inset from `ListTileTheme.contentPadding`, which
      // `applyCompactScale` steps down to 12 below 360dp. A literal here left
      // the two rows of one card on two left edges at 320dp (M6 R2).
      padding: EdgeInsets.symmetric(
        horizontal: mxScreenGutter(context),
        vertical: AppSpacing.xs,
      ),
      // One node, one state (WCAG 4.1.2, A20.1 P2-13): the label is the
      // switch's name and the toggle is its state — MxSwitchRow owns the
      // pattern.
      child: MxSwitchRow(
        label: context.l10n.reminderToggleLabel,
        isOn: isEnabled,
        onChanged: isChangeable ? onChanged : null,
      ),
    );
  }
}
