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
import '../../domain/models/card_text_model.dart';
import '../../domain/models/tag_name_model.dart';
import '../../domain/repositories/card_repository.dart';
import '../mappers/card_mapper.dart';
import '../mappers/tag_mapper.dart';
import '../datasources/card_dao.dart';
import '../datasources/card_deck_context_dao.dart';

/// Review-state initialisation per scheduler (BR-09 table).
const int _eightBoxInitialBox = 1;
const double _sm2InitialEaseFactor = 2.5;
const int _sm2InitialIntervalDays = 0;
const int _sm2InitialRepetitions = 0;

/// Drift-backed [CardRepository].
///
/// Uses both Card-owned adapters deliberately: `createCard` has a cross-entity
/// invariant — validate the target deck, lock an `unset` deck to `card`
/// (BR-62), resolve the scheduler from the root (BR-09) — and one drift
/// transaction covers the whole write **because both adapters wrap the same
/// open [AppDatabase]**. That
/// sameness is structural, not conventional: the constructor takes the one
/// database and builds both adapters from it itself. An API accepting two
/// ready-made adapters would let a composition root hand it instances from two
/// databases, and the BR-62 content lock would then sit outside the
/// transaction that rolls the card back — a bug no test with a correctly
/// wired harness can see.
///
/// Same boundary rule as `DeckRepositoryImpl`: below this class, rows,
/// companions and Drift exceptions; above it, entities and [Failure]. The
/// guard helpers are intentionally this class's own — each repository owns
/// its boundary rather than sharing one through a hidden coupling.
final class CardRepositoryImpl implements CardRepository {
  CardRepositoryImpl(
    AppDatabase database, {
    required DateTime Function() clock,
    String Function()? idGenerator,
  }) : _cardDao = CardDao(database),
       _deckContextDao = CardDeckContextDao(database),
       _idGenerator = idGenerator ?? const Uuid().v4,
       // The initializing formal the lint asks for would be
       // `required this._clock`, and Dart forbids a named parameter starting
       // with an underscore.
       // ignore: prefer_initializing_formals
       _clock = clock;

  final CardDao _cardDao;

  /// For the deck side of the createCard invariant only — deck mutations
  /// beyond the BR-62 content lock belong to `DeckRepositoryImpl`.
  final CardDeckContextDao _deckContextDao;

  /// Client-generated UUIDs (AD-03); injectable so tests are deterministic.
  final String Function() _idGenerator;

  /// The clock, injected — there is no default.
  ///
  /// A `?? DateTime.now()` fallback here would make "now" have two owners: this
  /// private static, and `clockProvider` which the whole tree can override. The
  /// one that is harder to reach is the one that silently wins in production, so
  /// it is gone and the composition root passes the provider's clock in.
  /// Timestamps are stored in UTC, always.
  final DateTime Function() _clock;

