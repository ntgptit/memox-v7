import 'dart:async';

import 'package:memox/features/progress/domain/models/progress_activity_day_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';

/// A `ProgressRepository` a widget or controller test drives by hand.
///
/// **It records the arguments and replays what the test pushes**, rather than
/// aggregating anything. The aggregation is tested against a real SQLite
/// database in `test/features/progress/data/`, and the streak and zero-fill
/// against pure Dart in `test/features/progress/domain/`; a double that repeated
/// either would only ever agree with itself.
///
/// The stream is a broadcast controller so a test can emit again after the
/// screen has settled — that is how live refresh (A3) and a midnight rollover
/// (A4) are exercised without a database.
base class FakeProgressRepository implements ProgressRepository {
  FakeProgressRepository({ProgressOverview? initial}) {
    if (initial != null) _pending = initial;
  }

  final StreamController<ProgressOverview> _controller =
      StreamController<ProgressOverview>.broadcast();

  /// Emitted to each new subscriber, so a screen that rebuilds its provider
  /// sees the current state rather than an empty stream.
  ProgressOverview? _pending;

  /// Every `(now, utcOffset)` pair the screen has asked for, in order.
  ///
  /// A midnight rollover is observable here and nowhere else: it is the same
  /// query re-opened at a later `now`, so a test that only watched the emissions
  /// could not tell a rollover from an ordinary re-emission.
  final List<({DateTime now, Duration utcOffset})> reads =
      <({DateTime now, Duration utcOffset})>[];

  /// How many times the screen subscribed.
  int get subscriptionCount => reads.length;

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

  /// Pushes a new snapshot to whoever is listening (A3).
  void emit(ProgressOverview overview) {
    _pending = overview;
    _controller.add(overview);
  }

  /// Fails the stream, for the error face (E1).
  void fail(Object error) => _controller.addError(error);

  Future<void> dispose() => _controller.close();
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
