import 'package:memox/features/progress/domain/models/deck_activity_metrics_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';
import 'package:memox/features/progress/domain/models/progress_path_segment_model.dart';

/// What a Progress read looks like, as values.
///
/// **Beside the fake rather than inside it**, the same split `deck_fixtures.dart`
/// makes: the fake answers "what does the screen's contract do", this file
/// answers "what does a level look like". The split is what lets a *domain* test
/// build a snapshot without importing presentation test support — an import that
/// pointed the wrong way across the layers the production code keeps apart.

/// The instant every progress fixture is anchored to. A fixed value, never the
/// wall clock: a windowed metric is only right or wrong relative to a `now`.
final DateTime progressTestNow = DateTime.utc(2026, 8, 13, 9);

/// The next local midnight after [progressTestNow] at the harness's +07:00 —
/// the instant the repository really would put on a snapshot taken then.
///
/// Spelled out rather than left at a round UTC value: a fixture whose expiry
/// instant is one the production read could never emit is a fixture that agrees
/// with nothing.
final DateTime progressTestDayBoundary = DateTime.utc(2026, 8, 13, 17);

/// A level with no decks and nothing measured.
DeckActivitySnapshot emptyActivitySnapshot({
  String? scopeDeckId,
  String? scopeName,
}) => DeckActivitySnapshot(
  scopeDeckId: scopeDeckId,
  scopeName: scopeName,
  scopePath: const <ProgressPathSegment>[],
  decks: const <DeckActivity>[],
  scopeLast7Days: DeckActivityMetrics.zero,
  scopeLast30Days: DeckActivityMetrics.zero,
  nextDayBoundaryAt: progressTestDayBoundary,
);

/// Four figures for one window, with a short spelling for a test that only cares
/// about one of them.
DeckActivityMetrics activityMetrics({
  int activeCards = 0,
  int activeDays = 0,
  int learning = 0,
  int reviewing = 0,
}) => DeckActivityMetrics(
  activeCardCount: activeCards,
  activeDayCount: activeDays,
  learningCardDayCount: learning,
  reviewingCardDayCount: reviewing,
);

/// One deck row. The 30-day window defaults to the 7-day one, because most
/// tests care about a single window and two independent sets of figures would
/// be two things to keep in step for no reason.
DeckActivity deckActivity({
  required String deckId,
  required String name,
  DeckActivityMetrics? last7Days,
  DeckActivityMetrics? last30Days,
  List<ProgressPathSegment> path = const <ProgressPathSegment>[],
}) {
  final week = last7Days ?? DeckActivityMetrics.zero;

  return DeckActivity(
    deckId: deckId,
    name: name,
    path: path,
    last7Days: week,
    last30Days: last30Days ?? week,
  );
}

/// A level holding [decks], whose totals are stated rather than folded — the
/// same way production reads them, so a test cannot accidentally assert a fold
/// the production code does not do.
DeckActivitySnapshot activitySnapshot({
  required List<DeckActivity> decks,
  String? scopeDeckId,
  String? scopeName,
  List<ProgressPathSegment> scopePath = const <ProgressPathSegment>[],
  DeckActivityMetrics? scopeLast7Days,
  DeckActivityMetrics? scopeLast30Days,
  DateTime? nextDayBoundaryAt,
}) {
  final week = scopeLast7Days ?? DeckActivityMetrics.zero;

  return DeckActivitySnapshot(
    scopeDeckId: scopeDeckId,
    scopeName: scopeName,
    scopePath: scopePath,
    decks: decks,
    scopeLast7Days: week,
    scopeLast30Days: scopeLast30Days ?? week,
    nextDayBoundaryAt: nextDayBoundaryAt ?? progressTestDayBoundary,
  );
}
