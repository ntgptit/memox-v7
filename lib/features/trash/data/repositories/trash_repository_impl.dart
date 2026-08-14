import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../deck/domain/entities/deck_entity.dart';
import '../../../deck/domain/failures/deck_move_failure.dart';
import '../../../deck/domain/models/deck_content_type_model.dart';
import '../../domain/entities/trash_batch_entity.dart';
import '../../domain/failures/trash_conflict_failure.dart';
import '../../domain/models/trash_item_type_model.dart';
import '../../domain/models/trash_restore_eligibility_model.dart';
import '../../domain/models/trash_restore_target_model.dart';
import '../../domain/models/trash_retention_model.dart';
import '../../domain/repositories/trash_repository.dart';
import '../datasources/trash_dao.dart';
import '../mappers/trash_batch_mapper.dart';

part 'trash_restore_repository_impl.dart';
part 'trash_purge_repository_impl.dart';

/// Drift-backed [TrashRepository].
///
/// Same boundary as every other repository: below it rows, companions and
/// Drift exceptions; above it entities and [Failure]. The restore and purge
/// halves live in part files purely so each source file stays readable — it is
/// one class and one library, exactly as `DeckRepositoryImpl` is.
///
/// **Every write re-checks every rule inside its own transaction.** The picker
/// decided what to *offer* from a snapshot that is already history by the time
/// the user taps confirm; this decides what may be *written*. That is the same
/// split `buildDeckMoveTargets` and `moveDeck` have, and for the same reason: a
/// stale screen must never be able to widen what the database accepts.
final class TrashRepositoryImpl
    with _TrashRestoreOperations, _TrashPurgeOperations
    implements TrashRepository {
  TrashRepositoryImpl(this._dao, {required DateTime Function() clock})
    // The field stays private because the part files read it, and Dart forbids
    // a named parameter starting with an underscore.
    // ignore: prefer_initializing_formals
    : _clock = clock;

  @override
  final TrashDao _dao;

  /// Injected — no default (AD-06). UTC always.
  @override
  final DateTime Function() _clock;

  // ---- reads --------------------------------------------------------------

  @override
  Stream<List<TrashBatchEntity>> watchBatches() =>
      _guardStream(_dao.watchBatchRows()).map(_mapBatchRows);

  @override
  Future<TrashBatchEntity> batch(String batchId) =>
      _guard(() async => _requireBatch(batchId));

  @override
  Stream<List<TrashRestoreTarget>> watchRestoreTargets(String batchId) async* {
    // The batch is read once, up front: which statement supplies the candidates
    // depends on what kind of thing is being restored, and that never changes
    // for a given batch. A batch that has already been purged yields an empty
    // list rather than an error the picker cannot act on (UC-12 E6).
    final row = await _dao.batchById(batchId);
    if (row == null) {
      yield const <TrashRestoreTarget>[];

      return;
    }

    final itemType = TrashItemType.fromDbValue(row.itemType);
    if (itemType == null) {
      yield const <TrashRestoreTarget>[];

      return;
    }

    if (itemType == TrashItemType.card) {
      yield* _guardStream(_watchCardTargets(row));

      return;
    }

    yield* _guardStream(_watchDeckTargets(row));
  }

  /// Where a deleted card may go back to (BR-165, BR-187).
  ///
  /// **`cardMoveTargets`, the production statement, with nothing excluded.** A
  /// move excludes the deck the card is leaving; a restore has no such deck —
  /// the origin is the most likely destination of all. Everything else about
  /// eligibility is the same rule, read from the same place.
  Stream<List<TrashRestoreTarget>> _watchCardTargets(DeleteBatch row) async* {
    final card = await _dao.tombstoneCardInBatch(
      cardId: row.rootItemId,
      batchId: row.id,
    );
    if (card == null) {
      yield const <TrashRestoreTarget>[];

      return;
    }

    // The origin deck may itself be in Trash, so this read must see tombstones:
    // the card's tree is decided by where it was, not by what is visible now.
    final originDeck = await _dao.anyDeckById(card.deckId);
    if (originDeck == null) {
      yield const <TrashRestoreTarget>[];

      return;
    }

    yield* _dao
        .watchCardRestoreTargets(originDeck.rootDeckId)
        .map(
          (rows) => <TrashRestoreTarget>[
            for (final target in rows)
              TrashDeckTarget(
                deckId: target.deckId,
                name: target.deckName,
                parentName: target.parentName,
              ),
          ],
        );
  }

  /// Where a deleted deck may go back to (BR-187).
  ///
  /// A **root** deck has exactly one destination — the top level — because a
  /// root has no parent (BR-56) and move does not apply to it. Everything else
  /// runs the move rule set over the active tree.
  Stream<List<TrashRestoreTarget>> _watchDeckTargets(DeleteBatch row) async* {
    final deck = await _dao.tombstoneDeckInBatch(
      deckId: row.rootItemId,
      batchId: row.id,
    );
    if (deck == null) {
      yield const <TrashRestoreTarget>[];

      return;
    }

    if (deck.parentDeckId == null) {
      yield const <TrashRestoreTarget>[TrashTopLevelTarget()];

      return;
    }

    final source = trashDeckEntityFromRow(deck);
    final sourceRootRow = await _dao.anyDeckById(deck.rootDeckId);
    final sourceRoot = sourceRootRow == null
        ? null
        : trashDeckEntityFromRow(sourceRootRow);
    final height = await _dao.batchSubtreeHeightProbe(
      deckId: deck.id,
      batchId: row.id,
      maxWalk: DeckEntity.maxTreeDepth + 1,
    );
    // A probe that hit its bound means the stored subtree is deeper than the
    // app allows, or cyclic. The picker offers nothing rather than offering
    // targets computed from a height that might be wrong; the confirm path
    // refuses the same case with a typed reason.
    if (height == null || height > DeckEntity.maxTreeDepth) {
      yield const <TrashRestoreTarget>[];

      return;
    }

    yield* _dao.watchActiveDecks().map((rows) {
      final candidates = buildTrashDeckCandidates(
        source: source,
        sourceRoot: sourceRoot,
        activeDecks: rows.map(trashDeckEntityFromRow).toList(growable: false),
        sourceSubtreeHeight: height,
      );

      return <TrashRestoreTarget>[
        for (final candidate in candidates)
          if (candidate.isEligible)
            TrashDeckTarget(
              deckId: candidate.deck.id,
              name: candidate.deck.name,
              // The parent's name, so two same-named decks are tellable apart
              // without a breadcrumb per row — the same fact `cardMoveTargets`
              // carries for the card picker.
              parentName: _parentNameOf(candidate.deck, rows),
            ),
      ];
    });
  }

  String? _parentNameOf(DeckEntity deck, List<Deck> rows) {
    final parentId = deck.parentDeckId;
    if (parentId == null) return null;

    for (final row in rows) {
      if (row.id == parentId) return row.name;
    }

    return null;
  }

  // ---- helpers ------------------------------------------------------------

  List<TrashBatchEntity> _mapBatchRows(List<TrashBatchRowsResult> rows) {
    final batches = <TrashBatchEntity>[];
    for (final row in rows) {
      final batch = trashBatchFromRow(row);
      // A row that cannot be read is dropped rather than drawn as a ghost —
      // see the mapper for why that is the safe direction here.
      if (batch == null) continue;
      batches.add(batch);
    }

    return List<TrashBatchEntity>.unmodifiable(batches);
  }

  Future<TrashBatchEntity> _requireBatch(String batchId) async {
    final rows = await _dao.batchRows();
    for (final row in rows) {
      if (row.batchId != batchId) continue;
      final batch = trashBatchFromRow(row);
      if (batch != null) return batch;
      break;
    }

    throw const NotFoundFailure(message: 'That item is no longer in Trash.');
  }

  @override
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw mapDatabaseError(error);
    }
  }

  Stream<T> _guardStream<T>(Stream<T> source) =>
      source.handleError(_rethrowMapped);

  Never _rethrowMapped(Object error) {
    if (error is Failure) throw error;
    throw mapDatabaseError(error);
  }
}
