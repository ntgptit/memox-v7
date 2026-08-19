import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/trash/domain/entities/trash_batch_entity.dart';
import 'package:memox/features/trash/domain/models/trash_item_type_model.dart';
import 'package:memox/features/trash/domain/models/trash_restore_target_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

/// A `TrashRepository` a screen test drives by hand.
///
/// **It records arguments rather than simulating a database.** Every rule the
/// real one enforces is tested against real SQLite in `test/features/trash/data`;
/// repeating it here would test the double. These tests are about what the
/// screen asks for and what it draws when the answer arrives.
final class FakeTrashRepository implements TrashRepository {
  FakeTrashRepository({
    List<TrashBatchEntity> batches = const <TrashBatchEntity>[],
    this.targets = const <TrashRestoreTarget>[],
  }) : _latest = batches;

  final StreamController<List<TrashBatchEntity>> _batches =
      StreamController<List<TrashBatchEntity>>.broadcast();

  /// **Replayed to each subscriber, because the real stream is a `watch()`.**
  /// A broadcast controller drops what it is given before anyone listens, and a
  /// screen that never receives a first emission sits in its loading state
  /// forever — which looks exactly like a hung query rather than like a fake
  /// that spoke too early.
  List<TrashBatchEntity> _latest;

  List<TrashRestoreTarget> targets;

  /// When set, the next write throws it — the error paths of UC-21.
  Failure? nextFailure;

  final List<({String batchId, TrashRestoreTarget target})> restores =
      <({String batchId, TrashRestoreTarget target})>[];
  final List<String> undos = <String>[];
  final List<List<String>> purges = <List<String>>[];

  /// How many sweeps ran, which is what BR-264's "before the list is shown"
  /// costs — and what proves it happened at all.
  int sweeps = 0;

  void emit(List<TrashBatchEntity> batches) {
    _latest = batches;
    _batches.add(batches);
  }

  Future<void> dispose() => _batches.close();

  @override
  Stream<List<TrashBatchEntity>> watchBatches() async* {
    yield _latest;
    yield* _batches.stream;
  }

  @override
  Future<TrashBatchEntity> batch(String batchId) async =>
      throw const NotFoundFailure(message: 'not used by these tests');

  /// When set, the targets read fails instead of answering — the sheet's
  /// own error face (C10), unreachable before this existed.
  Failure? targetsFailure;

  @override
  Stream<List<TrashRestoreTarget>> watchRestoreTargets(String batchId) {
    final failure = targetsFailure;
    if (failure != null) {
      return Stream<List<TrashRestoreTarget>>.error(failure);
    }

    return Stream<List<TrashRestoreTarget>>.value(targets);
  }

  @override
  Future<void> restore({
    required String batchId,
    required TrashRestoreTarget target,
  }) async {
    restores.add((batchId: batchId, target: target));
    final failure = nextFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> undo(String batchId) async {
    undos.add(batchId);
    final failure = nextFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> purge(List<String> batchIds) async {
    purges.add(batchIds);
    final failure = nextFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<int> purgeExpired(DateTime now) async {
    sweeps++;

    return 0;
  }
}

/// A batch with every field filled, so a test names only what it is about.
TrashBatchEntity fakeBatch({
  required String id,
  TrashItemType itemType = TrashItemType.card,
  String name = 'item',
  DateTime? deletedAt,
  String? originDeckId = 'origin',
  String? originDeckName = 'Origin',
  List<TrashPathSegment> originPath = const <TrashPathSegment>[],
  int deckCount = 0,
  int cardCount = 1,
}) => TrashBatchEntity(
  batchId: id,
  itemType: itemType,
  itemName: name,
  deletedAt: deletedAt ?? DateTime.utc(2026, 8, 1, 12),
  originDeckId: originDeckId,
  originDeckName: originDeckName,
  originPath: originPath,
  deckCount: deckCount,
  cardCount: cardCount,
);
