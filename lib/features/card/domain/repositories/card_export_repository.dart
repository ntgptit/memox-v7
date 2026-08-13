import '../models/card_export_scope_model.dart';
import '../models/card_transfer_record_model.dart';

/// One consistent read of everything an export needs (BR-177).
///
/// The deck name and the records travel together because they are read
/// together. Two reads are two snapshots, and a file whose name came from
/// before a rename while its rows came from after it is a file nobody can
/// explain (AD-13, "one interaction is not one statement").
final class CardExportSnapshot {
  const CardExportSnapshot({required this.deckName, required this.records});

  /// Raw, as stored. Sanitizing it for a file name happens in
  /// `card_export_file_name_model.dart`, once.
  final String deckName;

  /// Already in BR-177's order — `created_at ASC` with an `id ASC` tie-break,
  /// for **both** scopes — with each record's tags already sorted by folded
  /// name. Everything downstream may take the order as given, which is what
  /// makes "the same data produces the same bytes" a property of one place.
  ///
  /// Content only (BR-175): the canonical record carries no id, timestamp,
  /// flag, scheduler, box, interval, due date, `learned_at`, history or
  /// session, so no read here can leak one into a file.
  final List<CardTransferRecord> records;
}

/// The database half of card export (UC-11 step 4).
///
/// One of the deliberately narrow contracts AD-20 keeps apart: this one reads,
/// the encoder encodes, and [CardExportDestinationRepository] talks to the OS.
/// It knows nothing about file formats, bytes, file names or share sheets.
///
/// **Read-only, by contract** (BR-178). Nothing here writes: not card content,
/// not `updated_at` or any other timestamp, not the deck's `content_type`, not
/// study state, review history, sessions, flags or tag relations. A successful
/// export also leaves the caller's selection alone — BR-167 clears a selection
/// after a *mutation*, and this is not one.
abstract interface class CardExportRepository {
  /// Reads [scope] of [deckId] in one consistent statement (BR-177).
  ///
  /// Typed failures for everything UC-11 refuses on: an empty result
  /// (`CardExportProblem.emptyScope`), a selected id that no longer exists or
  /// no longer belongs to this deck — which fails the **whole** request rather
  /// than exporting the rest (`staleSelection`, BR-174) — a deleted deck
  /// (`deckMissing`), and a read that failed (`readFailed`).
  Future<CardExportSnapshot> readSnapshot({
    required String deckId,
    required CardExportScope scope,
  });
}
