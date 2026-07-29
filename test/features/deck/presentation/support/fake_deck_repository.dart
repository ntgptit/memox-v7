import 'dart:async';

import 'package:memox/features/deck/domain/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/deck_entity.dart';
import 'package:memox/features/deck/domain/deck_repository.dart';
import 'package:memox/features/deck/domain/scheduler_type_model.dart';

/// A [DeckRepository] a presentation test can drive.
///
/// **A fake of the domain contract, not of the DAO.** Mocking `DeckDao` here
/// would tie every screen test to the shape of the Drift row, which is the
/// coupling AD-01 exists to prevent — and it would make these tests pass on a
/// repository that maps rows wrongly. What the screen is entitled to know is
/// this contract; that is therefore what the test replaces.
///
/// The stream is supplied as a *builder*, not as a value. A single-subscription
/// stream can only be listened to once, so a stored `Stream.value(...)` would
/// throw on the second listen — which is exactly what retry does, and the case
/// most worth testing.
class FakeDeckRepository implements DeckRepository {
  FakeDeckRepository(this._buildRootDecks);

  /// Emits [decks] once and closes.
  factory FakeDeckRepository.emitting(List<DeckEntity> decks) =>
      FakeDeckRepository(() => Stream<List<DeckEntity>>.value(decks));

  /// Fails without ever emitting — a read that could not reach the database.
  factory FakeDeckRepository.failing(Object error) =>
      FakeDeckRepository(() => Stream<List<DeckEntity>>.error(error));

  /// Never emits and never closes: the state a real read is in while SQLite is
  /// still answering.
  factory FakeDeckRepository.pending() =>
      FakeDeckRepository(() => StreamController<List<DeckEntity>>().stream);

  final Stream<List<DeckEntity>> Function() _buildRootDecks;

  /// How many times the stream has been asked for.
  ///
  /// The number, not a boolean: "did retry actually re-subscribe" and "does one
  /// screen subscribe twice per build" are both questions about the count, and
  /// a flag answers neither.
  int watchRootDecksCallCount = 0;

  @override
  Stream<List<DeckEntity>> watchRootDecks() {
    watchRootDecksCallCount += 1;

    return _buildRootDecks();
  }

  /// Every other method of the contract is out of this slice. Throwing names
  /// the call instead of returning an empty default, which would let a screen
  /// silently depend on behaviour nobody wrote.
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} is not part of the root deck list slice.',
  );
}

/// A root deck with plausible values, so a test states only what it cares about.
///
/// The timestamps are a fixed instant rather than the wall clock: a test that
/// depends on when it runs is the classic suite that fails once a month at
/// midnight.
DeckEntity fakeRootDeck({
  required String id,
  required String name,
  SchedulerType schedulerType = SchedulerType.eightBox,
}) {
  final at = DateTime.utc(2026);

  return DeckEntity(
    id: id,
    name: name,
    parentDeckId: null,
    rootDeckId: id,
    contentType: DeckContentType.deck,
    schedulerType: schedulerType,
    schedulerGeneration: 1,
    firstReviewAt: null,
    createdAt: at,
    updatedAt: at,
  );
}
