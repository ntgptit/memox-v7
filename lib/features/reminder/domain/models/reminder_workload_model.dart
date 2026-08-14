/// One root deck's share of the work a reminder may talk about (BR-188).
///
/// **One row per root, and a card belongs to exactly one root.** The aggregation
/// resolves through `root_deck_id` (BR-57), so nothing here can double count a
/// card via an ancestor and a descendant of the deck that holds it — the shape
/// of this model is what makes that impossible rather than merely avoided.
///
/// **`overdueDayCount` is already in local day boundaries.** It arrives computed
/// from the oldest overdue `due_at` through `LocalDayModel` (BR-161), because
/// the ranking in BR-187 needs calendar days and this layer may not read a clock
/// (AD-16). A card due at 23:00 yesterday is one day overdue at 01:00 today, and
/// `difference().inHours ~/ 24` says zero.
final class ReminderWorkloadModel {
  const ReminderWorkloadModel({
    required this.deckId,
    required this.deckName,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.overdueDayCount,
  });

  /// The root deck's id — the last tie-break of BR-187's ordering.
  final String deckId;

  /// The root deck's name, which the notification MAY show (BR-186).
  final String deckName;

  /// Cards whose `due_at` fell before the start of the current local day.
  final int overdueCount;

  /// Cards that came due today, up to the moment of evaluation.
  final int dueTodayCount;

  /// Completed local day boundaries since the oldest overdue card came due.
  ///
  /// Zero when nothing is overdue, which is also what BR-187 wants: a deck with
  /// no overdue cards ranks below one that has them, and its age never breaks
  /// the tie in its favour.
  final int overdueDayCount;

  /// Everything this deck owes right now (BR-184).
  int get dueCount => overdueCount + dueTodayCount;

  @override
  bool operator ==(Object other) =>
      other is ReminderWorkloadModel &&
      other.deckId == deckId &&
      other.deckName == deckName &&
      other.overdueCount == overdueCount &&
      other.dueTodayCount == dueTodayCount &&
      other.overdueDayCount == overdueDayCount;

  @override
  int get hashCode =>
      Object.hash(deckId, deckName, overdueCount, dueTodayCount, overdueDayCount);
}