  @override
  Stream<List<CardEntity>> watchCardsByDeck(
    String deckId, {
    required int limit,
  }) {
    // A window has to be a window. Zero would render an empty deck that has
    // cards, and a negative one is SQLite's "no limit" — the unbounded read
    // this parameter exists to prevent, arriving through the parameter meant
    // to stop it.
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'must be at least 1');
    }

    return _cardDao
        .watchCardsByDeck(deckId, limit: limit)
        .handleError(_rethrowMapped)
        .map(
          (List<Card> rows) =>
              rows.map(cardEntityFromRow).toList(growable: false),
        );
  }

  @override
  Stream<int> watchCardCountByDeck(String deckId) =>
      _cardDao.watchCardCountByDeck(deckId).handleError(_rethrowMapped);

  @override
  Future<CardEntity> getCard(String cardId) =>
      _guard(() async => cardEntityFromRow(await _requireCardRow(cardId)));

  @override
  Future<CardEntity> createCard({
    required String deckId,
    required CardText front,
    required CardText back,
  }) => _guard(
    () => _cardDao.runInTransaction(() async {
      // No validation here. BR-07 and BR-08 were applied by `CardText.parse`
      // above the contract, and re-running them inside the transaction is what
      // gave one rule two owners — the arrangement `DeckName` ended on the deck
      // side and this now matches.
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
          createdAt: now,
          updatedAt: now,
        ),
      );
      // Exactly one review state, born with the card (BR-09). due_at stays
      // NULL — a new card is due immediately. Counters default to 0.
      await _cardDao.insertReviewState(_initialReviewState(id, scheduler));

      return cardEntityFromRow(await _requireCardRow(id));
    }),
  );

  @override
  Future<CardEntity> updateCard({
    required String cardId,
    required CardText front,
    required CardText back,
  }) => _guard(() async {
    await _requireCardRow(cardId);
    // Writes to `cards` only — the review state and history cannot change
    // here because nothing else is touched (BR-10).
    await _cardDao.updateCardById(
      cardId,
      CardsCompanion(
        front: Value<String>(front.value),
        back: Value<String>(back.value),
        updatedAt: Value<DateTime>(_clock()),
      ),
    );

    return cardEntityFromRow(await _requireCardRow(cardId));
  });

  @override
  Future<void> deleteCard(String cardId) => _guard(() async {
    await _requireCardRow(cardId);
    // The review state and history cascade; the deck's content_type is
    // deliberately left alone, even for the last card (BR-67).
    await _cardDao.deleteCardById(cardId);
  });

  @override
  Stream<List<TagEntity>> watchCardTags(String cardId) => _cardDao
      .watchTagsForCard(cardId)
      .handleError(_rethrowMapped)
      .map(
        (List<Tag> rows) => rows.map(tagEntityFromRow).toList(growable: false),
      );

  @override
  Future<void> addCardTag({
    required String cardId,
    required TagName name,
  }) => _guard(
    () => _cardDao.runInTransaction(() async {
      await _requireCardRow(cardId);
      // BR-94, and it lives inside the transaction on purpose: the count and the
      // link must be atomic, or two adds racing each other both pass an eleventh
      // tag past a check that each read as "9 so far".
      final existing = await _cardDao.tagCountForCard(cardId);
      if (existing >= kMaxTagsPerCard) {
        refuseInvalidTag(<TagValidationProblem>{
          TagValidationProblem.tooManyTags,
        });
      }

      // Reuse the tag that already owns this folded name (BR-93); mint one only
      // when nobody does. `owner_id` stays NULL — the local profile (AD-03).
      final owned = await _cardDao.tagByFoldedName(name.folded);
      final tagId = owned?.id ?? _idGenerator();
      if (owned == null) {
        await _cardDao.insertTag(
          TagsCompanion.insert(
            id: tagId,
            name: name.value,
            nameFolded: name.folded,
            createdAt: _clock(),
          ),
        );
      }

      // Idempotent — the DAO ignores a pair the card already carries.
      await _cardDao.linkTag(cardId, tagId);
    }),
  );

  @override
  Future<void> removeCardTag({
    required String cardId,
    required String tagId,
  }) => _guard(() async {
    // No existence check: unlinking a pair that is not there removes nothing and
    // is the same end state, so a double tap is harmless (BR-93).
    await _cardDao.unlinkTag(cardId, tagId);
  });

  @override
  Future<void> setCardFlag({required String cardId, required bool isFlagged}) =>
      _guard(() async {
        await _requireCardRow(cardId);
        // Only `is_flagged` moves (BR-92); the DAO's companion covers that one
        // column, so no edit path can ride along on a flag toggle.
        await _cardDao.setCardFlag(cardId, isFlagged: isFlagged);
      });

  // ---- helpers -----------------------------------------------------------

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

  /// Reads a deck's content type, refusing to operate on a value this build
  /// does not understand — altering such a deck could contradict rules a
  /// newer schema attached to it.
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

  /// The root's scheduler columns, resolved through `root_deck_id` (BR-57)
  /// for the review state a new card must carry (BR-09).
  Future<({SchedulerType type, int version, int generation})>
  _resolveRootScheduler(String rootDeckId) async {
    final root = await _requireDeckRow(rootDeckId);
    final typeValue = root.schedulerType;
    final version = root.schedulerVersion;
    final generation = root.schedulerGeneration;
    if (typeValue == null || version == null || generation == null) {
      // A root without a scheduler violates invariant Q11; refusing is the
      // only honest response to corrupt data.
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

  CardReviewStatesCompanion _initialReviewState(
    String cardId,
    ({SchedulerType type, int version, int generation}) scheduler,
  ) {
    final base = CardReviewStatesCompanion.insert(
      cardId: cardId,
      schedulerType: scheduler.type.dbValue,
      schedulerVersion: scheduler.version,
      schedulerGeneration: scheduler.generation,
    );

    return switch (scheduler.type) {
      // BR-09 initialisation table: each scheduler fills only its own columns.
      SchedulerType.eightBox => base.copyWith(
        currentBox: const Value<int?>(_eightBoxInitialBox),
      ),
      SchedulerType.sm2 => base.copyWith(
        easeFactor: const Value<double?>(_sm2InitialEaseFactor),
        intervalDays: const Value<int?>(_sm2InitialIntervalDays),
        repetitions: const Value<int?>(_sm2InitialRepetitions),
      ),
      // Unreachable: _resolveRootScheduler already refused it.
      SchedulerType.unknown => throw const ConflictFailure(
        message: 'This deck uses a study mode this app version does not know.',
        reason: CardConflictReason.unknownScheduler,
      ),
    };
  }
}
