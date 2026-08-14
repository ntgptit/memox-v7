part of 'card_repository_impl.dart';

/// The bulk half of [CardRepositoryImpl] — same class, same library, split out
/// only so each source file stays under the size guard.
///
/// **One primitive per operation, and the single-card API is a one-element
/// call into it** (BR-166). Two transaction paths for "move a card" and "move
/// these cards" is two chances to disagree about validation, and the one that
/// gets tested less is the one users hit.
///
/// Every method below opens exactly one transaction and reads what it needs
/// *inside* it. A validation that runs before the transaction is a check
/// against a database that may have changed by the time the write lands, which
/// is precisely the race BR-166's all-or-nothing is meant to exclude.
mixin _CardBulkOperations implements CardRepository {
  CardDao get _cardDao;
  CardDeckContextDao get _deckContextDao;
  DateTime Function() get _clock;
  String Function() get _idGenerator;

  Future<T> _guard<T>(Future<T> Function() action);

  @override
  Future<void> moveCards({
    required List<String> cardIds,
    required String targetDeckId,
  }) => _guard(
    () => _cardDao.runInTransaction(() async {
      if (cardIds.isEmpty) return;

      final target = await _requireDeckRow(targetDeckId);
      _refuseInvalidMoveTarget(target);

      final sources = await _readSourceDecks(cardIds, target: target);
      // Nothing to do, but not an error: a selection that already sits in the
      // target is a no-op the user experiences as success.
      if (sources.isEmpty) return;

      final now = _clock();
      await _cardDao.moveCardsToDeck(
        cardIds: cardIds,
        deckId: target.id,
        updatedAt: now,
      );

      // The target gains its first card (BR-62/BR-163) — same step as the move.
      if (_knownContentType(target) == DeckContentType.unset) {
        await _deckContextDao.updateDeckById(
          target.id,
          DecksCompanion(
            contentType: Value<String>(DeckContentType.card.dbValue),
            updatedAt: Value<DateTime>(now),
          ),
        );
      }
      // Every source that just lost its last card gives the type back.
      await _unsetEmptiedDecks(sources, now: now);
    }),
  );

  @override
  Future<void> deleteCards(List<String> cardIds) => _guard(
    () => _cardDao.runInTransaction(() async {
      if (cardIds.isEmpty) return;

      // Read the decks before the rows are gone: after the delete there is
      // nothing left to say where these cards lived.
      final rows = await _cardDao.cardDeckContextForIds(cardIds);
      _requireAllFound(cardIds, found: rows.length);
      final sources = <String>{for (final row in rows) row.deckId};
      await _cardDao.deleteCardsByIds(cardIds);
      await _unsetEmptiedDecks(sources, now: _clock());
    }),
  );

  @override
  Future<void> setCardsFlag({
    required List<String> cardIds,
    required bool isFlagged,
  }) => _guard(
    () => _cardDao.runInTransaction(() async {
      if (cardIds.isEmpty) return;

      // Setting a flag to the value it already carries is idempotent, so the
      // only thing worth reading first is whether the cards are still there:
      // a selection naming a deleted card is describing a database that has
      // moved on, and the caller must hear that rather than a silent success.
      final rows = await _cardDao.cardDeckContextForIds(cardIds);
      _requireAllFound(cardIds, found: rows.length);

      await _cardDao.setCardsFlagByIds(
        cardIds: cardIds,
        isFlagged: isFlagged,
        updatedAt: _clock(),
      );
    }),
  );

  @override
  Future<void> addTagToCards({
    required List<String> cardIds,
    required TagName name,
  }) => _guard(
    () => _cardDao.runInTransaction(() async {
      if (cardIds.isEmpty) return;

      // Reuse the tag owning this folded name (BR-93); mint one only if none.
      final owned = await _cardDao.tagByFoldedName(name.folded);
      final tagId = owned?.id ?? _idGenerator();

      // The cap counts only cards that would actually gain a tag: a card
      // already carrying it stays where it is, however full it is (BR-166).
      final alreadyTagged = await _cardDao.cardsAlreadyTagged(
        tagId: tagId,
        cardIds: cardIds,
      );
      final counts = await _cardDao.tagCountsForCards(cardIds);
      final gaining = cardIds.where((id) => !alreadyTagged.contains(id));
      final wouldOverflow = gaining.any(
        (String id) => (counts[id] ?? 0) >= kMaxTagsPerCard,
      );
      if (wouldOverflow) {
        // One card over the line refuses the batch — a partial tag is a state
        // the user cannot see and did not ask for (BR-166).
        refuseInvalidTag(<TagValidationProblem>{
          TagValidationProblem.tooManyTags,
        });
      }

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
      for (final cardId in gaining) {
        // Idempotent by the DAO's insert mode; `gaining` already skips the
        // rest, so this writes only what changes.
        await _cardDao.linkTag(cardId, tagId);
      }
    }),
  );

  @override
  Future<List<String>> readCardIdsMatching(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) => _guard(
    () => _cardDao.cardIdsMatching(
      deckId: deckId,
      filter: filter,
      searchTerm: searchTerm,
      now: now,
      tags: tags,
    ),
  );

  @override
  Stream<List<CardMoveTarget>> watchMoveTargets(String sourceDeckId) async* {
    // The root is read once, from the source: the query filters on it, and a
    // card cannot leave its tree anyway (BR-165), so a source that vanished
    // yields an empty list rather than an error the picker cannot act on.
    final source = await _deckContextDao.deckById(sourceDeckId);
    if (source == null) {
      yield const <CardMoveTarget>[];

      return;
    }

    yield* _deckContextDao
        .watchMoveTargets(
          rootDeckId: source.rootDeckId,
          sourceDeckId: sourceDeckId,
        )
        .map(
          (rows) => <CardMoveTarget>[
            for (final row in rows)
              CardMoveTarget(
                deckId: row.deckId,
                name: row.deckName,
                parentName: row.parentName,
              ),
          ],
        );
  }

  // ---- helpers -----------------------------------------------------------

  /// The move target, or a [NotFoundFailure] — read inside the transaction.
  Future<Deck> _requireDeckRow(String deckId) async {
    final deck = await _deckContextDao.deckById(deckId);
    if (deck == null) {
      throw const NotFoundFailure(message: 'That deck no longer exists.');
    }

    return deck;
  }

  /// BR-165's target rules, in the order a reader would ask them.
  void _refuseInvalidMoveTarget(Deck target) {
    if (target.parentDeckId == null) {
      throw const ConflictFailure(
        message: 'A top-level deck holds decks, not cards.',
        reason: CardConflictReason.moveTargetIsRoot,
      );
    }
    if (_knownContentType(target) == DeckContentType.deck) {
      throw const ConflictFailure(
        message: 'That deck holds decks, so it cannot hold cards.',
        reason: CardConflictReason.moveTargetHoldsDecks,
      );
    }
  }

  /// The decks the batch is leaving, having refused anything BR-165 forbids.
  ///
  /// Returns the distinct source decks **other than the target**, so a
  /// selection that already sits in the target contributes nothing rather than
  /// being reported as a same-deck move.
  Future<Set<String>> _readSourceDecks(
    List<String> cardIds, {
    required Deck target,
  }) async {
    final rows = await _cardDao.cardDeckContextForIds(cardIds);
    _requireAllFound(cardIds, found: rows.length);

    final sources = <String>{};
    for (final row in rows) {
      if (row.rootDeckId != target.rootDeckId) {
        throw const ConflictFailure(
          message: 'A card cannot move to a deck in another tree.',
          reason: CardConflictReason.moveCrossRoot,
        );
      }
      if (row.deckId != target.id) sources.add(row.deckId);
    }
    if (sources.isEmpty && rows.length == 1) {
      // A single card already in the target: say so rather than report a
      // silent success, because the caller asked for a move.
      throw const ConflictFailure(
        message: 'The card is already in that deck.',
        reason: CardConflictReason.moveTargetIsSameDeck,
      );
    }

    return sources;
  }

  /// Refuses a batch naming a card that is not there.
  ///
  /// A missing id means the selection is describing a database that has moved
  /// on — deleting or moving "the rest" would act on a set the user never saw.
  void _requireAllFound(List<String> cardIds, {required int found}) {
    if (found == cardIds.length) return;

    throw const NotFoundFailure(message: 'That card no longer exists.');
  }

  /// Puts every deck in [deckIds] back to `unset` if it now holds nothing
  /// (BR-163). Counted after the write, inside the same transaction.
  Future<void> _unsetEmptiedDecks(
    Set<String> deckIds, {
    required DateTime now,
  }) async {
    for (final deckId in deckIds) {
      if (await _cardDao.directCardCount(deckId) > 0) continue;

      final deck = await _deckContextDao.deckById(deckId);
      // A root never holds cards (BR-58), so it never reaches this branch
      // legitimately; the guard keeps a corrupt row from being "repaired"
      // into a root without a content type.
      if (deck == null || deck.parentDeckId == null) continue;

      await _deckContextDao.updateDeckById(
        deckId,
        DecksCompanion(
          contentType: Value<String>(DeckContentType.unset.dbValue),
          updatedAt: Value<DateTime>(now),
        ),
      );
    }
  }

  /// The deck's content type, or a typed refusal for a value this build does
  /// not know — the same helper the create path uses.
  DeckContentType _knownContentType(Deck deck);
}
