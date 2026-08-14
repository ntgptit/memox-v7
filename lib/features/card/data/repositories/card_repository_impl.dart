import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../deck/domain/models/deck_content_type_model.dart';
import '../../../deck/domain/models/scheduler_type_model.dart';
import '../../domain/entities/card_entity.dart';
import '../../domain/entities/tag_entity.dart';
import '../../domain/failures/card_conflict_failure.dart';
import '../../domain/failures/card_not_found_failure.dart';
import '../../domain/failures/tag_validation_failure.dart';
import '../../domain/models/card_list_filter_model.dart';
import '../../domain/models/card_list_item_model.dart';
import '../../domain/models/card_list_sort_model.dart';
import '../../domain/models/card_move_target_model.dart';
import '../../domain/models/card_state_distribution_model.dart';
import '../../domain/models/card_text_model.dart';
import '../../domain/models/deck_context_model.dart';
import '../../domain/models/tag_name_model.dart';
import '../../domain/repositories/card_repository.dart';
import '../../../trash/domain/repositories/content_trash_repository.dart';
import '../datasources/card_list_read_data_source.dart';
import '../datasources/deck_context_read_data_source.dart';
import '../mappers/card_mapper.dart';
import '../mappers/card_study_state_seed_mapper.dart';
import '../mappers/tag_mapper.dart';
import '../datasources/card_dao.dart';
import '../datasources/card_deck_context_dao.dart';

part 'card_bulk_repository_impl.dart';

