import 'reminder_workload_model.dart';

/// Everything a daily reminder is allowed to say (BR-186).
///
/// **Three numbers and one deck name, and nothing else can get in.** The
/// notification adapter takes this model, not a list of decks and not a card —
/// so "the copy cannot contain card content" is a property of the type rather
/// than a rule somebody has to keep in mind while writing a string. A tag, an
/// example or a review history has no field to travel in.
///
/// **`null` is the whole of "say nothing".** [build] returns no summary when
/// nothing is due, which is BR-184's skip expressed as a value the caller has to
/// handle: there is no empty summary that could be shown by accident.
final class ReminderSummaryModel {
  const ReminderSummaryModel._({
    required this.totalDueCount,
    required this.leadDeckName,
    required this.otherDeckCount,
  });

  /// Cards owed across every root deck, counted once each (BR-188).
  final int totalDueCount;

  /// The name of the most urgent root deck, by BR-187's ordering.
  final String leadDeckName;

  /// How many other root decks also owe something. Zero means only one deck.
  final int otherDeckCount;

  /// Builds the summary from the workload, or returns `null` when nothing is
  /// due (BR-184).
  ///
  /// **Pure, and that is the point.** Every input is a value: no clock, no
  /// database, no locale. The ranking in BR-187 is therefore a function that can
  /// be tested against its own tie-break table, rather than an ordering that has
  /// to be inferred from what a query happened to return.
  ///
  /// Decks owing nothing are dropped before ranking. A deck can arrive with a
  /// zero total only if the caller passed one — the query cannot produce it —
  /// and ranking it would let an empty deck become the lead name.
  static ReminderSummaryModel? build(List<ReminderWorkloadModel> workloads) {
    final owing = workloads.where((deck) => deck.dueCount > 0).toList();
    if (owing.isEmpty) return null;

    owing.sort(compareUrgency);
    final total = owing.fold<int>(0, (sum, deck) => sum + deck.dueCount);

    return ReminderSummaryModel._(
      totalDueCount: total,
      leadDeckName: owing.first.deckName,
      otherDeckCount: owing.length - 1,
    );
  }

  /// BR-187's ordering, as a total order with no unresolved tie.
  ///
  /// Overdue count, then overdue age, then due-today count — all descending,
  /// because more and older is more urgent — and then name and id ascending, so
  /// two decks with identical numbers still have one answer. The last two steps
  /// are what stop the lead deck changing between two evaluations of the same
  /// data: without them the order is whatever the query planner chose.
  static int compareUrgency(ReminderWorkloadModel a, ReminderWorkloadModel b) {
    final byOverdue = b.overdueCount.compareTo(a.overdueCount);
    if (byOverdue != 0) return byOverdue;

    final byAge = b.overdueDayCount.compareTo(a.overdueDayCount);
    if (byAge != 0) return byAge;

    final byDueToday = b.dueTodayCount.compareTo(a.dueTodayCount);
    if (byDueToday != 0) return byDueToday;

    final byName = a.deckName.compareTo(b.deckName);
    if (byName != 0) return byName;

    return a.deckId.compareTo(b.deckId);
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderSummaryModel &&
      other.totalDueCount == totalDueCount &&
      other.leadDeckName == leadDeckName &&
      other.otherDeckCount == otherDeckCount;

  @override
  int get hashCode => Object.hash(totalDueCount, leadDeckName, otherDeckCount);
}
