import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_list_tile.dart';
import '../../../domain/models/reminder_time_model.dart';
import '../support/reminder_labels_widget.dart';

/// The row that opens the time picker (M6 W4).
///
/// **Always present, disabled rather than hidden** (M6 R3). Hiding it while the
/// reminder is off makes the card change height at the exact moment the user
/// touches the toggle — and BR-192 means that move can fail and be undone, so
/// the jump would happen twice. Showing it also lets someone see the default
/// 20:00 before deciding whether to opt in at all.
class ReminderTimeRowWidget extends StatelessWidget {
  const ReminderTimeRowWidget({
    required this.time,
    required this.isChangeable,
    required this.onTap,
    super.key,
  });

  final ReminderTime time;

  /// False while the reminder is off, while a command runs, and on a platform
  /// without reminders.
  final bool isChangeable;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = context.reminderTimeText(time);

    // `Semantics(value:)` around the tile rather than a label on the `Text`:
    // `MxListTile` merges its children into one node, so the time would
    // otherwise be spoken as part of the title instead of as the row's value
    // (M6 A4).
    return Semantics(
      value: value,
      child: MxListTile(
        title: context.l10n.reminderTimeLabel,
        trailing: Text(value),
        isEnabled: isChangeable,
        onTap: onTap,
      ),
    );
  }
}
