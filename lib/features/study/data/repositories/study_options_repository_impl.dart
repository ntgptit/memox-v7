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
    );
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
