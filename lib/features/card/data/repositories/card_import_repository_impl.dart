import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../deck/domain/models/deck_content_type_model.dart';
import '../../../deck/domain/models/scheduler_type_model.dart';
import '../../domain/failures/card_conflict_failure.dart';
import '../../domain/failures/card_not_found_failure.dart';
import '../../domain/models/card_import_preview_model.dart';
import '../../domain/models/card_import_result_model.dart';
import '../../domain/models/card_transfer_record_model.dart';
import '../../domain/models/tag_name_model.dart';
import '../../domain/repositories/card_import_repository.dart';
import '../datasources/card_deck_context_dao.dart';
import '../datasources/card_import_dao.dart';
import '../mappers/card_study_state_seed_mapper.dart';

/// Drift-backed [CardImportRepository] — the commit half only (M99.19).
///
/// Builds both of its DAOs from the one [AppDatabase] it is handed, for the
/// reason `CardRepositoryImpl` states: the target checks, the duplicate
/// recheck and the content-type step must share one transaction with the
/// batch, and ready-made adapters would let a root hand it two databases.
///
/// It speaks canonical records and rows; no picker, no parser, no format —
/// those are the other two contracts' business, and keeping them out is
/// what `card_transfer_boundary_test.dart` pins.
final class CardImportRepositoryImpl implements CardImportRepository {
  CardImportRepositoryImpl(
    AppDatabase database, {
    required DateTime Function() clock,
    String Function()? idGenerator,
  }) : _importDao = CardImportDao(database),
       _deckDao = CardDeckContextDao(database),
       _idGenerator = idGenerator ?? const Uuid().v4,
       // A named parameter can't start with `_`, so the formal is impossible.
       // ignore: prefer_initializing_formals
       _clock = clock;

  final CardImportDao _importDao;
  final CardDeckContextDao _deckDao;
  final String Function() _idGenerator;
  final DateTime Function() _clock;

  @override
  Future<Set<CardImportDuplicateKey>> readExistingDuplicateKeys(
    String deckId,
  ) => _guard(() => _readDuplicateKeys(deckId));

