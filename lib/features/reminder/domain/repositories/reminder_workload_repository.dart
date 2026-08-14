import '../models/reminder_workload_model.dart';

/// What is owed right now, per root deck (BR-184, BR-188).
///
/// **Read-only, and the contract says so by having no other method.** A
/// reminder observes the schedule; it never advances one. BR-189's "dismiss
/// changes nothing" is easy to keep when the only thing this feature can reach
/// is a `SELECT`.
abstract interface class ReminderWorkloadRepository {
  /// The due workload as of [now], grouped by root deck.
  ///
  /// **Both time inputs are arguments** (AD-16, AD-06). `now` decides which
  /// cards have come due and [utcOffset] decides where the local day starts,
  /// which is what separates "overdue" from "due today" (BR-161). A repository
  /// that read either itself could not be tested at the boundary where a card
  /// becomes one day overdue with no write in between.
  ///
  /// Decks owing nothing are absent rather than present with zeroes.
  Future<List<ReminderWorkloadModel>> readWorkload({
    required DateTime now,
    required Duration utcOffset,
  });
}
