import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../domain/models/deck_content_type_model.dart';
import '../../domain/models/deck_deletion_impact_model.dart';
import '../../domain/models/deck_detail_model.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/failures/deck_conflict_failure.dart';
import '../../domain/failures/deck_move_failure.dart';
import '../../domain/failures/deck_validation_failure.dart';
import '../../domain/models/deck_name_model.dart';
import '../../domain/repositories/deck_repository.dart';
import '../../domain/models/root_deck_list_snapshot_model.dart';
import '../../domain/models/scheduler_type_model.dart';
import '../mappers/deck_mapper.dart';
import '../datasources/deck_dao.dart';

part 'move_deck_repository_impl.dart';

/// A fresh root deck starts at scheduler version 1, generation 1 (BR-40).
const int _initialSchedulerVersion = 1;
const int _initialSchedulerGeneration = 1;

/// Drift-backed [DeckRepository]. Card CRUD lives in `CardRepositoryImpl`.
///
/// This class is the boundary of two languages: below it, rows, companions and
/// Drift exceptions; above it, entities and [Failure]. Nothing from below
/// crosses up — every method runs inside [_guard], which rethrows domain
/// failures untouched and maps anything else through `mapDatabaseError`.
///
/// Multi-step writes — first-child content lock (BR-62), subtree move
/// (BR-71) — each run atomically: a thrown failure anywhere inside rolls back
/// every step. Depth guards (BR-55) run BEFORE any mutation, so a refused
/// write leaves no trace even mid-transaction. The move operation lives in
/// the part file as a private mixin, purely to keep each source file
/// readable; it is one class and one library.
final class DeckRepositoryImpl
    with _MoveDeckOperation
    implements DeckRepository {
  DeckRepositoryImpl(
    this._dao, {
    required DateTime Function() clock,
    String Function()? idGenerator,
  }) : _idGenerator = idGenerator ?? const Uuid().v4,
       // The initializing formal the lint asks for would be
       // `required this._clock`, and Dart forbids a named parameter starting
       // with an underscore. The field has to stay private — the move operation
       // is a `part of` this library and reads it.
       // ignore: prefer_initializing_formals
       _clock = clock;

  @override
  final DeckDao _dao;

  /// Client-generated UUIDs (AD-03); injectable so tests are deterministic.
  final String Function() _idGenerator;

  /// The clock, injected — there is no default.
  ///
  /// A `?? DateTime.now()` fallback here would make "now" have two owners: this
  /// private static, and `clockProvider` which the whole tree can override. The
  /// one that is harder to reach is the one that silently wins in production, so
  /// it is gone and the composition root passes the provider's clock in.
  /// Timestamps are stored in UTC, always.
  @override
  final DateTime Function() _clock;

  // ---- reads -------------------------------------------------------------

  @override
  Stream<List<DeckEntity>> watchRootDecks() =>
      _guardStream(_dao.watchRootDecks()).map(_mapDeckRows);

  @override
  Stream<RootDeckListSnapshot> watchRootDeckList({required DateTime now}) =>
      _guardStream(_dao.watchRootDeckSummaries(now)).map(rootDeckListFromRows);

  @override
  Stream<List<DeckEntity>> watchAllDecks() =>
      _guardStream(_dao.watchAllDecks()).map(_mapDeckRows);

  @override
  Stream<List<DeckEntity>> watchDeckTree(String rootDeckId) =>
      _guardStream(_dao.watchDecksInTree(rootDeckId)).map(_mapDeckRows);

  @override
  Stream<DeckDetail> watchDeckDetail(String deckId) =>
      _guardStream(_dao.watchDeckDetail(deckId)).map(deckDetailFromRows);

  // ---- writes ------------------------------------------------------------

  @override
  Future<DeckEntity> createRootDeck({
    required DeckName name,
    required SchedulerType schedulerType,
  }) => _guard(() async {
    // No name check. BR-01 was applied when the `DeckName` was constructed, and
    // checking it again here is what made three layers own one rule.
    _requireRealScheduler(schedulerType);

    final id = _idGenerator();
    final now = _clock();
    await _dao.insertDeck(
      DecksCompanion.insert(
        id: id,
        name: name.value,
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
    required DeckName name,
    required String parentDeckId,
  }) => _guard(
    () => _dao.runInTransaction(() async {
      final parent = await _requireDeckRow(parentDeckId);
      final parentType = _knownContentType(parent);
      if (parentType == DeckContentType.card) {
        throw const ConflictFailure(
          message: 'Refused: the parent already holds cards.',
          reason: DeckConflictReason.parentHoldsCards,
        );
      }
      // BR-55 — refused BEFORE the content lock below, so a rejected create
      // mutates nothing at all.
      final parentDepth = await _requireDeckDepth(parent.id);
      if (parentDepth >= DeckEntity.maxTreeDepth) {
        throw const ConflictFailure(
          message: 'Refused: the parent is already at the depth limit.',
          reason: DeckConflictReason.parentAtMaxDepth,
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
          name: name.value,
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
  Future<void> renameDeck({required String deckId, required DeckName name}) =>
      _guard(() async {
        await _requireDeckRow(deckId);
        await _dao.updateDeckById(
          deckId,
          DecksCompanion(
            name: Value<String>(name.value),
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
          message: 'Refused: the content type of a root deck is invariant.',
          reason: DeckConflictReason.rootContentTypeFixed,
        );
      }
      if (await _dao.directCardCount(deckId) > 0) {
        throw const ConflictFailure(
          message: 'Refused: the deck still holds cards.',
          reason: DeckConflictReason.deckStillHasCards,
        );
      }
      if (await _dao.directChildDeckCount(deckId) > 0) {
        throw const ConflictFailure(
          message: 'Refused: the deck still holds sub-decks.',
          reason: DeckConflictReason.deckStillHasSubDecks,
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

  void _requireRealScheduler(SchedulerType schedulerType) {
    if (schedulerType != SchedulerType.unknown) return;

    // BR-11 — the choice is mandatory and `unknown` is not a choice.
    // Reachable only when a caller passes `SchedulerType.unknown`, which no use
    // case does — the create-root use case refuses a null choice before this.
    // Kept as a boundary guard, and it reports the same typed problem the use
    // case would, so the screen has one shape to read.
    refuseInvalidDeckForm(<DeckValidationProblem>{
      DeckValidationProblem.schedulerMissing,
    });
  }

  /// Reads a deck's content type, refusing to operate on a value this build
  /// does not understand — altering such a deck could contradict rules a
  /// newer schema attached to it.
  @override
  DeckContentType _knownContentType(Deck deck) {
    final type = DeckContentType.fromDbValue(deck.contentType);
    if (type == DeckContentType.unknown) {
      throw const ConflictFailure(
        message:
            'Refused: stored content_type is not a value this build knows.',
        reason: DeckConflictReason.unknownContentType,
      );
    }

    return type;
  }

  /// The deck's level with the root as level 1 (BR-55).
  ///
  /// The walk is bounded one step past the allowed maximum: an intact chain
  /// within the limit always reaches its root inside that bound, so a probe
  /// that does not is a chain deeper than the app supports or a cyclic one —
  /// refused, never guessed at.
  @override
  Future<int> _requireDeckDepth(String deckId) async {
    final probe = await _dao.deckDepthProbe(
      deckId: deckId,
      maxWalk: DeckEntity.maxTreeDepth + 1,
    );
    if (probe == null || !probe.reachedRoot) {
      throw const ConflictFailure(
        message: 'Refused: the deck depth probe did not reach a root.',
        reason: DeckConflictReason.deckDepthUnknowable,
      );
    }

    return probe.depth;
  }

  /// The subtree's height with the deck itself as height 1 (BR-55).
  ///
  /// Same bounding rule as [_requireDeckDepth]: a height at the walk bound
  /// means "at least this tall" — taller than any tree the limit permits, or
  /// cyclic — and is refused.
  @override
  Future<int> _requireSubtreeHeight(String deckId) async {
    const maxWalk = DeckEntity.maxTreeDepth + 1;
    final height = await _dao.subtreeHeightProbe(
      deckId: deckId,
      maxWalk: maxWalk,
    );
    if (height == null || height >= maxWalk) {
      throw const ConflictFailure(
        message: 'Refused: the subtree height probe hit its walk bound.',
        reason: DeckConflictReason.subtreeHeightUnknowable,
      );
    }

    return height;
  }
}
