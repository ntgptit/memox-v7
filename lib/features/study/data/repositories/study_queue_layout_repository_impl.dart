part of 'study_repository_impl.dart';

/// Laying a session out: which cards it takes, and how a stage deals its first
/// round.
///
/// **Split from `study_queue_repository_impl.dart` at the guard's 400-line
/// limit, and the seam is a real one.** Everything here runs exactly once, when
/// a session opens; everything left there runs once per answer. They share a
/// library because they share a transaction, which is a reason to share a
/// library rather than a file.
mixin _StudyQueueLayoutOperations {
  StudyDao get _dao;
  Random get _random;

  /// The card set for a session — one set, never both (BR-142).
  Future<List<StudyCardModel>> _cardsFor({
    required String rootDeckId,
    required StudySessionKind kind,
    required int cardLimit,
    required NewCardOrder newCardOrder,
    required DateTime now,
  }) async {
    if (kind == StudySessionKind.reviewing) {
      final due = await _dao.dueCards(rootDeckId, now, cardLimit);

      return due.map((row) => studyCardModelFromRow(row.c)).toList();
    }

    // `random` shuffles **before** the ceiling, and that ordering is the rule
    // rather than a detail. BR-113 gives every stage its own shuffle, so the
    // order this list is in never reaches the user — the only thing
    // `new_card_order` can decide is *which* new cards enter the session when
    // the deck has more than the limit. Shuffling after `LIMIT` reorders a set
    // already chosen by `created_at`, which is the same set every time: the
    // option looked implemented and did nothing at all. It stays in Dart
    // because `RANDOM()` in SQL cannot be seeded, and a shuffle no test can pin
    // is a shuffle nobody can check.
    if (newCardOrder == NewCardOrder.created) {
      final fresh = await _dao.newCards(rootDeckId, cardLimit);

      return fresh.map((row) => studyCardModelFromRow(row.c)).toList();
    }

    final all = await _dao.allNewCards(rootDeckId);
    final cards = all.map((row) => studyCardModelFromRow(row.c)).toList()
      ..shuffle(_random);

    return cards.take(cardLimit).toList();
  }

  /// Round 1 of a stage: every card the stage can use, in an order of its own.
  ///
  /// **A card the mode cannot use gets no row at all** (BR-114). That is the
  /// difference between "skipped" and "stuck": with no row here, it has nothing
  /// left pending in this stage, so it finishes the learning chain alongside the
  /// others (BR-144). `fill` is the mode this matters for — `example` is
  /// optional, and an earlier reading would have frozen every card without one.
  ///
  /// Two independent shuffles per stage keep BR-117 true: sharing one order
  /// across stages would make the second stage a re-run of the first.
  ///
  /// [direction] is the session's choice (BR-182), and this is where BR-184
  /// happens: a `mixed` session hands each row its own direction, once, from the
  /// injected generator. A fixed choice gives every row the same one, and a null
  /// choice leaves the column alone.
  List<StudyQueueItemsCompanion> _roundOne({
    required String sessionId,
    required StudyMode mode,
    required List<StudyCardModel> cards,
    StudySessionDirection? direction,
  }) {
    final handler = studyModeHandler(mode);

    // A stage that cannot run on this card set gets no rows at all (BR-99).
    // With none it is exhausted from the start, so the session advances past it
    // — the same path a `fill` stage takes when no card carries an example. The
    // alternative, which is what used to happen, is a stage full of rows whose
    // widget renders nothing and a session with nowhere to go.
    if (!(handler?.canRunOn(cards) ?? false)) {
      return const <StudyQueueItemsCompanion>[];
    }

    final usable = <StudyCardModel>[
      for (final card in cards)
        if (handler!.canTake(card)) card,
    ]..shuffle(_random);

    final directions = _directionsFor(
      mode: mode,
      direction: direction,
      count: usable.length,
    );

    return <StudyQueueItemsCompanion>[
      for (final (index, card) in usable.indexed)
        StudyQueueItemsCompanion.insert(
          sessionId: sessionId,
          mode: mode.dbValue,
          cardId: card.id,
          position: index,
          status: 'pending',
          direction: Value<String?>(directions?[index].dbValue),
        ),
    ];
  }

  /// One direction per row of this stage, or null when the stage has none.
  ///
  /// **The `self_assess` gate is here rather than only at the caller**, and it is
  /// structural rather than defensive: BR-182 makes the direction a property of
  /// *how a card is asked*, and only `self_assess` asks that way. A stage that
  /// shows both faces at once (BR-112) could not honour a direction if it wanted
  /// to.
  ///
  /// **An exhaustive `switch`, not `fixedDirection` plus a null check.** Reading
  /// null as "mixed" makes [StudySessionDirection.unknown] deal a mixed hand
  /// silently — a value nothing owns, quietly given a behaviour. Naming all four
  /// makes a fifth a compile error, which is the check the null test cannot make.
  List<StudyRecallDirection>? _directionsFor({
    required StudyMode mode,
    required StudySessionDirection? direction,
    required int count,
  }) {
    if (direction == null || mode != StudyMode.selfAssess) return null;

    // BR-184: `mixed` is assigned once, here, from the injected generator — the
    // same one that shuffled the round above, and the reason a test can pin both.
    return switch (direction) {
      StudySessionDirection.koreanToMeaning =>
        List<StudyRecallDirection>.filled(
          count,
          StudyRecallDirection.koreanToMeaning,
        ),
      StudySessionDirection.meaningToKorean =>
        List<StudyRecallDirection>.filled(
          count,
          StudyRecallDirection.meaningToKorean,
        ),
      StudySessionDirection.mixed => assignMixedDirections(
        count: count,
        random: _random,
      ),
      StudySessionDirection.unknown => null,
    };
  }
}
