import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

/// Data access for the template-copy path (AD-07).
///
/// **Its own DAO rather than four more methods on `DeckDao`.** `DeckDao` serves
/// the deck screens; nothing there writes a card, and adding card inserts to it
/// would put the widest write in the app beside the reads a list rebuild runs
/// constantly. This one exists for a single transaction that runs at most once
/// per template per install.
final class DeckTemplateDao {
  DeckTemplateDao(this._db);

  final AppDatabase _db;

  /// Runs [action] atomically — the whole copy, check included (BR-37, BR-39).
  Future<T> runInTransaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  /// How many root decks already came from this exact template version.
  ///
  /// Counts rather than reads: the answer only ever decides "write or not", and
  /// a count avoids materialising a deck row nobody looks at. `> 0` rather than
  /// `== 1` on purpose — BR-38 lets a user deliberately add a second copy, and
  /// if they have, an automatic install must still stay out of the way.
  Future<int> countCopiesOf({
    required String templateId,
    required int version,
  }) async {
    final query = _db.selectOnly(_db.decks)
      ..addColumns(<Expression<Object>>[_db.decks.id.count()])
      ..where(
        _db.decks.sourceTemplateId.equals(templateId) &
            _db.decks.sourceTemplateVersion.equals(version),
      );
    final row = await query.getSingle();

    return row.read(_db.decks.id.count()) ?? 0;
  }

  Future<void> insertDeck(DecksCompanion deck) =>
      _db.into(_db.decks).insert(deck);

  Future<void> insertCard(CardsCompanion card) =>
      _db.into(_db.cards).insert(card);

  Future<void> insertReviewState(CardReviewStatesCompanion state) =>
      _db.into(_db.cardReviewStates).insert(state);
}
