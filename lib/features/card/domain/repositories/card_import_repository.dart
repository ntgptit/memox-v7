import '../models/card_import_preview_model.dart';
import '../models/card_import_result_model.dart';
import '../models/card_transfer_record_model.dart';

/// The commit payload: the canonical records the preview validated, and the
/// duplicate policy the user chose (BR-170). Everything in it already went
/// through the card value objects — a plan cannot carry unvalidated text.
final class CardImportPlan {
  const CardImportPlan({
    required this.records,
    required this.shouldIncludeDuplicates,
  });

  final List<CardTransferRecord> records;
  final bool shouldIncludeDuplicates;
}

/// The database half of card import (UC-10): duplicate keys out, one atomic
/// batch in. It speaks canonical records and knows nothing about file
/// formats, pickers or parsing — those live behind their own contracts, and
/// this implementation never imports a codec.
abstract interface class CardImportRepository {
  /// The duplicate identities already in [deckId], as typed
  /// [CardImportDuplicateKey] pairs — one read for the whole preview
  /// (BR-170), never a per-row query.
  Future<Set<CardImportDuplicateKey>> readExistingDuplicateKeys(String deckId);

  /// Writes the whole plan atomically (BR-171): target checks
  /// (BR-168), duplicate recheck under the plan's policy (BR-170), the
  /// cards, exactly one fresh study state each, tags created or reused by
  /// folded name, and the target's `content_type` when it was `unset`
  /// (BR-172). Any failure rolls the whole batch back; an empty effective
  /// batch writes nothing at all.
  Future<CardImportResult> commitImport({
    required String deckId,
    required CardImportPlan plan,
  });
}
