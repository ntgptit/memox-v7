import '../../../../core/database/app_database.dart';
import '../../../../core/error/drift_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../deck/domain/models/deck_content_type_model.dart';
import '../../domain/models/deck_context_model.dart';
import '../mappers/deck_context_mapper.dart';

/// Card-side reads of deck context, split out of `CardRepositoryImpl` to keep
/// each file inside the size guard.
///
/// Reads deck rows through the shared [AppDatabase] — never the deck feature's
/// data layer (AD-13), the same seam `CardDeckContextDao` draws for `createCard`.
/// Drift rows and exceptions stop here: the header read maps to a domain model,
/// and both surface a [Failure] rather than a `DriftException`.
final class DeckContextReadDataSource {
  DeckContextReadDataSource(this._db);

  final AppDatabase _db;

  /// The deck's name and ancestor breadcrumb for the list header (W1).
  ///
  /// `watchSingleOrNull` rather than `watchSingle`: a deck deleted while its card
  /// list is still routed to would make `watchSingle` error the stream, where the
  /// honest outcome is simply no header — so a null row emits nothing and the
  /// screen keeps its fallback title.
  Stream<DeckContextModel> watchDeckContext(String deckId) => _db
      .deckContextById(deckId)
      .watchSingleOrNull()
      .handleError(_rethrowMapped)
      .where((DeckContextByIdResult? row) => row != null)
      .map((DeckContextByIdResult? row) => deckContextFromRow(row!));

  /// Whether the deck holds cards (BR-63) — the router's auto-forward answer.
  ///
  /// A missing deck is `false`: there is nothing to forward into. An unrecognised
  /// `content_type` (a newer schema) is also `false` — the redirect stays put
  /// rather than guessing.
  Future<bool> readDeckHoldsCards(String deckId) async {
    try {
      final deck = await _db.deckById(deckId).getSingleOrNull();
      if (deck == null) return false;

      return DeckContentType.fromDbValue(deck.contentType) ==
          DeckContentType.card;
    } on Object catch (error) {
      throw mapDatabaseError(error);
    }
  }

  Never _rethrowMapped(Object error) {
    if (error is Failure) throw error;
    throw mapDatabaseError(error);
  }
}
