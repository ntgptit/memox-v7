import 'dart:async';

import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';
import 'package:memox/features/progress/domain/models/progress_activity_day_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';

import '../../support/progress_fixtures.dart';

// Re-exported so the tests that reach here for both the fake and the value
// builders keep one import. The split is about which layer may see what, not
// about asking every caller to know where a helper moved to.
export '../../support/progress_fixtures.dart';

/// A `ProgressRepository` a widget or controller test drives by hand.
///
/// **It records the arguments and replays what the test pushes**, rather than
/// aggregating anything. The aggregation is tested against a real SQLite
/// database in `test/features/progress/data/`, and the streak and zero-fill
/// against pure Dart in `test/features/progress/domain/`; a double that repeated
/// either would only ever agree with itself.
///
/// **One fake for both reads, because the contract is one interface.** The two
/// halves of Progress arrived as separate features and each wrote its own
/// double; keeping both would mean a screen that shows the overview above the
/// deck level needs two fakes to stand up, and the day the interface grows a
/// third method only one of them would be updated.
///
/// They are driven differently on purpose, because they are asked differently.
/// The overview arrives on a broadcast controller a test pushes to — that is how
/// live refresh (A3) and a midnight rollover (A4) are exercised without a
/// database. The level arrives from a function the test supplies, keyed by
/// `deckId`, because what a level test varies is which level answers what.
///
/// **The two recording lists are deliberately not one.** `reads` is the
/// overview's and `levelReads` is the level's, so an assertion always says which
/// question it is about; one list would make "the screen re-read" ambiguous
/// exactly where these tests care most.
base class FakeProgressRepository implements ProgressRepository {
  FakeProgressRepository({
    ProgressOverview? initial,
    Stream<DeckActivitySnapshot> Function(String? deckId)? activity,
  }) : _activity = activity ?? _defaultLevel {
    if (initial != null) _pending = initial;
  }

  /// Emits one fixed snapshot at every level.
  ///
  /// **The overview answers too, and that is not incidental.** `/progress` is
  /// one screen: the level renders under the overview's three sections, so a
  /// double that answered only the level read would leave the tab on its
  /// spinner forever — `pumpAndSettle` then times out on a `CircularProgressIndicator`
  /// rather than failing on the thing the test is about. [overview] overrides
  /// the default for a test whose subject is the header.
  factory FakeProgressRepository.withSnapshot(
    DeckActivitySnapshot snapshot, {
    ProgressOverview? overview,
  }) => FakeProgressRepository(
    initial: overview ?? _defaultOverview(),
    activity: (String? deckId) => Stream<DeckActivitySnapshot>.value(snapshot),
  );

  /// Fails every level read, for the level's error face.
  ///
  /// The overview still succeeds: a level that fails under a header that
  /// loaded is the real shape of that failure, and failing both would test two
  /// error faces at once.
  factory FakeProgressRepository.failing(Object error) =>
      FakeProgressRepository(
        initial: _defaultOverview(),
        activity: (String? deckId) => Stream<DeckActivitySnapshot>.error(error),
      );

  /// Enough history that the composed screen takes its loaded branch.
  static ProgressOverview _defaultOverview() => progressOverviewFixture(
    totals: const <int>[1, 0, 2, 0, 3, 0, 4],
    streakDays: 1,
  );

  final StreamController<ProgressOverview> _controller =
      StreamController<ProgressOverview>.broadcast();

  final Stream<DeckActivitySnapshot> Function(String? deckId) _activity;

  /// Emitted to each new subscriber, so a screen that rebuilds its provider
  /// sees the current state rather than an empty stream.
  ProgressOverview? _pending;

  /// Every `(now, utcOffset)` pair the **overview** has been asked for, in order.
  ///
  /// A midnight rollover is observable here and nowhere else: it is the same
  /// query re-opened at a later `now`, so a test that only watched the emissions
  /// could not tell a rollover from an ordinary re-emission.
  final List<({DateTime now, Duration utcOffset})> reads =
      <({DateTime now, Duration utcOffset})>[];

  /// Every `(deckId, now, utcOffset)` triple the **level** has been asked for.
  final List<({String? deckId, DateTime now, Duration utcOffset})> levelReads =
      <({String? deckId, DateTime now, Duration utcOffset})>[];

  /// How many times the overview was subscribed to.
  int get subscriptionCount => reads.length;

  /// How many times a level was subscribed to.
  int get levelReadCount => levelReads.length;

  @override
  Stream<ProgressOverview> watchProgressOverview({
    required DateTime now,
    required Duration utcOffset,
  }) async* {
    // Recorded on subscription rather than on call, because `async*` is lazy
    // and that is also the honest moment: a provider that builds a stream and
    // never listens has not read anything.
    reads.add((now: now, utcOffset: utcOffset));

    final ProgressOverview? seed = _pending;
    if (seed != null) yield seed;
    yield* _controller.stream;
  }

  @override
  Stream<DeckActivitySnapshot> watchDeckActivity({
    required String? deckId,
    required DateTime now,
    required Duration utcOffset,
  }) {
    levelReads.add((deckId: deckId, now: now, utcOffset: utcOffset));

    return _activity(deckId);
  }

  /// Pushes a new overview snapshot to whoever is listening (A3).
  void emit(ProgressOverview overview) {
    _pending = overview;
    _controller.add(overview);
  }

  /// Fails the overview stream, for the error face (E1).
  void fail(Object error) => _controller.addError(error);

  Future<void> dispose() => _controller.close();

  /// The level every test gets unless it says otherwise: the **composed**
  /// library level, one deck row under a real summary panel.
  ///
  /// **Not an empty level, and the difference is the whole screen.** An empty
  /// top level takes `_hasNothingToMeasure`, which drops the pinned range
  /// selector, the totals panel and the list — so a suite that defaulted to it
  /// pinned geometry, overflow sweeps and the visual audit against a face the
  /// user cannot reach. **Cannot, by rule rather than by assertion:** deleting
  /// a deck cascades its cards, and a card's `study_answers` rows go with it
  /// (BR-03, BR-198), so a library with no decks has no lifetime activity —
  /// and `/progress` then takes the whole-screen empty face, never the level's.
  /// Every default-fake test now measures the screen a user opens. A test whose
  /// subject *is* the empty level passes `emptyActivitySnapshot()` explicitly.
  static Stream<DeckActivitySnapshot> _defaultLevel(String? deckId) =>
      Stream<DeckActivitySnapshot>.value(
        activitySnapshot(
          scopeLast7Days: activityMetrics(
            activeCards: 12,
            activeDays: 4,
            learning: 3,
            reviewing: 9,
          ),
          decks: <DeckActivity>[
            deckActivity(
              deckId: 'deck-default',
              name: 'Spanish',
              last7Days: activityMetrics(
                activeCards: 12,
                activeDays: 4,
                learning: 3,
                reviewing: 9,
              ),
            ),
          ],
        ),
      );
}

/// A snapshot built from seven day totals, so a test states the week it means
/// rather than seven constructor calls.
///
/// [totals] is oldest first, today last — the order BR-186 fixes. [learning] is
/// per day and defaults to zero, which makes every card-day a Reviewing one.
ProgressOverview progressOverviewFixture({
  required List<int> totals,
  required int streakDays,
  DateTime? today,
  List<int>? learning,
  bool? hasLifetimeActivity,
}) {
  final DateTime lastDay = today ?? DateTime.utc(2026, 8, 12);

  return ProgressOverview(
    lastSevenDays: <ProgressActivityDay>[
      for (final (int index, int total) in totals.indexed)
        ProgressActivityDay(
          localDate: lastDay.subtract(
            Duration(days: totals.length - 1 - index),
          ),
          totalCards: total,
          learningCards: learning?[index] ?? 0,
        ),
    ],
    currentStreakDays: streakDays,
    hasLifetimeActivity:
        hasLifetimeActivity ?? totals.any((int total) => total > 0),
    nextLocalMidnight: lastDay.add(const Duration(days: 1)),
  );
}
