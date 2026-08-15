/// The two windows Progress by Deck reports over (BR-194).
///
/// **Two, and fixed.** A free date picker turns every figure into "compared to
/// what?" and needs a second control before the first one has taught anybody
/// anything. Seven days is the week a person can still remember; thirty is the
/// habit. Anything between them says the same thing more slowly, and anything
/// longer needs a chart rather than a number.
///
/// The window is **whole local days ending with today** (BR-194): `last7Days`
/// covers today and the six days before it, so a person who studied this morning
/// sees today's work immediately rather than at the next midnight.
enum ProgressRange {
  last7Days(dayCount: 7),
  last30Days(dayCount: 30);

  const ProgressRange({required this.dayCount});

  /// How many whole local days the window spans, today included.
  final int dayCount;

  /// How many day boundaries back the window starts — `dayCount - 1`, because
  /// today is one of the days.
  ///
  /// Named rather than written as `-(range.dayCount - 1)` at the call site: the
  /// off-by-one is the entire difference between "the last seven days" and
  /// "the last eight", and it should be wrong in one place at most.
  int get daysBeforeToday => dayCount - 1;

  /// The window shown first (BR-194). The shorter one: it answers "am I keeping
  /// up" which is the question somebody opening a progress screen is asking.
  static const ProgressRange initial = last7Days;
}
