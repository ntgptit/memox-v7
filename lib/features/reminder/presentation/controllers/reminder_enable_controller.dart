import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/time/clock_provider.dart';
import '../../../../core/time/time_zone_provider.dart';
import '../../domain/models/reminder_time_model.dart';
import '../providers/reminder_use_case_provider.dart';
import '../states/reminder_submit_state.dart';

part 'reminder_enable_controller.g.dart';

/// Turning the reminder on (UC-12 main flow, BR-182, BR-192).
///
/// **One command, one submit state, and that is why there are three of these.**
/// Enabling asks the OS for a permission and can be refused; disabling cannot;
/// changing the time reschedules an existing run. Sharing one `isSubmitting`
/// across them would put the spinner on whichever control the user did not
/// touch, which is the failure `command_query_separation_test.dart` exists to
/// stop.
///
/// **It validates nothing and orders nothing.** The range belongs to
/// [ReminderTime]; capability → permission → write → schedule, and the
/// compensating write when the schedule fails, belong to
/// `EnableReminderUseCase`. What is left here is refusing a second tap and
/// turning a typed failure into a state the screen renders.
///
/// **`now` and the offset are read per submit, not captured at build.** A
/// device that crosses a timezone while the screen is open must schedule
/// against the new offset (AD-16).
@riverpod
class ReminderEnableController extends _$ReminderEnableController {
  @override
  ReminderSubmitState build() => const ReminderSubmitState();

  Future<void> submit(ReminderTime time) async {
    if (!state.canSubmit) return;

    state = const ReminderSubmitState(isSubmitting: true);
    try {
      await ref.read(enableReminderUseCaseProvider)(
        time: time,
        now: ref.read(clockProvider)(),
        utcOffset: ref.read(utcOffsetProvider)(),
      );
      // The screen can be gone by the time the platform call and the write
      // return, and writing state into a disposed notifier throws.
      if (!ref.mounted) return;
      state = const ReminderSubmitState();
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = reminderSubmitFailure(failure);
    }
  }

  /// Clears the banner without re-running anything.
  ///
  /// The banner is long-lived by design (M6 R5) — a refused permission is a
  /// state, not an event — so something has to put it away once it has been
  /// read.
  void reset() => state = const ReminderSubmitState();
}