/// Drift-backed [CardRepository].
///
/// Builds all its adapters from the one [AppDatabase] it is handed, so
/// `createCard`'s cross-entity invariant — validate the deck, lock an `unset`
/// deck to `card` (BR-62), resolve the scheduler from the root (BR-09) — runs in
/// one transaction. Ready-made adapters would let a root pass two databases,
/// putting the BR-62 lock outside the rollback.
///
/// Same boundary as `DeckRepositoryImpl`: below, rows and Drift exceptions;
/// above, entities and [Failure].
final class CardRepositoryImpl
    with _CardBulkOperations
    implements CardRepository {
  CardRepositoryImpl(
    AppDatabase database, {
    required DateTime Function() clock,
    required ContentTrashRepository trash,
    String Function()? idGenerator,
  }) : // A named parameter cannot start with `_`, so the formal is impossible.
       // ignore: prefer_initializing_formals
       _trash = trash,
       _cardDao = CardDao(database),
       _reads = CardListReadDataSource(CardDao(database)),
       _deckContextReads = DeckContextReadDataSource(database),
       _deckContextDao = CardDeckContextDao(database),
       _idGenerator = idGenerator ?? const Uuid().v4,
       // A named parameter can't start with `_`, so the formal is impossible.
       // ignore: prefer_initializing_formals
       _clock = clock;

  @override
  final CardDao _cardDao;

  /// Trash's contract, for the batch half of a soft delete (BR-182).
  @override
  final ContentTrashRepository _trash;

  /// The list reads (windowed rows, filter counts), split out for size.
  final CardListReadDataSource _reads;

  /// The deck-context reads (header name + breadcrumb, holds-cards).
  final DeckContextReadDataSource _deckContextReads;

  /// For the deck side of the createCard invariant only (BR-62 lock).
  @override
  final CardDeckContextDao _deckContextDao;

  /// Client-generated UUIDs (AD-03); injectable so tests are deterministic.
  @override
  final String Function() _idGenerator;

  /// Injected — no default. A `?? DateTime.now()` fallback gives "now" two
  /// owners and the unreachable static wins in production. UTC always.
  @override
  final DateTime Function() _clock;

  @override
  Stream<List<CardEntity>> watchCardsByDeck(
    String deckId, {
    required int limit,
  }) => _reads.watchCardsByDeck(deckId, limit: limit);

  @override
  Stream<List<CardListItemModel>> watchCardListItems(
    String deckId, {
    required int limit,
    CardListFilter filter = CardListFilter.all,
    CardListSort sort = CardListSort.newest,
    String? searchTerm,
    DateTime? now,
  }) => _reads.watchCardListItems(
    deckId,
    limit: limit,
    filter: filter,
    sort: sort,
    searchTerm: searchTerm,
    now: now,
  );

  @override
  Stream<int> watchFilteredCardCount(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    String? searchTerm,
    DateTime? now,
  }) => _reads.watchFilteredCardCount(
    deckId,
    filter: filter,
    searchTerm: searchTerm,
    now: now,
  );

  @override
  Stream<int> watchCardCountByDeck(String deckId) =>
      _reads.watchCardCountByDeck(deckId);

  @override
  Stream<CardStateDistributionModel> watchCardStateDistribution(
    String deckId,
  ) => _reads.watchCardStateDistribution(deckId);

  @override
  Stream<DeckContextModel> watchDeckContext(String deckId) =>
      _deckContextReads.watchDeckContext(deckId);

  @override
  Future<bool> readDeckHoldsCards(String deckId) =>
      _deckContextReads.readDeckHoldsCards(deckId);

  @override
  Future<CardEntity> getCard(String cardId) =>
      _guard(() async => cardEntityFromRow(await _requireCardRow(cardId)));

  @override
  Future<CardEntity> createCard({
    required String deckId,
    required CardText front,
    required CardText back,
    CardDetailText? example,
    CardDetailText? hint,
    CardDetailText? pronunciation,
  }) => _guard(
    () => _cardDao.runInTransaction(() async {
      // No validation here: BR-07/BR-08 ran in `CardText.parse` above the
      // contract; re-running them here gave one rule two owners.
      final deck = await _requireDeckRow(deckId);
      if (deck.parentDeckId == null) {
        // BR-58 — no card ever sits directly under a root.
        throw const ConflictFailure(
          message: 'A top-level deck holds decks, not cards.',
          reason: CardConflictReason.parentIsRoot,
        );
      }
      final deckType = _knownContentType(deck);
      if (deckType == DeckContentType.deck) {
        throw const ConflictFailure(
          message: 'This deck holds decks, so it cannot hold cards.',
          reason: CardConflictReason.deckHoldsDecks,
        );
      }

      final scheduler = await _resolveRootScheduler(deck.rootDeckId);
      final now = _clock();
      if (deckType == DeckContentType.unset) {
        // First card locks the deck to 'card' — same atomic step (BR-62).
        await _deckContextDao.updateDeckById(
          deck.id,
          DecksCompanion(
            contentType: Value<String>(DeckContentType.card.dbValue),
            updatedAt: Value<DateTime>(now),
          ),
        );
      }

      final id = _idGenerator();
      await _cardDao.insertCard(
        CardsCompanion.insert(
          id: id,
          deckId: deck.id,
          front: front.value,
          back: back.value,
          // Written together with the text they fold, never derived later: a
          // row whose folded column disagrees with its text is invisible to
          // search while looking perfectly correct in the list.
          frontFolded: Value<String>(front.folded),
          backFolded: Value<String>(back.folded),
          example: Value<String?>(example?.value),
          hint: Value<String?>(hint?.value),
          pronunciation: Value<String?>(pronunciation?.value),
          createdAt: now,
          updatedAt: now,
        ),
      );
      // Exactly one study state, born with the card (BR-09); due_at NULL.
      await _cardDao.insertReviewState(
        initialReviewStateFromScheduler(id, scheduler),
      );

      return cardEntityFromRow(await _requireCardRow(id));
    }),
  );

  @override
  Future<CardEntity> updateCard({
    required String cardId,
    required CardText front,
    required CardText back,
    CardDetailText? example,
    CardDetailText? hint,
    CardDetailText? pronunciation,
  }) => _guard(() async {
    await _requireCardRow(cardId);
    // `cards` only, so BR-10 holds structurally. Details always written
    // (BR-95): a null clears the column.
    await _cardDao.updateCardById(
      cardId,
      CardsCompanion(
        front: Value<String>(front.value),
        back: Value<String>(back.value),
        frontFolded: Value<String>(front.folded),
        backFolded: Value<String>(back.folded),
        example: Value<String?>(example?.value),
        hint: Value<String?>(hint?.value),
        pronunciation: Value<String?>(pronunciation?.value),
        updatedAt: Value<DateTime>(_clock()),
      ),
    );

    return cardEntityFromRow(await _requireCardRow(cardId));
  });

  /// Moves a card to Trash, and hands the deck its content type back when that
  /// was the last one (BR-182, BR-186).
  ///
  /// **One element into the bulk primitive.** A second transaction path for
  /// "just this card" is a second place for the emptied-deck rule to be
  /// forgotten; `deleteCards` owns it once (BR-166).
  @override
  Future<void> deleteCard(String cardId) => deleteCards(<String>[cardId]);

  /// The same deletion, returning the one batch so the caller can offer Undo
  /// (BR-182, BR-189).
  @override
  Future<String> deleteCardForUndo(String cardId) async {
    final batchIds = await deleteCardsForUndo(<String>[cardId]);

    return batchIds.single;
  }

  @override
  Stream<List<TagEntity>> watchCardTags(String cardId) => _cardDao
      .watchTagsForCard(cardId)
      .handleError(_rethrowMapped)
      .map(
        (List<Tag> rows) => rows.map(tagEntityFromRow).toList(growable: false),
      );

  @override
  Future<void> addCardTag({required String cardId, required TagName name}) =>
      addTagToCards(cardIds: <String>[cardId], name: name);

  @override
  Future<void> removeCardTag({required String cardId, required String tagId}) =>
      _guard(() async {
        // No existence check: unlinking an absent pair is the same end state.
        await _cardDao.unlinkTag(cardId, tagId);
      });

  @override
  Stream<bool> watchCardFlag(String cardId) =>
      _cardDao.watchCardFlag(cardId).handleError(_rethrowMapped);

  @override
  /// Only `is_flagged` moves (BR-92) — one element into the bulk primitive,
  /// which is the one place that statement lives.
  Future<void> setCardFlag({required String cardId, required bool isFlagged}) =>
      setCardsFlag(cardIds: <String>[cardId], isFlagged: isFlagged);

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

  Never _rethrowMapped(Object error) {
    if (error is Failure) throw error;
    throw mapDatabaseError(error);
  }

  @override
  Future<Deck> _requireDeckRow(String deckId) async {
    final row = await _deckContextDao.deckById(deckId);
    if (row == null) {
      throw const NotFoundFailure(
        message: 'That deck no longer exists.',
        reason: CardNotFoundReason.deckGone,
      );
    }

    return row;
  }

  Future<Card> _requireCardRow(String cardId) async {
    final row = await _cardDao.cardById(cardId);
    if (row == null) {
      throw const NotFoundFailure(
        message: 'That card no longer exists.',
        reason: CardNotFoundReason.cardGone,
      );
    }

    return row;
  }

  /// A deck's content type, refusing a value this build does not know.
  @override
  DeckContentType _knownContentType(Deck deck) {
    final type = DeckContentType.fromDbValue(deck.contentType);
    if (type == DeckContentType.unknown) {
      throw const ConflictFailure(
        message: 'This deck was made by a newer version of the app.',
        reason: CardConflictReason.unknownContentType,
      );
    }

    return type;
  }

  /// The root's scheduler, via `root_deck_id` (BR-57), for BR-09's state.
  Future<({SchedulerType type, int version, int generation})>
  _resolveRootScheduler(String rootDeckId) async {
    final root = await _requireDeckRow(rootDeckId);
    final typeValue = root.schedulerType;
    final version = root.schedulerVersion;
    final generation = root.schedulerGeneration;
    if (typeValue == null || version == null || generation == null) {
      // A root without a scheduler violates Q11 — refuse rather than guess.
      throw const ConflictFailure(
        message: 'This deck has no study mode configured.',
        reason: CardConflictReason.rootSchedulerMissing,
      );
    }

    final type = SchedulerType.fromDbValue(typeValue);
    if (type == SchedulerType.unknown) {
      throw const ConflictFailure(
        message: 'This deck uses a study mode this app version does not know.',
        reason: CardConflictReason.unknownScheduler,
      );
    }

    return (type: type, version: version, generation: generation);
  }
}
