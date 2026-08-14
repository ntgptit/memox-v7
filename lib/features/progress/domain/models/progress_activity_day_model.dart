import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_activity_day_model.freezed.dart';

/// One local day on which the user answered at least one card (BR-182).
///
/// **The unit is a card-day, not an answer.** A `learning` session walks five
/// stages over the same card and writes a row per turn (BR-98, BR-113), so
/// counting `study_answers` rows would tell a user who studied one card that
/// they studied six. Every count here is a number of **distinct cards** touched
/// on this local day; the same card answered ten times is one, and the same card
/// answered on two days is two.
///
/// **Only days with activity exist as instances.** A day with nothing on it is
/// not a `ProgressActivityDay` carrying zeros — it is a day the repository never
/// produced. `ProgressOverview` zero-fills the seven-day window (BR-186), and it
/// is the only place allowed to: an empty day invented here would also be
/// indistinguishable from a real day of zeros, which cannot exist.
@freezed
abstract class ProgressActivityDay with _$ProgressActivityDay {
  const factory ProgressActivityDay({
    /// The local calendar date, as a **UTC** `DateTime` at midnight.
    ///
    /// A calendar date, not an instant. `DateTime.utc(2026, 8, 13)` here means
    /// "13 August in the user's local zone", and it is UTC-flagged only so that
    /// `==`, `Set` membership and `subtract(Duration(days: 1))` are exact —
    /// building it as a local `DateTime` would make the value depend on the
    /// host's zone, which in a test is whatever machine ran it. That is the
    /// same reasoning `LocalDayModel` states for its own arithmetic.
    required DateTime localDate,

    /// Distinct cards answered on [localDate] (BR-182).
    required int totalCards,

    /// Of those, how many had at least one `learning` answer (BR-185).
    ///
    /// Learning wins the tie by rule: a card that was both finished off the
    /// learning chain and reviewed on the same day counts once, as Learning.
    /// [reviewingCards] is therefore the remainder rather than a second count,
    /// which is what makes `learning + reviewing == total` true by construction
    /// instead of true by agreement between two SQL expressions.
    required int learningCards,
  }) = _ProgressActivityDay;

  const ProgressActivityDay._();

  /// Distinct cards whose only answers that day were `scheduled` or
  /// `relearning` (BR-185).
  int get reviewingCards => totalCards - learningCards;

  /// Whether this day counts towards a streak (BR-187).
  ///
  /// Always true for an instance the repository produced — a day with no card
  /// is not emitted at all. It exists for the zero-filled days
  /// [ProgressOverview] creates, where the answer is what the caller is asking.
  bool get isActive => totalCards > 0;
}
