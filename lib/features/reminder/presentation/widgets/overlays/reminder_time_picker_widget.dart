import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/reminder_time_model.dart';

/// Asks for a reminder time, returning `null` when the user backs out.
///
/// **The platform dialog rather than a screen of our own** (M6 R6). A time is
/// the one value this collects, and Android users already know this dialog;
/// a bespoke route would add a URL, a back-handling rule and a layout for a
/// single number.
///
/// **The result goes back through `ReminderTime.parse`.** The picker cannot
/// produce an out-of-range value today, but the type is the only proof that the
/// range was checked (BR-219) — accepting the raw hour and minute here would
/// move that proof to "the picker is well behaved", which is an argument rather
/// than a check. A value that somehow fails parsing is treated as a cancel:
/// there is nothing to tell the user about a dialog that returned nonsense, and
/// keeping the stored time is the safe reading.
Future<ReminderTime?> showReminderTimePicker(
  BuildContext context,
  ReminderTime initial,
) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    helpText: context.l10n.reminderTimeLabel,
  );
  if (picked == null) return null;

  return ReminderTime.fromHourMinute(
    hour: picked.hour,
    minute: picked.minute,
  ).time;
}