  @override
  Future<CardImportResult> commitImport({
    required String deckId,
    required CardImportPlan plan,
  }) => _guard(
    () => _importDao.runInTransaction(() async {
      // Target checks re-run here (BR-168): the deck was validated when the
      // wizard opened, but preview time is not write time.
      final deck = await _requireDeckRow(deckId);
      if (deck.parentDeckId == null) {
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

      // Duplicate recheck inside the transaction (BR-170): the database is
      // free to have changed since the preview, and the policy the user chose
      // is applied to what is true now.
      final existingKeys = await _readDuplicateKeys(deckId);
      final seenInBatch = <CardImportDuplicateKey>{};
      final toWrite = <CardTransferRecord>[];
      var duplicatesSkipped = 0;
      for (final entry in plan.records) {
        final key = entry.duplicateKey;
        final isDuplicate =
            existingKeys.contains(key) || seenInBatch.contains(key);
        seenInBatch.add(key);
        if (isDuplicate && !plan.shouldIncludeDuplicates) {
          duplicatesSkipped += 1;
          continue;
        }
        toWrite.add(entry);
      }

      // Nothing effective to write → no mutation of any kind (BR-171),
      // the content type included (BR-172).
      if (toWrite.isEmpty) {
        return CardImportResult(
          imported: 0,
          duplicatesSkipped: duplicatesSkipped,
        );
      }

      // The scheduler resolves once for the batch (BR-171), from the root
      // (BR-57), before any write.
      final scheduler = await _resolveRootScheduler(deck.rootDeckId);
      final now = _clock();

      if (deckType == DeckContentType.unset) {
        // First content locks the deck to 'card', batch edition (BR-62,
        // BR-172) — same transaction, same as a manual first card.
        await _deckDao.updateDeckById(
          deck.id,
          DecksCompanion(
            contentType: Value<String>(DeckContentType.card.dbValue),
            updatedAt: Value<DateTime>(now),
          ),
        );
      }

      final batch = _buildBatch(
        entries: toWrite,
        deckId: deck.id,
        scheduler: scheduler,
        now: now,
        existingTags: await _importDao.tagsByFoldedNames(
          _distinctFoldedTagNames(toWrite),
        ),
      );
      await _importDao.insertImportBatch(
        cards: batch.cards,
        states: batch.states,
        tags: batch.tags,
        links: batch.links,
      );

      return CardImportResult(
        imported: toWrite.length,
        duplicatesSkipped: duplicatesSkipped,
      );
    }),
  );

  /// Every companion of one commit, built in memory before any insert: cards,
  /// exactly one fresh study state per card via the same seed mapper a manual
  /// create uses (BR-09, BR-171), tags minted only for folded names the
  /// database does not hold (BR-93), and the links.
  ({
    List<CardsCompanion> cards,
    List<CardStudyStatesCompanion> states,
    List<TagsCompanion> tags,
    List<CardTagsCompanion> links,
  })
  _buildBatch({
    required List<CardTransferRecord> entries,
    required String deckId,
    required ({SchedulerType type, int version, int generation}) scheduler,
    required DateTime now,
    required List<Tag> existingTags,
  }) {
    final tagIdByFolded = <String, String>{
      for (final tag in existingTags) tag.nameFolded: tag.id,
    };
    final mintedTags = <TagsCompanion>[];
    final cards = <CardsCompanion>[];
    final states = <CardStudyStatesCompanion>[];
    final links = <CardTagsCompanion>[];

    for (final entry in entries) {
      final cardId = _idGenerator();
      cards.add(
        CardsCompanion.insert(
          id: cardId,
          deckId: deckId,
          front: entry.front.value,
          back: entry.back.value,
          frontFolded: Value<String>(entry.front.folded),
          backFolded: Value<String>(entry.back.folded),
          example: Value<String?>(entry.example?.value),
          hint: Value<String?>(entry.hint?.value),
          pronunciation: Value<String?>(entry.pronunciation?.value),
          createdAt: now,
          updatedAt: now,
        ),
      );
      states.add(initialReviewStateFromScheduler(cardId, scheduler));

      for (final TagName tag in entry.tags) {
        var tagId = tagIdByFolded[tag.folded];
        if (tagId == null) {
          tagId = _idGenerator();
          tagIdByFolded[tag.folded] = tagId;
          mintedTags.add(
            TagsCompanion.insert(
              id: tagId,
              name: tag.value,
              nameFolded: tag.folded,
              createdAt: now,
            ),
          );
        }
        links.add(CardTagsCompanion.insert(cardId: cardId, tagId: tagId));
      }
    }

    return (cards: cards, states: states, tags: mintedTags, links: links);
  }

  List<String> _distinctFoldedTagNames(List<CardTransferRecord> entries) =>
      <String>{
        for (final entry in entries)
          for (final TagName tag in entry.tags) tag.folded,
      }.toList(growable: false);

  Future<Set<CardImportDuplicateKey>> _readDuplicateKeys(String deckId) async {
    final rows = await _importDao.cardKeysInDeck(deckId);

    return <CardImportDuplicateKey>{
      for (final row in rows)
        cardImportDuplicateKey(
          frontFolded: row.frontFolded,
          backFolded: row.backFolded,
        ),
    };
  }

  Future<Deck> _requireDeckRow(String deckId) async {
    final row = await _deckDao.deckById(deckId);
    if (row == null) {
      throw const NotFoundFailure(
        message: 'That deck no longer exists.',
        reason: CardNotFoundReason.deckGone,
      );
    }

    return row;
  }

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

  /// The root's scheduler, via `root_deck_id` (BR-57), read once per commit.
  Future<({SchedulerType type, int version, int generation})>
  _resolveRootScheduler(String rootDeckId) async {
    final root = await _requireDeckRow(rootDeckId);
    final typeValue = root.schedulerType;
    final version = root.schedulerVersion;
    final generation = root.schedulerGeneration;
    if (typeValue == null || version == null || generation == null) {
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
