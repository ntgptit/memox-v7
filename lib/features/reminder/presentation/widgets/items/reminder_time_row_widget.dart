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

    // **The time is a subtitle, not a trailing widget** (M6 W4, A2). Beside the
    // label it took 157 of the row's ~264dp at 320dp and text scale 2, leaving
    // the label 90dp for 422dp of intrinsic width — `MxListTile` caps at two
    // lines and then ellipsises, so the label was *cut*, which A2 forbids.
    // Under the label it has the whole row and no scale can truncate it.
    //
    // **No `Semantics(value:)` wrapper** (M6 A4). `MxListTile` merges its title
    // and subtitle into one node, so the time is already inside the announced
    // label; adding it again as a value made a screen reader say it twice.
    // One node, one button, the time spoken once.
    return MxListTile(
      title: context.l10n.reminderTimeLabel,
      subtitle: value,
      isEnabled: isChangeable,
      onTap: onTap,
    );
  }
}
