import 'dart:convert';

import 'package:csv/csv.dart';

import '../../../../core/error/failure.dart';
import '../../domain/failures/card_transfer_failure.dart';
import '../../domain/models/card_transfer_document_model.dart';
import 'card_transfer_resolver_data_source.dart';

/// The delimited-text strategy: CSV and TSV, one implementation (M99.19).
///
/// The two formats differ only in delimiter contract — `.tsv` pins a tab,
/// CSV and pasted text detect among the delimiters the decoder supports
/// (comma, semicolon, tab, pipe) — so they are two configurations of one
/// class, not two classes. Quoted cells, escaped quotes, and commas or
/// newlines inside quotes are the csv package's contract, exercised by the
/// parser fixtures; nothing here splits by hand.
///
/// Bytes decode as UTF-8 or UTF-8 BOM only (BR-173); anything else refuses
/// with guidance rather than guessing an encoding and importing mojibake.
final class CardDelimitedTransferDataSource implements CardTransferDecoder {
  /// Delimiter detected from the content — the CSV and pasted-text contract.
  const CardDelimitedTransferDataSource.detect() : _fieldDelimiter = null;

  /// Delimiter pinned to a tab — the `.tsv` contract.
  const CardDelimitedTransferDataSource.tab() : _fieldDelimiter = '\t';

  final String? _fieldDelimiter;

  @override
  CardTransferDocument decodeBytes(List<int> bytes) =>
      decodeText(_decodeUtf8(bytes));

  /// The text half, shared with the paste path (which never had bytes).
  CardTransferDocument decodeText(String text) {
    // The text path never saw the byte decoder, so strip a pasted BOM too.
    final body = text.startsWith('﻿') ? text.substring(1) : text;
    if (body.trim().isEmpty) {
      return const CardTransferDocument(sheets: <CardTransferSheet>[]);
    }

    // Empty lines are kept as rows so `sourceRowNumber` stays the number the
    // user's own editor shows — the blank-row skip is BR-169's, counted
    // where the user can see it, not the parser's, silent.
    // Text stays text: `dynamicTyping` (csv 8's name for the csv<=6
    // `shouldParseNumbers` contract) is left at its false default and is
    // pinned by the textual-values regression tests — "001" is a word
    // somebody typed, "1e3" is a front, "+84" starts a phone number, and a
    // decoder that parses them into numbers hands back "1000.0"-shaped
    // strings the user never wrote.
    final decoder = CsvDecoder(
      fieldDelimiter: _fieldDelimiter,
      skipEmptyLines: false,
    );

    // `Object?` cells rather than the csv package's untyped rows: nothing
    // here calls into a cell, only stringifies it.
    List<List<Object?>> parsed;
    try {
      parsed = decoder.convert(body);
    } on Exception {
      throw const ValidationFailure(
        message: 'The text could not be read as delimited rows.',
        problems: <Enum>{CardTransferProblem.unreadableFile},
      );
    }

    return CardTransferDocument(
      sheets: <CardTransferSheet>[
        CardTransferSheet(
          name: '',
          rows: <CardTransferRow>[
            for (var i = 0; i < parsed.length; i++)
              CardTransferRow(
                sourceRowNumber: i + 1,
                cells: <String>[
                  for (final cell in parsed[i]) cell?.toString() ?? '',
                ],
              ),
          ],
        ),
      ],
    );
  }
}

String _decodeUtf8(List<int> bytes) {
  const bom = <int>[0xEF, 0xBB, 0xBF];
  final body =
      bytes.length >= 3 &&
          bytes[0] == bom[0] &&
          bytes[1] == bom[1] &&
          bytes[2] == bom[2]
      ? bytes.sublist(3)
      : bytes;
  try {
    return utf8.decode(body);
  } on FormatException {
    throw const ValidationFailure(
      message: 'The file is not UTF-8 encoded.',
      problems: <Enum>{CardTransferProblem.invalidEncoding},
    );
  }
}
