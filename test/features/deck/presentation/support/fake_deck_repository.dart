import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_impact_model.dart';
import 'package:memox/features/deck/domain/models/deck_detail_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/deck/domain/models/root_deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/root_deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

/// A [DeckRepository] a presentation test can drive.
///
/// **A fake of the domain contract, not of the DAO.** Mocking `DeckDao` here
/// would tie every screen test to the shape of the Drift row, which is the
/// coupling AD-01 exists to prevent — and it would make these tests pass on a
/// repository that maps rows wrongly. What the screen is entitled to know is
/// this contract; that is therefore what the test replaces.
///
/// Reads are supplied as *builders*, not values. A single-subscription stream can
/// only be listened to once, so a stored `Stream.value(...)` would throw on the
/// second listen — which is exactly what retry and a family provider rebuild do.
///
/// Writes record their arguments and return whatever the test asked for. That is
/// what lets a widget test assert "the form called `createRootDeck` with this
/// name and this scheduler" without a database, while the *behaviour* of those
/// writes is asserted against real SQLite in
/// `test/features/deck/data/`.
class FakeDeckRepository implements DeckRepository {
  FakeDeckRepository({
    Stream<RootDeckListSnapshot> Function()? summaries,
    Stream<List<DeckEntity>> Function()? rootDecks,
    Stream<List<DeckEntity>> Function()? allDecks,
    Stream<DeckDetail> Function(String deckId)? deckDetail,
    this.deletionImpact = const DeckDeletionImpact(
      descendantDeckCount: 0,
      cardCount: 0,
    ),
    this.writeFailure,
  }) : _summaries = summaries ?? _emptySummaries,
       _rootDecks = rootDecks ?? _emptyDecks,
       _allDecks = allDecks ?? _emptyDecks,
       _deckDetail = deckDetail ?? _missingDeck;

  /// Emits [summaries] as the deck list, with no due boundary by default.
  ///
  /// [nextDueAt] is the instant the counts expire. It is part of the same read as
  /// the counts in production, so it is one argument here too — a fake that let a
  /// test set the two independently would be a fake of a contract that does not
  /// exist.
  factory FakeDeckRepository.withSummaries(
    List<RootDeckSummary> summaries, {
    DateTime? nextDueAt,
  }) => FakeDeckRepository(
    summaries: () => Stream<RootDeckListSnapshot>.value(
      RootDeckListSnapshot(decks: summaries, nextDueAt: nextDueAt),
    ),
  );

  /// Never emits and never closes: the state a real read is in while SQLite is
  /// still answering.
  factory FakeDeckRepository.pending() => FakeDeckRepository(
    summaries: () => StreamController<RootDeckListSnapshot>().stream,
    deckDetail: (_) => StreamController<DeckDetail>().stream,
  );

  /// Fails without ever emitting — a read that could not reach the database.
  factory FakeDeckRepository.failing(Object error) => FakeDeckRepository(
    summaries: () => Stream<RootDeckListSnapshot>.error(error),
    deckDetail: (_) => Stream<DeckDetail>.error(error),
  );

  /// A deck screen's read, supplied as the pair the real read returns together.
  ///
  /// One builder for both facts, because the contract has one method for both.
  /// The old fake had a `childDecks` stream and a separate `deckById` future, and
  /// a test could therefore set up a state the database cannot produce — a deck
  /// whose children belong to a different snapshot. That is no longer expressible.
  factory FakeDeckRepository.withDetail({
    required DeckEntity deck,
    List<DeckEntity> children = const <DeckEntity>[],
  }) => FakeDeckRepository(
    deckDetail: (_) =>
        Stream<DeckDetail>.value(DeckDetail(deck: deck, childDecks: children)),
  );

  static Stream<RootDeckListSnapshot> _emptySummaries() =>
      Stream<RootDeckListSnapshot>.value(
        const RootDeckListSnapshot(decks: <RootDeckSummary>[], nextDueAt: null),
      );

  static Stream<List<DeckEntity>> _emptyDecks() =>
      Stream<List<DeckEntity>>.value(const <DeckEntity>[]);

  static Stream<DeckDetail> _missingDeck(String deckId) =>
      Stream<DeckDetail>.error(
        const NotFoundFailure(message: 'That deck no longer exists.'),
      );

  final Stream<RootDeckListSnapshot> Function() _summaries;
  final Stream<List<DeckEntity>> Function() _rootDecks;
  final Stream<List<DeckEntity>> Function() _allDecks;
  final Stream<DeckDetail> Function(String deckId) _deckDetail;

  DeckDeletionImpact deletionImpact;

  /// When set, every write throws it. One switch rather than one per method:
  /// what the tests care about is "the write failed", and the state machine that
  /// handles it is the same for all six.
  Failure? writeFailure;

  /// Counts, not booleans: "did retry re-subscribe" and "did a double tap send
  /// two writes" are both questions about the number.
  int summariesCallCount = 0;

