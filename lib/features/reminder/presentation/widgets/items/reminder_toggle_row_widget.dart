import 'package:flutter/material.dart';

import '../../../../../shared/widgets/mx_switch_row.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../support/reminder_labels_widget.dart';

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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      // The announced variant (M6 A3, WCAG 4.1.2): the switch alone carries
      // the label and the value in words, and the label is the tap target for
      // nothing — MxSwitchRow owns the pattern and its reasoning now.
      child: MxSwitchRow(
        label: context.l10n.reminderToggleLabel,
        announcedValue: context.reminderToggleValue(isEnabled: isEnabled),
        isOn: isEnabled,
        onChanged: isChangeable ? onChanged : null,
      ),
    );
  }
}
