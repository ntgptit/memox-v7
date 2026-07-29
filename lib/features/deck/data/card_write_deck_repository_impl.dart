part of 'deck_repository_impl.dart';

/// The card half of [DeckRepositoryImpl] — same class, same library, split
/// out only so each source file stays readable. The abstract private members
/// below are satisfied by the class in `deck_repository_impl.dart`.
mixin _CardWriteOperations implements DeckRepository {
  DeckDao get _dao;
  String Function() get _idGenerator;
  DateTime Function() get _clock;

  Future<T> _guard<T>(Future<T> Function() action);
  Stream<T> _guardStream<T>(Stream<T> source);
  Future<Deck> _requireDeckRow(String deckId);
  Future<Card> _requireCardRow(String cardId);
  DeckContentType _knownContentType(Deck deck);

  @override
  Stream<List<CardEntity>> watchCardsByDeck(String deckId) =>
      _guardStream(_dao.watchCardsByDeck(deckId)).map(
        (List<Card> rows) =>
            rows.map(cardEntityFromRow).toList(growable: false),
      );

  @override
  Future<CardEntity> createCard({
    required String deckId,
    required String front,
    required String back,
  }) => _guard(
    () => _dao.runInTransaction(() async {
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
        await _dao.updateDeckById(
          deck.id,
          DecksCompanion(
            contentType: Value<String>(DeckContentType.card.dbValue),
            updatedAt: Value<DateTime>(now),
          ),
        );
      }

      final id = _idGenerator();
      await _dao.insertCard(
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
      await _dao.insertReviewState(_initialReviewState(id, scheduler));

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
    await _dao.updateCardById(
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
    await _dao.deleteCardById(cardId);
  });

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
