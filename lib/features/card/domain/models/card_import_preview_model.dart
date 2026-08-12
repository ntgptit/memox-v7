import '../failures/card_validation_failure.dart';
import '../failures/tag_validation_failure.dart';
import 'card_transfer_record_model.dart';

/// What one source row turned out to be (UC-10 step 5).
enum CardImportRowStatus {
  /// Valid and not a duplicate — will be written.
  ready,

  /// Broke a card rule (BR-169); the problems say which.
  invalid,

  /// Same folded front+back as a card already in the target deck (BR-170).
  duplicateExisting,

  /// Same folded front+back as an earlier row of this source (BR-170).
  duplicateInFile,

  /// Every cell empty — skipped without being an error (BR-169).
  blank,
}

/// The duplicate identity BR-170 measures: the folded pair, as a record.
///
/// A record, not a joined string: any separator scheme rests on the unstated
/// invariant that the separator never occurs in text, and nothing enforces
/// that — `("a", "b\u0000c")` and `("a\u0000b", "c")` join identically under
/// a NUL. Structural equality has no separator to collide on, and the type
/// makes "what is a key" a compiler question rather than a convention.
typedef CardImportDuplicateKey = ({String frontFolded, String backFolded});

/// One construction point, so the preview, the commit recheck and every test
/// agree on what "the same card" means.
CardImportDuplicateKey cardImportDuplicateKey({
  required String frontFolded,
  required String backFolded,
}) => (frontFolded: frontFolded, backFolded: backFolded);

/// Import's reading of a canonical record: its duplicate identity. An
/// extension rather than a member because the key is BR-170's — import
/// policy — while the record itself is direction-neutral content.
extension CardImportRecordIdentity on CardTransferRecord {
  CardImportDuplicateKey get duplicateKey => cardImportDuplicateKey(
    frontFolded: front.folded,
    backFolded: back.folded,
  );
}

/// One row of the preview list: its source number, what it showed, and why
/// it got the status it did. Carries display summaries, not the full content
/// — the preview is a checkpoint, not an editor.
final class CardImportRowPreview {
  const CardImportRowPreview({
    required this.sourceRowNumber,
    required this.status,
    required this.front,
    required this.back,
    this.cardProblems = const <CardValidationProblem>{},
    this.tagProblems = const <TagValidationProblem>{},
  });

  final int sourceRowNumber;
  final CardImportRowStatus status;

  /// The raw cell text, trimmed — shown even for invalid rows so the user
  /// can see what was there. Empty when the cell was.
  final String front;
  final String back;

  /// Typed reasons, reusing the card editor's vocabulary (BR-169) so the
  /// copy is written once. Empty unless [status] is
  /// [CardImportRowStatus.invalid].
  final Set<CardValidationProblem> cardProblems;
  final Set<TagValidationProblem> tagProblems;
}

/// Everything step 5 shows and step 7 commits: per-row verdicts for the
/// list, the surviving canonical records for the batch, and the counts the
/// summary prints.
final class CardImportPreview {
  const CardImportPreview({
    required this.rows,
    required this.records,
    required this.totalRows,
    required this.readyCount,
    required this.duplicateCount,
    required this.invalidCount,
    required this.blankCount,
  });

  final List<CardImportRowPreview> rows;

  /// Every valid record in source order — duplicates included, because the
  /// commit applies the policy against the database as it stands then
  /// (BR-170), not against this snapshot.
  final List<CardTransferRecord> records;

  /// Data rows in the source, after the header row if one was declared.
  final int totalRows;

  final int readyCount;
  final int duplicateCount;
  final int invalidCount;
  final int blankCount;

  /// How many cards the Import button would write under [shouldIncludeDuplicates]
  /// — the number its label prints, and the number that gates Continue
  /// (UC-10 E3).
  int importableCount({required bool shouldIncludeDuplicates}) =>
      shouldIncludeDuplicates ? readyCount + duplicateCount : readyCount;
}
