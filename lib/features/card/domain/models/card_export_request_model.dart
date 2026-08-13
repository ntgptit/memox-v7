import 'card_export_scope_model.dart';
import 'card_transfer_format_model.dart';

/// One export, fully described (UC-11 step 3): which deck, how much of it, and
/// in which representation.
///
/// The three travel together because a retry has to repeat all three
/// unchanged (UC-11 E2, E3, E4) — an error that kept the scope but dropped the
/// format would silently export CSV for a user who asked for XLSX.
final class CardExportRequest {
  const CardExportRequest({
    required this.deckId,
    required this.scope,
    required this.format,
  });

  final String deckId;
  final CardExportScope scope;

  /// Representation only (AD-20): nothing about which cards are exported, in
  /// what order, or what the file holds may depend on this value.
  final CardTransferFormat format;
}
