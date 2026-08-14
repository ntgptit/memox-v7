import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/time/clock_provider.dart';
import '../../../../core/time/time_zone_provider.dart';
import '../providers/reminder_use_case_provider.dart';
import '../states/reminder_submit_state.dart';

part 'reminder_disable_controller.g.dart';

/// Turning the reminder off (UC-12 A2, BR-190).
///
/// Its own submit state for the reason `ReminderEnableController` gives: the
/// two directions of one toggle fail in different ways and must not share a
/// spinner.
///
/// **No permission and no confirmation.** Turning something off is not a
/// decision the app gets to question, and asking the OS for anything here would
/// be asking on a path the user is walking away from.
@riverpod
class ReminderDisableController extends _$ReminderDisableController {
  @override
  ReminderSubmitState build() => const ReminderSubmitState();

  Future<void> submit() async {
    if (!state.canSubmit) return;

    state = const ReminderSubmitState(isSubmitting: true);
    try {
      await ref.read(disableReminderUseCaseProvider)(
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
