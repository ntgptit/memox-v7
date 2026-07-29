import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/error/drift_error_mapper.dart';
import '../../../core/error/failure.dart';
import '../domain/card_entity.dart';
import '../domain/deck_content_type_model.dart';
import '../domain/deck_deletion_impact_model.dart';
import '../domain/deck_entity.dart';
import '../domain/deck_repository.dart';
import '../domain/scheduler_type_model.dart';
import 'card_mapper.dart';
import 'deck_mapper.dart';
import 'local/deck_dao.dart';

part 'card_write_deck_repository_impl.dart';
part 'move_deck_repository_impl.dart';

/// A fresh root deck starts at scheduler version 1, generation 1 (BR-40).
const int _initialSchedulerVersion = 1;
const int _initialSchedulerGeneration = 1;

/// Review-state initialisation per scheduler (BR-09 table).
const int _eightBoxInitialBox = 1;
const double _sm2InitialEaseFactor = 2.5;
const int _sm2InitialIntervalDays = 0;
const int _sm2InitialRepetitions = 0;

/// Drift-backed [DeckRepository].
///
/// This class is the boundary of two languages: below it, rows, companions and
/// Drift exceptions; above it, entities and [Failure]. Nothing from below
/// crosses up — every method runs inside [_guard], which rethrows domain
/// failures untouched and maps anything else through `mapDatabaseError`.
///
/// Multi-step writes — first-child content lock (BR-62), card + review state
/// (BR-09), subtree move (BR-71) — each run atomically: a thrown failure
/// anywhere inside rolls back every step. The card and move operations live in
/// the two part files as private mixins, purely to keep each source file
/// readable; it is one class and one library.
final class DeckRepositoryImpl
    with _CardWriteOperations, _MoveDeckOperation
    implements DeckRepository {
  DeckRepositoryImpl(
    this._dao, {
    String Function()? idGenerator,
    DateTime Function()? clock,
  }) : _idGenerator = idGenerator ?? const Uuid().v4,
       _clock = clock ?? _utcNow;

  @override
  final DeckDao _dao;

  /// Client-generated UUIDs (AD-03); injectable so tests are deterministic.
  @override
  final String Function() _idGenerator;

  /// Injectable clock; timestamps are stored in UTC, always.
  @override
  final DateTime Function() _clock;

  static DateTime _utcNow() => DateTime.now().toUtc();

  // ---- reads -------------------------------------------------------------

  @override
  Stream<List<DeckEntity>> watchRootDecks() =>
      _guardStream(_dao.watchRootDecks()).map(_mapDeckRows);

  @override
  Stream<List<DeckEntity>> watchDeckTree(String rootDeckId) =>
      _guardStream(_dao.watchDecksInTree(rootDeckId)).map(_mapDeckRows);

  @override
  Stream<List<DeckEntity>> watchChildDecks(String parentDeckId) =>
      _guardStream(_dao.watchChildDecks(parentDeckId)).map(_mapDeckRows);

  @override
  Future<DeckEntity> getDeckById(String deckId) =>
      _guard(() async => deckEntityFromRow(await _requireDeckRow(deckId)));

  // ---- deck writes -------------------------------------------------------

  @override
  Future<DeckEntity> createRootDeck({
    required String name,
    required SchedulerType schedulerType,
  }) => _guard(() async {
    final validName = DeckEntity.validateName(name);
    _requireRealScheduler(schedulerType);

    final id = _idGenerator();
    final now = _clock();
    await _dao.insertDeck(
      DecksCompanion.insert(
        id: id,
        name: validName,
        rootDeckId: id,
        contentType: DeckContentType.deck.dbValue,
        schedulerType: Value<String?>(schedulerType.dbValue),
        schedulerVersion: const Value<int?>(_initialSchedulerVersion),
        schedulerGeneration: const Value<int?>(_initialSchedulerGeneration),
        createdAt: now,
        updatedAt: now,
      ),
    );

    return deckEntityFromRow(await _requireDeckRow(id));
  });

  @override
  Future<DeckEntity> createSubDeck({
    required String name,
    required String parentDeckId,
  }) => _guard(
    () => _dao.runInTransaction(() async {
      final validName = DeckEntity.validateName(name);
      final parent = await _requireDeckRow(parentDeckId);
      final parentType = _knownContentType(parent);
      if (parentType == DeckContentType.card) {
        throw const ConflictFailure(
          message: 'This deck holds cards, so it cannot hold decks.',
        );
      }

      final now = _clock();
      if (parentType == DeckContentType.unset) {
        // First child locks the parent to 'deck' — same atomic step (BR-62).
        await _dao.updateDeckById(
          parent.id,
          DecksCompanion(
            contentType: Value<String>(DeckContentType.deck.dbValue),
            updatedAt: Value<DateTime>(now),
          ),
        );
      }

      final id = _idGenerator();
      await _dao.insertDeck(
        DecksCompanion.insert(
          id: id,
          name: validName,
          parentDeckId: Value<String?>(parent.id),
          rootDeckId: parent.rootDeckId,
          contentType: DeckContentType.unset.dbValue,
          createdAt: now,
          updatedAt: now,
        ),
      );

      return deckEntityFromRow(await _requireDeckRow(id));
    }),
  );

  @override
  Future<void> renameDeck({required String deckId, required String name}) =>
      _guard(() async {
        final validName = DeckEntity.validateName(name);
        await _requireDeckRow(deckId);
        await _dao.updateDeckById(
          deckId,
          DecksCompanion(
            name: Value<String>(validName),
            updatedAt: Value<DateTime>(_clock()),
          ),
        );
      });

  @override
  Future<DeckDeletionImpact> getDeletionImpact(String deckId) =>
      _guard(() async {
        await _requireDeckRow(deckId);
        final subtreeIds = await _dao.subtreeDeckIds(deckId);
        final cardCount = await _dao.subtreeCardCount(deckId);

        return DeckDeletionImpact(
          // The subtree walk includes the deck itself; the confirm dialog
          // talks about what goes *with* it.
          descendantDeckCount: subtreeIds.length - 1,
          cardCount: cardCount,
        );
      });

  @override
  Future<void> deleteDeck(String deckId) => _guard(() async {
    await _requireDeckRow(deckId);
    // Descendants, cards, review states, history and sessions cascade from
    // this one delete (BR-03) — enforced by the schema's foreign keys.
    await _dao.deleteDeckById(deckId);
  });

  @override
  Future<void> resetContentType(String deckId) => _guard(
    () => _dao.runInTransaction(() async {
      final deck = await _requireDeckRow(deckId);
      if (deck.parentDeckId == null) {
        // A root is 'deck' forever — that is what makes BR-58 checkable.
        throw const ConflictFailure(
          message: 'A top-level deck always holds decks.',
        );
      }
      if (await _dao.directCardCount(deckId) > 0) {
        throw const ConflictFailure(
          message: 'The deck still has cards. Remove them first.',
        );
      }
      if (await _dao.directChildDeckCount(deckId) > 0) {
        throw const ConflictFailure(
          message: 'The deck still has decks inside it. Remove them first.',
        );
      }

      await _dao.updateDeckById(
        deckId,
        DecksCompanion(
          contentType: Value<String>(DeckContentType.unset.dbValue),
          updatedAt: Value<DateTime>(_clock()),
        ),
      );
    }),
  );

  // ---- helpers -----------------------------------------------------------

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

  /// Re-throws stream errors through the same boundary as [_guard], so a
  /// watcher never sees a raw Drift exception either.
  @override
  Stream<T> _guardStream<T>(Stream<T> source) =>
      source.handleError(_rethrowMapped);

  Never _rethrowMapped(Object error) {
    if (error is Failure) throw error;
    throw mapDatabaseError(error);
  }

  List<DeckEntity> _mapDeckRows(List<Deck> rows) =>
      rows.map(deckEntityFromRow).toList(growable: false);

  @override
  Future<Deck> _requireDeckRow(String deckId) async {
    final row = await _dao.deckById(deckId);
    if (row == null) {
      throw const NotFoundFailure(message: 'That deck no longer exists.');
    }

    return row;
  }

  @override
  Future<Card> _requireCardRow(String cardId) async {
    final row = await _dao.cardById(cardId);
    if (row == null) {
      throw const NotFoundFailure(message: 'That card no longer exists.');
    }

    return row;
  }

  void _requireRealScheduler(SchedulerType schedulerType) {
    if (schedulerType != SchedulerType.unknown) return;

    // BR-11 — the choice is mandatory and `unknown` is not a choice.
    throw const ValidationFailure(
      message: 'Please choose a study mode for the deck.',
      fieldErrors: <String, String>{
        'schedulerType': 'A study mode must be chosen.',
      },
    );
  }

  /// Reads a deck's content type, refusing to operate on a value this build
  /// does not understand — altering such a deck could contradict rules a
  /// newer schema attached to it.
  @override
  DeckContentType _knownContentType(Deck deck) {
    final type = DeckContentType.fromDbValue(deck.contentType);
    if (type == DeckContentType.unknown) {
      throw const ConflictFailure(
        message: 'This deck was made by a newer version of the app.',
      );
    }

    return type;
  }
}
