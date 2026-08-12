import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_impact_model.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

import 'deck_fixtures.dart';

// Re-exported so the fifteen tests that import this file for both the fake
// and the builders keep one import. The split is about file size, not about
// asking every caller to know where a helper moved to.
export 'deck_fixtures.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

/// A [DeckRepository] a presentation test can drive.
///
/// The builders that make plausible decks and summaries moved to
/// `deck_fixtures.dart` when this file crossed the size guard — a real seam:
/// this file answers "what does the screen's contract do", that one answers
/// "what does a deck look like".
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
/// **One read builder for every level.** The fake used to have a `summaries`
/// stream for the root list and a separate `deckDetail` stream for the inside of
/// a deck, which let a test set up a root list and a deck screen that disagreed
/// about the same deck. The contract has one method now, so the fake has one
/// builder, keyed on the parent id the screen asked for.
///
/// Writes record their arguments and return whatever the test asked for. That is
/// what lets a widget test assert "the form called `createRootDeck` with this
/// name and this scheduler" without a database, while the *behaviour* of those
/// writes is asserted against real SQLite in
/// `test/features/deck/data/`.
class FakeDeckRepository implements DeckRepository {
  FakeDeckRepository({
    Stream<DeckListSnapshot> Function(String? parentDeckId)? deckList,
    Stream<List<DeckEntity>> Function()? rootDecks,
    Stream<List<DeckEntity>> Function()? allDecks,
    this.deletionImpact = const DeckDeletionImpact(
      descendantDeckCount: 0,
      cardCount: 0,
    ),
    this.writeFailure,
  }) : _deckList = deckList ?? _emptyLevel,
       _rootDecks = rootDecks ?? _emptyDecks,
       _allDecks = allDecks ?? _emptyDecks;

  /// Emits [summaries] as the root level, with no due boundary by default.
  ///
  /// [nextDueAt] is the instant the counts expire. It is part of the same read as
  /// the counts in production, so it is one argument here too — a fake that let a
  /// test set the two independently would be a fake of a contract that does not
  /// exist.
  factory FakeDeckRepository.withSummaries(
    List<DeckSummary> summaries, {
    DateTime? nextDueAt,
  }) => FakeDeckRepository(
    deckList: (_) => Stream<DeckListSnapshot>.value(
      DeckListSnapshot(
        parent: null,
        ancestors: const <DeckPathSegment>[],
        decks: summaries,
        nextDueAt: nextDueAt,
        nextOverdueTickAt: null,
      ),
    ),
  );

  /// One level inside a deck: the parent, and what it directly contains.
  ///
  /// The same value type the root level uses, because it is the same screen —
  /// the only difference is that `parent` is not null.
  factory FakeDeckRepository.withLevel({
    required DeckEntity parent,
    List<DeckSummary> children = const <DeckSummary>[],
    List<DeckPathSegment> ancestors = const <DeckPathSegment>[],
    DateTime? nextDueAt,
  }) => FakeDeckRepository(
    deckList: (_) => Stream<DeckListSnapshot>.value(
      DeckListSnapshot(
        parent: parent,
        ancestors: ancestors,
        decks: children,
        nextDueAt: nextDueAt,
        nextOverdueTickAt: null,
      ),
    ),
  );

  /// A level that does not exist — the deck was deleted while it was open.
  factory FakeDeckRepository.missingDeck() => FakeDeckRepository(
    deckList: (_) => Stream<DeckListSnapshot>.error(
      const NotFoundFailure(message: 'That deck no longer exists.'),
    ),
  );

  /// Never emits and never closes: the state a real read is in while SQLite is
  /// still answering.
  factory FakeDeckRepository.pending() => FakeDeckRepository(
    deckList: (_) => StreamController<DeckListSnapshot>().stream,
  );

  /// Fails without ever emitting — a read that could not reach the database.
  factory FakeDeckRepository.failing(Object error) => FakeDeckRepository(
    deckList: (_) => Stream<DeckListSnapshot>.error(error),
  );

  static Stream<DeckListSnapshot> _emptyLevel(String? parentDeckId) =>
      Stream<DeckListSnapshot>.value(
        const DeckListSnapshot(
          parent: null,
          ancestors: <DeckPathSegment>[],
          decks: <DeckSummary>[],
          nextDueAt: null,
          nextOverdueTickAt: null,
        ),
      );

  static Stream<List<DeckEntity>> _emptyDecks() =>
      Stream<List<DeckEntity>>.value(const <DeckEntity>[]);

  final Stream<DeckListSnapshot> Function(String? parentDeckId) _deckList;
  final Stream<List<DeckEntity>> Function() _rootDecks;
  final Stream<List<DeckEntity>> Function() _allDecks;

  DeckDeletionImpact deletionImpact;

  /// When set, every write throws it. One switch rather than one per method:
  /// what the tests care about is "the write failed", and the state machine that
  /// handles it is the same for all six.
  Failure? writeFailure;

  /// Counts, not booleans: "did retry re-subscribe" and "did a double tap send
  /// two writes" are both questions about the number.
  int deckListCallCount = 0;

  /// Every parent id the list read was opened for, in order — `null` for the
  /// root level.
  final List<String?> deckListParents = <String?>[];

  /// Every `now` the list read was given, in order.
  ///
  /// The due boundary is the only reason the same query runs twice with different
  /// arguments, so this is what a test asserts against to show a re-measure
  /// actually happened at a new instant rather than just re-running.
  final List<DateTime> readInstants = <DateTime>[];
  int allDecksCallCount = 0;
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
  Stream<DeckListSnapshot> watchDeckList({
    required String? parentDeckId,
    required DateTime now,
    required Duration utcOffset,
  }) {
    deckListCallCount += 1;
    deckListParents.add(parentDeckId);
    readInstants.add(now);

    return _deckList(parentDeckId);
  }

  @override
  Stream<List<DeckEntity>> watchRootDecks() => _rootDecks();

  @override
  Stream<List<DeckEntity>> watchAllDecks() {
    allDecksCallCount += 1;

    return _allDecks();
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

  /// Every reset of learning progress this fake was asked for (UC-07).
  final List<({String rootDeckId, SchedulerType schedulerType})>
  progressResets = <({String rootDeckId, SchedulerType schedulerType})>[];

  @override
  Future<void> resetLearningProgress({
    required String rootDeckId,
    required SchedulerType schedulerType,
  }) async {
    progressResets.add((rootDeckId: rootDeckId, schedulerType: schedulerType));
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
