import '../models/reminder_capability_model.dart';
import '../models/reminder_summary_model.dart';
import '../models/reminder_time_model.dart';

/// Everything the operating system does for the reminder, behind one contract.
///
/// **One contract for four verbs, and deliberately not four.** Capability,
/// permission, scheduling and display are one device, one plugin pair and one
/// unsupported-platform answer (BR-229); splitting them would make every caller
/// hold four references that can only ever be satisfied together, and would let
/// a test fake a supported platform that cannot show anything.
///
/// **No plugin type crosses this line.** The implementations own
/// `flutter_local_notifications` and `workmanager` entirely (AD-21), which is
/// what keeps `domain/` free of Flutter and lets an unsupported adapter satisfy
/// the same signature without a single platform check above it.
abstract interface class ReminderPlatformRepository {
  /// Whether this device can deliver reminders at all (BR-229).
  ///
  /// Asked before anything else and answered without side effects: it must not
  /// prompt, schedule or show.
  Future<ReminderCapability> readCapability();

  /// Asks the OS for permission to post notifications (BR-228).
  ///
  /// **Called only after the user turns the toggle on.** Android grants one
  /// prompt per app, so asking early spends it on a user who has not decided —
  /// and a refusal is then permanent for reasons the user never saw.
  ///
  /// Returns the resulting state rather than throwing on refusal: a refusal is
  /// a state the screen renders, not an error condition.
  Future<ReminderPermission> requestPermission();

  /// Enqueues the next reminder run for [time] (BR-226, BR-227).
  ///
  /// **Idempotent by contract.** Calling it twice with the same inputs leaves
  /// exactly one pending run, so bootstrap can reconcile on every launch
  /// without stacking runs — which is what BR-227 asks for and what makes the
  /// reconcile safe to call from anywhere.
  ///
  /// **`now` and [notBefore] are two different instants and the difference is
  /// load-bearing.** `now` is the wall clock, and the delay handed to the OS is
  /// measured from it — an inexact scheduler counts forward from the moment the
  /// work is enqueued, not from anything else. [notBefore] is the earliest
  /// instant the next occurrence may be chosen from, which BR-221 sometimes
  /// pushes past `now`: a run that slipped past local midnight has already
  /// served that day. Collapsing the two shortens the delay by exactly their
  /// gap, and the reminder then walks backwards through the day, a little
  /// further every night.
  ///
  /// [notBefore] defaults to `now` for every ordinary caller. Both are
  /// arguments for the reason they are everywhere else in this feature
  /// (AD-16): a scheduler that read the clock itself could not be tested
  /// across a timezone change.
  ///
  /// Throws a `Failure` carrying `ReminderSetupRejection.scheduleFailed` when
  /// the OS refuses the work.
  Future<void> schedule({
    required ReminderTime time,
    required DateTime now,
    required Duration utcOffset,
    DateTime? notBefore,
  });

  /// Removes any pending run and any reminder still on the shade (BR-226).
  ///
  /// Safe to call when nothing is scheduled — turning off a reminder that was
  /// never on must not fail.
  Future<void> cancel();

  /// Posts today's summary (BR-221, BR-222).
  ///
  /// Takes the model rather than two strings so the copy is built where the
  /// locale lives and cannot be assembled from anything BR-222 forbids.
  Future<void> showSummary(ReminderSummaryModel summary);
}
