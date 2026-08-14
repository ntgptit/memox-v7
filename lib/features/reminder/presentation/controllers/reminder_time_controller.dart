import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/time/clock_provider.dart';
import '../../../../core/time/time_zone_provider.dart';
import '../../domain/models/reminder_time_model.dart';
import '../providers/reminder_use_case_provider.dart';
import '../states/reminder_submit_state.dart';

part 'reminder_time_controller.g.dart';

/// Moving the reminder to another time of day (UC-12 A1, BR-183).
///
/// Its own submit state, like the other two: a failed reschedule must mark the
/// time row, not the toggle the user did not touch.
///
/// **The range check ran before this, and the type proves it.** The parameter
/// is a [ReminderTime], which cannot exist without having passed
/// [ReminderTime.parse] — so no caller can hand over a minute of 5000, and the
/// screen never re-derives which bound was broken.
@riverpod
class ReminderTimeController extends _$ReminderTimeController {
  @override
  ReminderSubmitState build() => const ReminderSubmitState();

  Future<void> submit(ReminderTime time) async {
    if (!state.canSubmit) return;

    state = const ReminderSubmitState(isSubmitting: true);
    try {
      await ref.read(changeReminderTimeUseCaseProvider)(
        time: time,
        now: ref.read(clockProvider)(),
        utcOffset: ref.read(utcOffsetProvider)(),
      );
      if (!ref.mounted) return;
      state = const ReminderSubmitState();
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = reminderSubmitFailure(failure);
    }
  }

  void reset() => state = const ReminderSubmitState();
}
