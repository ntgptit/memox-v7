part of 'study_repository_impl.dart';

/// The two-tier study options: the app-wide defaults, and a root deck-s
/// override of them (BR-147).
///
/// **Split out at the 400-line guard, along a seam that was already there.**
/// Nothing here touches a session, a queue or a card — it reads and writes a
/// preference, and the only reason it lived beside the session lifecycle is
/// that both hang off the same DAO.
mixin _StudyOptionsOperations {
  StudyDao get _dao;

  Future<StudyOptionsModel> effectiveOptions(String rootDeckId) async {
    final settings = await _dao.appSettings();
    final deck = await _dao.deckById(rootDeckId);

    // The override is read from the **root**, whichever deck was asked about.
    // A sub-deck carries no options of its own (BR-147), so resolving through
    // `root_deck_id` is the same move the scheduler columns make — and reading
    // the passed deck-s own column would silently return nothing from the
    // second level down.
    final root = deck == null || deck.rootDeckId == deck.id
        ? deck
        : await _dao.deckById(deck.rootDeckId) ?? deck;

    final override = studyOptionsOverrideFromJson(root?.studyConfig);

    return StudyOptionsModel(
      cardLimit: StudyCardLimit.fromStored(
        override.cardLimit ?? settings.cardLimit,
      ).value,
      newCardOrder:
          override.newCardOrder ??
          NewCardOrder.fromDbValue(settings.newCardOrder),
      // **Read from the parsed override, not from `root?.studyConfig != null`**
      // (BR-184). A column holding malformed JSON parses to "no override" and
      // the values above then come from the app defaults; reporting an override
      // anyway would offer a `Use app defaults` that changes nothing visible.
      isRootOverride: override != kNoStudyOptionsOverride,
    );
  }

  /// Drops the root's override so the tree follows the app-wide defaults again
  /// (BR-184).
  ///
  /// **[deckId] may be any deck in the tree; the write lands on its root** —
  /// the same resolution `saveStudyOptions` does, and for the same reason: a
  /// sub-deck carries no options, so clearing "this deck's" override from two
  /// levels down has to mean the root's.
  ///
  /// One `UPDATE` of one column. Nothing here can reach `card_study_states`,
  /// `study_answers`, a session or the scheduler columns, which is what makes
  /// "this is not Reset learning progress" a property of the code rather than a
  /// promise in a comment.
  Future<void> clearStudyOptionsOverride(String deckId) async {
    final deck = await _dao.deckById(deckId);
    if (deck == null) {
      throw const NotFoundFailure(message: 'Deck not found');
    }

    await _dao.clearDeckStudyConfig(deck.rootDeckId);
  }

  Future<void> saveStudyOptions({
    required String deckId,
    required StudyCardLimit cardLimit,
    required NewCardOrder newCardOrder,
  }) async {
    final deck = await _dao.deckById(deckId);
    if (deck == null) {
      throw const NotFoundFailure(message: 'Deck not found');
    }

    await _dao.updateDeckStudyConfig(
      deckId: deck.rootDeckId,
      studyConfig: studyOptionsOverrideToJson(
        cardLimit: cardLimit.value,
        newCardOrder: newCardOrder,
      ),
    );
  }
}
