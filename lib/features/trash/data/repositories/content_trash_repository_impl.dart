import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../study/domain/repositories/study_repository.dart';
import '../../domain/models/trash_item_type_model.dart';
import '../../domain/repositories/content_trash_repository.dart';
import '../datasources/trash_dao.dart';

/// Drift-backed [ContentTrashRepository] — the batch half of a soft delete.
///
/// **It opens no transaction.** Every method here is called from inside the
/// Deck or Card repository's own delete transaction (BR-256), and a nested
/// transaction is a savepoint that can commit while the outer one rolls back:
/// a batch recorded for a deletion that never happened, or worse, sessions
/// closed for one. The contract says so and this is the implementation of that
/// sentence.
///
/// The order inside each method is load-bearing and is the same both times:
/// **read the ids, close the sessions, then mark.** Reading first because a
/// tombstone is invisible to `activeSubtreeDeckIds`; closing before marking
/// because the session lookups join `study_queue_items` to rows that are about
/// to become invisible to nothing at all — they read `study_sessions`, but the
/// ids handed to them describe live rows and must be gathered while they are.
final class ContentTrashRepositoryImpl implements ContentTrashRepository {
  ContentTrashRepositoryImpl(
    this._dao, {
    required DateTime Function() clock,
    required StudyRepository study,
    String Function()? idGenerator,
  }) : _idGenerator = idGenerator ?? const Uuid().v4,
       // A named parameter cannot start with `_`, so the formal is impossible.
       // ignore: prefer_initializing_formals
       _study = study,
       // ignore: prefer_initializing_formals
       _clock = clock;

  final TrashDao _dao;
  final StudyRepository _study;

  /// Client-generated UUIDs (AD-03); injectable so tests are deterministic.
  final String Function() _idGenerator;

  /// Injected — no default, for the reason AD-06 gives. UTC always.
  final DateTime Function() _clock;

  @override
  Future<String> markDeckDeleted(String deckId) => _guard(() async {
    // The subtree is read from the ACTIVE tree, so a branch already in Trash
    // keeps the batch it went with and is not swept into this one (BR-258).
    // Restoring this batch will therefore leave it exactly where it is.
    final deckIds = await _dao.activeSubtreeDeckIds(deckId);
    if (deckIds.isEmpty) {
      // No active row with this id: it is already in Trash, or gone. Either way
      // the caller is describing a database that has moved on.
      throw const NotFoundFailure(message: 'That deck no longer exists.');
    }

    final cardIds = await _dao.activeCardIdsInDecks(deckIds);
    final now = _clock();

    // BR-259, in the same transaction and before the rows go dark. Both id sets
    // are needed: a session opened on a deck in this subtree, and a session
    // reviewing the whole root whose queue happens to hold one of these cards.
    await _study.invalidateSessionsForDeletedContent(
      deckIds: deckIds,
      cardIds: cardIds,
      endedAt: now,
    );

    final batchId = _idGenerator();
    await _dao.insertBatch(
      DeleteBatchesCompanion.insert(
        id: batchId,
        itemType: TrashItemType.deck.dbValue,
        rootItemId: deckId,
        deletedAt: now,
      ),
    );
    final markedDecks = await _dao.markDecksDeleted(
      deckIds: deckIds,
      batchId: batchId,
      updatedAt: now,
    );
    final markedCards = await _dao.markCardsDeleted(
      cardIds: cardIds,
      batchId: batchId,
      updatedAt: now,
    );
    // The ids were read from the active tree inside this transaction, so a
    // short count is not a race — it is a bug, and one that would leave a batch
    // missing part of what it claims (invariant 37). Throwing rolls everything
    // back rather than recording a deletion nobody can undo cleanly.
    if (markedDecks != deckIds.length || markedCards != cardIds.length) {
      throw const DatabaseFailure(
        message: 'Refused: the deletion marked fewer rows than it read.',
      );
    }

    return batchId;
  });

  @override
  Future<List<String>> markCardsDeleted(List<String> cardIds) =>
      _guard(() async {
        if (cardIds.isEmpty) return const <String>[];

        final now = _clock();
        // One call for the whole selection: fifty cards is one pair of lookups
        // and however many sessions they touch, not fifty of each.
        await _study.invalidateSessionsForDeletedContent(
          deckIds: const <String>[],
          cardIds: cardIds,
          endedAt: now,
        );

        // **One batch per card, not one per action** (BR-256). The item root is
        // singular, and a user who deletes fifty cards may want three of them
        // back — which a shared batch could not give them without inventing a
        // partial restore that BR-262 does not have.
        final batchIds = <String>[];
        for (final cardId in cardIds) {
          final batchId = _idGenerator();
          await _dao.insertBatch(
            DeleteBatchesCompanion.insert(
              id: batchId,
              itemType: TrashItemType.card.dbValue,
              rootItemId: cardId,
              deletedAt: now,
            ),
          );
          final marked = await _dao.markCardsDeleted(
            cardIds: <String>[cardId],
            batchId: batchId,
            updatedAt: now,
          );
          // The statement refuses a card that is already a tombstone, so zero
          // here means the selection named a card that has since gone to Trash.
          // Committing would leave a batch with no rows (invariant 35) and a
          // Trash row the user cannot act on.
          if (marked != 1) {
            throw const NotFoundFailure(message: 'That card no longer exists.');
          }
          batchIds.add(batchId);
        }

        return batchIds;
      });

  /// The same boundary every repository has: domain failures pass, everything
  /// else is mapped before it can leave `data/`.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw mapDatabaseError(error);
    }
  }
}
