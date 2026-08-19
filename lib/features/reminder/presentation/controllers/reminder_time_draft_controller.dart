import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/reminder_time_model.dart';

part 'reminder_time_draft_controller.g.dart';

/// The time the user last picked, kept so a retry re-submits *that* value.
///
/// **It exists because the rollback is correct and the retry was not.**
/// `ChangeReminderTimeUseCase` restores the previous time when the reschedule
/// fails, so by the time the error banner is on screen the database no longer
/// holds what the user chose — and a retry built from the stored row would
/// silently re-submit the old time while the copy says "try again".
///
/// One value and one mutator, which is what an input-state notifier is allowed
/// to be. It holds no failure and runs no use case: the command still lives in
/// [ReminderTimeController], and this is only the input that command was given.
///
/// `null` means nothing has been picked this visit, in which case a retry falls
/// back to the stored time — the same value the picker would have opened at.
@riverpod
class ReminderTimeDraftController extends _$ReminderTimeDraftController {
  @override
  ReminderTime? build() => null;

  void remember(ReminderTime time) => state = time;
}