  /// Every `now` the list read was given, in order.
  ///
  /// The due boundary is the only reason the same query runs twice with different
  /// arguments, so this is what a test asserts against to show a re-measure
  /// actually happened at a new instant rather than just re-running.
  final List<DateTime> readInstants = <DateTime>[];
  int allDecksCallCount = 0;
  final List<String> deckDetailCalls = <String>[];
  final List<({String name, SchedulerType scheduler})> createdRootDecks =
      <({String name, SchedulerType scheduler})>[];
  final List<({String name, String parentDeckId})> createdSubDecks =
      <({String name, String parentDeckId})>[];
  final List<({String deckId, String name})> renames =
      <({String deckId, String name})>[];
  final List<String> deletes = <String>[];
  final List<String> resets = <String>[];
  final List<({String deckId, String target})> moves =
      <({String deckId, String target})>[];

  @override
  Stream<RootDeckListSnapshot> watchRootDeckList({required DateTime now}) {
    summariesCallCount += 1;
    readInstants.add(now);

    return _summaries();
  }

  @override
  Stream<List<DeckEntity>> watchRootDecks() => _rootDecks();

  @override
  Stream<List<DeckEntity>> watchAllDecks() {
    allDecksCallCount += 1;

    return _allDecks();
  }

  @override
  Stream<DeckDetail> watchDeckDetail(String deckId) {
    deckDetailCalls.add(deckId);

    return _deckDetail(deckId);
  }

  @override
  Stream<List<DeckEntity>> watchDeckTree(String rootDeckId) => _allDecks();

  @override
  Future<DeckDeletionImpact> getDeletionImpact(String deckId) async {
    final failure = writeFailure;
    if (failure != null) throw failure;

    return deletionImpact;
  }

  @override
  Future<DeckEntity> createRootDeck({
    required DeckName name,
    required SchedulerType schedulerType,
  }) async {
    // Recorded as the normalised string, which is what the repository would
    // persist — so a test asserting `createdRootDecks.single.name` is asserting
    // that trim happened exactly once, upstream, and reached here already applied.
    createdRootDecks.add((name: name.value, scheduler: schedulerType));
    final failure = writeFailure;
    if (failure != null) throw failure;

    return fakeRootDeck(id: 'created-root', name: name.value);
  }

  @override
  Future<DeckEntity> createSubDeck({
    required DeckName name,
    required String parentDeckId,
  }) async {
    createdSubDecks.add((name: name.value, parentDeckId: parentDeckId));
    final failure = writeFailure;
    if (failure != null) throw failure;

    return fakeSubDeck(
      id: 'created-sub',
      name: name.value,
      parentId: parentDeckId,
    );
  }

  @override
  Future<void> renameDeck({
    required String deckId,
    required DeckName name,
  }) async {
    renames.add((deckId: deckId, name: name.value));
    final failure = writeFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> deleteDeck(String deckId) async {
    deletes.add(deckId);
    final failure = writeFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> resetContentType(String deckId) async {
    resets.add(deckId);
    final failure = writeFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> moveDeck({
    required String deckId,
    required String targetParentDeckId,
  }) async {
    moves.add((deckId: deckId, target: targetParentDeckId));
    final failure = writeFailure;
    if (failure != null) throw failure;
  }
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
  int schedulerGeneration = 1,
  DateTime? createdAt,
}) {
  final at = createdAt ?? DateTime.utc(2026);

  return DeckEntity(
    id: id,
    name: name,
    parentDeckId: null,
    rootDeckId: id,
    contentType: DeckContentType.deck,
    schedulerType: schedulerType,
    schedulerGeneration: schedulerGeneration,
    firstReviewAt: null,
    createdAt: at,
    updatedAt: at,
  );
}

/// A sub-deck. Scheduler columns are null, as BR-06 requires of anything that is
/// not a root.
DeckEntity fakeSubDeck({
  required String id,
  required String name,
  required String parentId,
  String? rootId,
  DeckContentType contentType = DeckContentType.unset,
  DateTime? createdAt,
}) {
  final at = createdAt ?? DateTime.utc(2026);

  return DeckEntity(
    id: id,
    name: name,
    parentDeckId: parentId,
    rootDeckId: rootId ?? parentId,
    contentType: contentType,
    schedulerType: null,
    schedulerGeneration: null,
    firstReviewAt: null,
    createdAt: at,
    updatedAt: at,
  );
}

/// The list read's snapshot, for a test that drives the stream directly.
///
/// [nextDueAt] defaults to null — nothing scheduled to come due — because that is
/// what most tests are about. The ones about the due-boundary timer pass it.
RootDeckListSnapshot fakeListSnapshot(
  List<RootDeckSummary> summaries, {
  DateTime? nextDueAt,
}) => RootDeckListSnapshot(decks: summaries, nextDueAt: nextDueAt);

/// A root summary with explicit counts.
RootDeckSummary fakeSummary({
  required String id,
  required String name,
  int totalCardCount = 0,
  int dueCardCount = 0,
  SchedulerType schedulerType = SchedulerType.eightBox,
}) => RootDeckSummary(
  deck: fakeRootDeck(id: id, name: name, schedulerType: schedulerType),
  totalCardCount: totalCardCount,
  dueCardCount: dueCardCount,
);
