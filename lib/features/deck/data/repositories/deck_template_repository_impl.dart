import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../domain/models/deck_content_type_model.dart';
import '../../domain/models/deck_template_model.dart';
import '../../domain/models/scheduler_type_model.dart';
import '../../domain/repositories/deck_template_repository.dart';
import '../datasources/deck_template_dao.dart';
import '../mappers/deck_template_seed_mapper.dart';

/// A copied root starts where any new root starts (BR-40).
const int _initialSchedulerVersion = 1;
const int _initialSchedulerGeneration = 1;

/// Drift-backed [DeckTemplateRepository].
///
/// **The whole copy is one transaction and the idempotency check is inside it
/// (BR-37, BR-39).** Checking first and writing after leaves a window: two
/// startups, or a test installing the same template twice concurrently, both
/// read "absent" and both write. Inside the transaction the second one sees the
/// first one's root.
///
/// **It writes cards without going through `CardRepositoryImpl`.** That is not a
/// boundary being crossed — `cards` and `card_review_states` are core schema,
/// not the card feature's private data — and it is required: the copy has to be
/// atomic, and two repositories cannot share one transaction. What it must not
/// do is re-derive card rules, so the row shapes come from
/// `deck_template_seed_mapper.dart`, beside the deck mapper, and the review
/// state follows BR-09's table exactly as the card feature's own seed does.
final class DeckTemplateRepositoryImpl implements DeckTemplateRepository {
  DeckTemplateRepositoryImpl(
    this._dao, {
    required DateTime Function() clock,
    String Function()? idGenerator,
  }) : _idGenerator = idGenerator ?? const Uuid().v4,
       // Same trade as `DeckRepositoryImpl`: a named parameter may not start
       // with an underscore, and the field stays private.
       // ignore: prefer_initializing_formals
       _clock = clock;

  final DeckTemplateDao _dao;
  final String Function() _idGenerator;
  final DateTime Function() _clock;

  @override
  Future<DeckTemplateInstallOutcome> installTemplate(
    DeckTemplate template, {
    SchedulerType? schedulerType,
  }) async {
    try {
      return await _dao.runInTransaction(() async {
        final existing = await _dao.countCopiesOf(
          templateId: template.templateId,
          version: template.version,
        );
        if (existing > 0) return DeckTemplateInstallOutcome.alreadyPresent;

        await _copy(template, schedulerType ?? template.defaultSchedulerType);

        return DeckTemplateInstallOutcome.installed;
      });
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw mapDatabaseError(error);
    }
  }

  Future<void> _copy(DeckTemplate template, SchedulerType scheduler) async {
    final now = _clock();
    final rootId = _idGenerator();

    // The root: its own root_deck_id, `deck` content type, scheduler columns
    // filled (BR-58, BR-06), and the two columns that make this install
    // idempotent next launch (BR-34).
    await _dao.insertDeck(
      DecksCompanion.insert(
        id: rootId,
        name: template.title.value,
        rootDeckId: rootId,
        contentType: DeckContentType.deck.dbValue,
        schedulerType: Value<String?>(scheduler.dbValue),
        schedulerVersion: const Value<int?>(_initialSchedulerVersion),
        schedulerGeneration: const Value<int?>(_initialSchedulerGeneration),
        sourceTemplateId: Value<String?>(template.templateId),
        sourceTemplateVersion: Value<int?>(template.version),
        createdAt: now,
        updatedAt: now,
      ),
    );

    for (final child in template.children) {
      await _copyNode(
        child,
        parentDeckId: rootId,
        rootDeckId: rootId,
        scheduler: scheduler,
        now: now,
      );
    }
  }

  Future<void> _copyNode(
    DeckTemplateNode node, {
    required String parentDeckId,
    required String rootDeckId,
    required SchedulerType scheduler,
    required DateTime now,
  }) async {
    final deckId = _idGenerator();
    // The content type is settled by what the node holds, not discovered later
    // by a first-child lock: the whole tree is written at once, so there is no
    // "first child" moment to hook. An empty leaf stays `unset`, which is the
    // same state an empty deck the user made would be in (BR-62).
    final contentType = switch ((node.isLeaf, node.cards.isEmpty)) {
      (true, true) => DeckContentType.unset,
      (true, false) => DeckContentType.card,
      _ => DeckContentType.deck,
    };

    await _dao.insertDeck(
      DecksCompanion.insert(
        id: deckId,
        name: node.name.value,
        parentDeckId: Value<String?>(parentDeckId),
        rootDeckId: rootDeckId,
        contentType: contentType.dbValue,
        createdAt: now,
        updatedAt: now,
      ),
    );

    for (final card in node.cards) {
      final cardId = _idGenerator();
      await _dao.insertCard(
        templateCardCompanion(card, cardId: cardId, deckId: deckId, now: now),
      );
      // Exactly one study state per card, born with it and due_at NULL (BR-09).
      await _dao.insertReviewState(
        templateReviewStateCompanion(
          cardId,
          scheduler: (
            type: scheduler,
            version: _initialSchedulerVersion,
            generation: _initialSchedulerGeneration,
          ),
        ),
      );
    }

    for (final child in node.children) {
      await _copyNode(
        child,
        parentDeckId: deckId,
        rootDeckId: rootDeckId,
        scheduler: scheduler,
        now: now,
      );
    }
  }
}
