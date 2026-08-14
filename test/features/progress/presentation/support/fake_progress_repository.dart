import 'dart:async';

import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';

import '../../support/progress_fixtures.dart';

// Re-exported so the tests that reach here for both the fake and the value
// builders keep one import. The split is about which layer may see what, not
// about asking every caller to know where a helper moved to.
export '../../support/progress_fixtures.dart';

/// A [ProgressRepository] a presentation test can drive.
///
/// **A fake of the domain contract, not of the DAO.** Faking `ProgressDao` here
/// would tie every screen test to the shape of the Drift result row — the
/// coupling AD-01 exists to prevent — and would let these tests pass against a
/// repository that maps rows wrongly. What a screen is entitled to know is this
/// contract, so that is what the test replaces. The *behaviour* of the read is
/// asserted against real SQLite in `test/features/progress/data/`.
///
/// Reads are supplied as a **builder**, not a value: a single-subscription
/// stream can only be listened to once, so a stored `Stream.value(...)` would
/// throw on the second listen — which is exactly what a retry and a family
/// rebuild do.
///
/// [now] and [utcOffset] arrive on every call and are recorded, because "the
/// caller decides which instant the windows are measured against" is part of the
/// contract and a fake that dropped them could not hold anyone to it.
class FakeProgressRepository implements ProgressRepository {
  FakeProgressRepository({
    Stream<DeckActivitySnapshot> Function(String? deckId)? activity,
  }) : _activity = activity ?? _emptyLevel;

  /// Emits one fixed snapshot at every level.
  factory FakeProgressRepository.withSnapshot(DeckActivitySnapshot snapshot) =>
      FakeProgressRepository(
        activity: (String? deckId) =>
            Stream<DeckActivitySnapshot>.value(snapshot),
      );

  /// Fails every read with [error].
  factory FakeProgressRepository.failing(Object error) =>
      FakeProgressRepository(
        activity: (String? deckId) => Stream<DeckActivitySnapshot>.error(error),
      );

  final Stream<DeckActivitySnapshot> Function(String? deckId) _activity;

  /// Every `(deckId, now, utcOffset)` the screen asked for, oldest first.
  final List<({String? deckId, DateTime now, Duration utcOffset})> reads =
      <({String? deckId, DateTime now, Duration utcOffset})>[];

  /// How many times the read was opened — the measurement that tells one
  /// subscription apart from a screen re-reading on every rebuild.
  int get readCount => reads.length;

  @override
  Stream<DeckActivitySnapshot> watchDeckActivity({
    required String? deckId,
    required DateTime now,
    required Duration utcOffset,
  }) {
    reads.add((deckId: deckId, now: now, utcOffset: utcOffset));

    return _activity(deckId);
  }

  static Stream<DeckActivitySnapshot> _emptyLevel(String? deckId) =>
      Stream<DeckActivitySnapshot>.value(emptyActivitySnapshot());
}
