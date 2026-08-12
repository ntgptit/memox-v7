import '../failures/card_validation_failure.dart';
import '../failures/tag_validation_failure.dart';
import '../models/card_import_preview_model.dart';
import '../models/card_transfer_document_model.dart';
import '../models/card_transfer_field_model.dart';
import '../models/card_transfer_mapping_model.dart';
import '../models/card_transfer_record_model.dart';
import '../models/card_text_model.dart';
import '../models/tag_name_model.dart';
import '../repositories/card_import_repository.dart';

/// Builds the preview for one sheet under one mapping (UC-10 step 5).
///
/// One repository read — the target deck's existing duplicate keys — then a
/// pure pass over the rows. The classification itself is [classifyImportRows],
/// a function rather than a method so the parser fixtures can unit-test every
/// rule without a repository in the room. This is *not* the check that
/// protects the write: BR-170's recheck runs again inside the commit
/// transaction, because the database is free to change between here and there.
final class BuildCardImportPreviewUseCase {
  const BuildCardImportPreviewUseCase(this._repository);

  final CardImportRepository _repository;

  Future<CardImportPreview> call({
    required String deckId,
    required CardTransferSheet sheet,
    required CardTransferMapping mapping,
    required bool hasHeaderRow,
  }) async {
    final existingKeys = await _repository.readExistingDuplicateKeys(deckId);

    return classifyImportRows(
      sheet: sheet,
      mapping: mapping,
      hasHeaderRow: hasHeaderRow,
      existingKeys: existingKeys,
    );
  }
}

/// BR-169 and BR-170 applied to every row, in source order.
///
/// Validation is the card's own: `CardText.parse`, `CardDetailText.parse` and
/// `TagName.parse` — the same calls a manual create makes, so this file states
/// no rule of its own and cannot drift from the editor. A cell the mapping
/// does not reach (short row) reads as empty, which is how an inconsistent
/// column count surfaces as `missingFront`/`missingBack` on that row instead
/// of a crash.
CardImportPreview classifyImportRows({
  required CardTransferSheet sheet,
  required CardTransferMapping mapping,
  required bool hasHeaderRow,
  required Set<CardImportDuplicateKey> existingKeys,
}) {
  final dataRows = hasHeaderRow && sheet.rows.isNotEmpty
      ? sheet.rows.sublist(1)
      : sheet.rows;

  final rows = <CardImportRowPreview>[];
  final records = <CardTransferRecord>[];
  final seenInFile = <CardImportDuplicateKey>{};
  var ready = 0, duplicates = 0, invalid = 0, blank = 0;

  String cellOf(CardTransferRow row, CardTransferField field) {
    final column = mapping.columnOf(field);
    if (column == null || column >= row.cells.length) return '';

    return row.cells[column].trim();
  }

  for (final row in dataRows) {
    final front = cellOf(row, CardTransferField.front);
    final back = cellOf(row, CardTransferField.back);

    if (row.isBlank) {
      blank += 1;
      rows.add(
        CardImportRowPreview(
          sourceRowNumber: row.sourceRowNumber,
          status: CardImportRowStatus.blank,
          front: front,
          back: back,
        ),
      );
      continue;
    }

    final parsedFront = CardText.parse(front, side: CardSide.front);
    final parsedBack = CardText.parse(back, side: CardSide.back);
    final parsedExample = CardDetailText.parse(
      cellOf(row, CardTransferField.example),
      field: CardDetailField.example,
    );
    final parsedHint = CardDetailText.parse(
      cellOf(row, CardTransferField.hint),
      field: CardDetailField.hint,
    );
    final parsedPronunciation = CardDetailText.parse(
      cellOf(row, CardTransferField.pronunciation),
      field: CardDetailField.pronunciation,
    );
    final tags = _parseTagsCell(cellOf(row, CardTransferField.tags));

    final cardProblems = <CardValidationProblem>{
      ?parsedFront.problem,
      ?parsedBack.problem,
      ?parsedExample.problem,
      ?parsedHint.problem,
      ?parsedPronunciation.problem,
    };

    if (cardProblems.isNotEmpty || tags.problems.isNotEmpty) {
      invalid += 1;
      rows.add(
        CardImportRowPreview(
          sourceRowNumber: row.sourceRowNumber,
          status: CardImportRowStatus.invalid,
          front: front,
          back: back,
          cardProblems: cardProblems,
          tagProblems: tags.problems,
        ),
      );
      continue;
    }

    final frontText = parsedFront.text!;
    final backText = parsedBack.text!;
    final key = cardImportDuplicateKey(
      frontFolded: frontText.folded,
      backFolded: backText.folded,
    );
    // Existing wins over in-file: a row that collides with the deck is a
    // duplicate of the deck even if an earlier row already collided too.
    final status = existingKeys.contains(key)
        ? CardImportRowStatus.duplicateExisting
        : seenInFile.contains(key)
        ? CardImportRowStatus.duplicateInFile
        : CardImportRowStatus.ready;
    seenInFile.add(key);

    final isDuplicate = status != CardImportRowStatus.ready;
    isDuplicate ? duplicates += 1 : ready += 1;

    rows.add(
      CardImportRowPreview(
        sourceRowNumber: row.sourceRowNumber,
        status: status,
        front: front,
        back: back,
      ),
    );
    records.add(
      CardTransferRecord(
        sourceRowNumber: row.sourceRowNumber,
        front: frontText,
        back: backText,
        example: parsedExample.text,
        hint: parsedHint.text,
        pronunciation: parsedPronunciation.text,
        tags: tags.names,
      ),
    );
  }

  return CardImportPreview(
    rows: rows,
    records: records,
    totalRows: dataRows.length,
    readyCount: ready,
    duplicateCount: duplicates,
    invalidCount: invalid,
    blankCount: blank,
  );
}

/// One tags cell → names, split on `;` (BR-169 — never a comma, CSV owns
/// commas), deduplicated by folded identity (BR-93), capped at
/// [kMaxTagsPerCard] (BR-94).
({List<TagName> names, Set<TagValidationProblem> problems}) _parseTagsCell(
  String cell,
) {
  final names = <TagName>[];
  final problems = <TagValidationProblem>{};
  final seen = <String>{};

  for (final piece in cell.split(kCardTransferTagsSeparator)) {
    // A blank piece — a trailing `;` or a double `;;` — is spacing, not an
    // empty-name error the way an empty tag *form* is.
    if (piece.trim().isEmpty) continue;
    final parsed = TagName.parse(piece);
    final name = parsed.name;
    if (name == null) {
      problems.add(parsed.problem!);
      continue;
    }
    if (!seen.add(name.folded)) continue;
    names.add(name);
  }

  if (names.length > kMaxTagsPerCard) {
    problems.add(TagValidationProblem.tooManyTags);
  }

  return (names: names, problems: problems);
}
