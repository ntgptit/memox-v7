import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/error/drift_error_mapper.dart';
import '../../../core/error/failure.dart';
import '../domain/card_entity.dart';
import '../domain/card_repository.dart';
import '../domain/deck_content_type_model.dart';
import '../domain/scheduler_type_model.dart';
import 'card_mapper.dart';
import 'local/card_dao.dart';
import 'local/deck_dao.dart';

/// Review-state initialisation per scheduler (BR-09 table).
const int _eightBoxInitialBox = 1;
const double _sm2InitialEaseFactor = 2.5;
const int _sm2InitialIntervalDays = 0;
const int _sm2InitialRepetitions = 0;

/// Drift-backed [CardRepository].
///
/// Uses both DAOs deliberately: `createCard` has a cross-entity invariant —
/// validate the target deck, lock an `unset` deck to `card` (BR-62), resolve
/// the scheduler from the root (BR-09) — and one drift transaction covers the
/// whole write **because both DAOs wrap the same open [AppDatabase]**. That
/// sameness is structural, not conventional: the constructor takes the one
/// database and builds both DAOs from it itself. An API accepting two
/// ready-made DAOs would let a composition root hand it DAOs from two
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
    String Function()? idGenerator,
    DateTime Function()? clock,
  }) : _cardDao = CardDao(database),
       _deckDao = DeckDao(database),
       _idGenerator = idGenerator ?? const Uuid().v4,
       _clock = clock ?? _utcNow;

  final CardDao _cardDao;

  /// For the deck side of the createCard invariant only — deck mutations
  /// beyond the BR-62 content lock belong to `DeckRepositoryImpl`.
  final DeckDao _deckDao;

  /// Client-generated UUIDs (AD-03); injectable so tests are deterministic.
  final String Function() _idGenerator;

  /// Injectable clock; timestamps are stored in UTC, always.
  final DateTime Function() _clock;

  static DateTime _utcNow() => DateTime.now().toUtc();

  @override
  Stream<List<CardEntity>> watchCardsByDeck(String deckId) => _cardDao
      .watchCardsByDeck(deckId)
      .handleError(_rethrowMapped)
      .map(
        (List<Card> rows) =>
            rows.map(cardEntityFromRow).toList(growable: false),
      );

  @override
  Future<CardEntity> createCard({
    required String deckId,
    required String front,
    required String back,
  }) => _guard(
    () => _cardDao.runInTransaction(() async {
      final validFront = CardEntity.validateSide(front, side: 'front');
      final validBack = CardEntity.validateSide(back, side: 'back');
      final deck = await _requireDeckRow(deckId);
      if (deck.parentDeckId == null) {
        // BR-58 — no card ever sits directly under a root.
        throw const ConflictFailure(
          message: 'A top-level deck holds decks, not cards.',
        );
      }
      final deckType = _knownContentType(deck);
      if (deckType == DeckContentType.deck) {
        throw const ConflictFailure(
          message: 'This deck holds decks, so it cannot hold cards.',
        );
      }

      final scheduler = await _resolveRootScheduler(deck.rootDeckId);
      final now = _clock();
      if (deckType == DeckContentType.unset) {
        // First card locks the deck to 'card' — same atomic step (BR-62).
        await _deckDao.updateDeckById(
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
          front: validFront,
          back: validBack,
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
    required String front,
    required String back,
  }) => _guard(() async {
    final validFront = CardEntity.validateSide(front, side: 'front');
    final validBack = CardEntity.validateSide(back, side: 'back');
    await _requireCardRow(cardId);
    // Writes to `cards` only — the review state and history cannot change
    // here because nothing else is touched (BR-10).
    await _cardDao.updateCardById(
      cardId,
      CardsCompanion(
        front: Value<String>(validFront),
        back: Value<String>(validBack),
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
    final row = await _deckDao.deckById(deckId);
    if (row == null) {
      throw const NotFoundFailure(message: 'That deck no longer exists.');
    }

    return row;
  }

  Future<Card> _requireCardRow(String cardId) async {
    final row = await _cardDao.cardById(cardId);
    if (row == null) {
      throw const NotFoundFailure(message: 'That card no longer exists.');
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
      );
    }

    final type = SchedulerType.fromDbValue(typeValue);
    if (type == SchedulerType.unknown) {
      throw const ConflictFailure(
        message: 'This deck uses a study mode this app version does not know.',
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
      ),
    };
  }
}
