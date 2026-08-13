import 'package:flutter/material.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/failures/card_transfer_failure.dart';
import '../../../domain/failures/card_validation_failure.dart';
import '../../../domain/failures/tag_validation_failure.dart';
import '../../../domain/models/card_import_preview_model.dart';
import '../../../domain/models/card_transfer_field_model.dart';
import 'card_failure_labels_widget.dart';

/// Every enum-to-copy switch the import wizard needs, in one place — the
/// counterpart of `card_failure_labels_widget.dart` for the import
/// vocabulary. Exhaustive switches, so a new problem value fails to compile
/// until it has copy in both locales.
extension CardImportLabels on BuildContext {
  /// A parse or pick refusal (UC-10 E1/E2). Typed problems get their own
  /// operational copy; anything else falls back to the shared write-failure
  /// line — never the failure's diagnostic message (BR-173).
  String cardImportFailureLabel(Failure failure) {
    final problem = failure is ValidationFailure
        ? failure.problems.whereType<CardTransferProblem>().firstOrNull
        : null;
    if (problem == null) return cardWriteFailure(failure);

    return switch (problem) {
      CardTransferProblem.unsupportedFile =>
        l10n.cardImportErrorUnsupportedFile,
      CardTransferProblem.invalidEncoding =>
        l10n.cardImportErrorInvalidEncoding,
      CardTransferProblem.emptySource => l10n.cardImportErrorEmptySource,
      CardTransferProblem.emptySheet => l10n.cardImportErrorEmptySheet,
      CardTransferProblem.unreadableFile => l10n.cardImportErrorUnreadableFile,
    };
  }

  String cardImportRowStatusLabel(CardImportRowStatus status) =>
      switch (status) {
        CardImportRowStatus.ready => l10n.cardImportRowStatusReadyLabel,
        CardImportRowStatus.invalid => l10n.cardImportRowStatusInvalidLabel,
        CardImportRowStatus.duplicateExisting =>
          l10n.cardImportRowStatusDuplicateExistingLabel,
        CardImportRowStatus.duplicateInFile =>
          l10n.cardImportRowStatusDuplicateInFileLabel,
        CardImportRowStatus.blank => l10n.cardImportRowStatusBlankLabel,
      };

  String cardImportFieldLabel(CardTransferField field) => switch (field) {
    CardTransferField.front => l10n.cardImportFieldFrontLabel,
    CardTransferField.back => l10n.cardImportFieldBackLabel,
    CardTransferField.example => l10n.cardImportFieldExampleLabel,
    CardTransferField.hint => l10n.cardImportFieldHintLabel,
    CardTransferField.pronunciation => l10n.cardImportFieldPronunciationLabel,
    CardTransferField.tags => l10n.cardImportFieldTagsLabel,
  };

  /// One invalid row's reason line — the first problem, in the card editor's
  /// own words (BR-169's "no second validation" applied to the copy too).
  String cardImportRowIssueLabel(CardImportRowPreview row) {
    final cardProblem = row.cardProblems.firstOrNull;
    if (cardProblem != null) {
      return switch (cardProblem) {
        CardValidationProblem.frontEmpty => l10n.cardFrontEmptyError,
        CardValidationProblem.frontTooLong => l10n.cardFrontTooLongError,
        CardValidationProblem.backEmpty => l10n.cardBackEmptyError,
        CardValidationProblem.backTooLong => l10n.cardBackTooLongError,
        CardValidationProblem.exampleTooLong ||
        CardValidationProblem.hintTooLong ||
        CardValidationProblem.pronunciationTooLong =>
          l10n.cardDetailTooLongError,
      };
    }

    return switch (row.tagProblems.firstOrNull) {
      TagValidationProblem.nameTooLong ||
      TagValidationProblem.nameEmpty => l10n.cardImportRowIssueTagTooLong,
      // Its own sentence rather than the `tooManyTags` catch-all: the row is
      // refused for what a name *contains*, and "More than 10 tags" would send
      // the user to count tags that are already within the cap (BR-93).
      TagValidationProblem.nameHasControlCharacter =>
        l10n.cardImportRowIssueTagCharacter,
      TagValidationProblem.tooManyTags ||
      _ => l10n.cardImportRowIssueTooManyTags,
    };
  }

  /// The stable no-header column name (UC-10 A3): A, B, …, Z, AA, AB, …
  String cardImportColumnLabel(int column) =>
      l10n.cardImportColumnFallbackLabel(_columnLetters(column));

  /// KB below a megabyte, MB above — the two units a spreadsheet plausibly
  /// arrives in. Rounded up so nothing reads as "0 KB". Shared because the
  /// same file line renders on the Source step and again as Preview's
  /// context (M4.12 states 1–2).
  String cardImportFileSizeLabel(int bytes) {
    const int kilobyte = 1024;
    const int megabyte = kilobyte * kilobyte;
    if (bytes >= megabyte) {
      return l10n.cardImportFileSizeMegabytes((bytes / megabyte).ceil());
    }

    return l10n.cardImportFileSizeKilobytes(
      bytes < kilobyte ? 1 : (bytes / kilobyte).ceil(),
    );
  }
}

String _columnLetters(int column) {
  var index = column;
  final letters = StringBuffer();
  do {
    letters.write(String.fromCharCode('A'.codeUnitAt(0) + (index % 26)));
    index = index ~/ 26 - 1;
  } while (index >= 0);

  return letters.toString().split('').reversed.join();
}
