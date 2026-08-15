import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/models/reminder_overview_model.dart';
import '../providers/reminder_use_case_provider.dart';

part 'reminder_overview_controller.g.dart';

/// The reminder screen's data: the stored choice and what the device can do.
///
/// **One subscription, one model** (AD-13). Watching the settings row and asking
/// the platform separately would let the screen draw an enabled toggle beside a
/// capability that has since come back unsupported — a control that looks live
/// and is not.
///
/// **A stream, because the row is the source of truth.** Every command writes
/// the database and the screen learns about it from here, so a toggle can never
/// show a value the database rejected — which is what makes the compensating
/// writes in the use cases visible rather than silent.
///
/// [noAutomaticRetry] for the reason `retry_policy.dart` gives: a failed local
/// read must show its error, not thirteen seconds of spinner.
@Riverpod(retry: noAutomaticRetry)
Stream<ReminderOverviewModel> reminderOverview(Ref ref) =>
    ref.watch(watchReminderOverviewUseCaseProvider)();
