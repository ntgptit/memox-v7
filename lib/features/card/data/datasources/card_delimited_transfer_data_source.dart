import 'dart:convert';

import 'package:csv/csv.dart';

import '../../../../core/error/failure.dart';
import '../../domain/failures/card_transfer_failure.dart';
import '../../domain/models/card_transfer_document_model.dart';
import '../../domain/models/card_transfer_field_model.dart';
import 'card_transfer_resolver_data_source.dart';

/// Comma — what a `.csv` file is written with, and what detection falls back
/// to when the body names no delimiter at all.
const String _commaDelimiter = ',';

/// Tab — the `.tsv` contract, pinned on both sides.
const String _tabDelimiter = '\t';

/// The delimiters detection considers, in the order the `csv` package's own
/// detector considered them. The same four on purpose: a file with no header
/// row still decodes exactly as it did before this detector existed.
const List<String> _detectableDelimiters = <String>[
  _commaDelimiter,
  ';',
  _tabDelimiter,
  '|',
];

/// How much of the body the header probe reads.
///
/// A canonical header cell is one word — `front`, `pronunciation`, `labels` —
/// so the whole first row sits far inside this, and reading a prefix keeps
/// detection constant-time in the size of the file.
const int _headerProbeLimit = 8192;

/// How many lines the frequency fallback looks at, matching the detector this
/// one replaced so a headerless file scores identically.
const int _frequencyProbeLines = 10;

/// What one line of agreement with the line before it is worth.
const int _consistencyBonus = 2;

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
  const CardDelimitedTransferDataSource.tab() : _fieldDelimiter = _tabDelimiter;

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
      fieldDelimiter: _fieldDelimiter ?? detectDelimiter(body),
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

  /// Which delimiter [body] is written with (BR-176).
  ///
  /// **The header row decides; frequency only breaks ties.** The detector this
  /// replaced scored candidates purely by how often each character occurred,
  /// and that loses to the app's own export: BR-169 joins tags with `;`, BR-94
  /// allows ten of them, and nine semicolons in one cell outvote the five
  /// commas that hold the six columns apart. The file this app wrote then
  /// decoded as semicolon-delimited, the header row came back as a single
  /// cell, and auto-map could not recognise its own canonical spellings —
  /// export → import, the one round trip BR-176 guarantees, was broken by
  /// content that is entirely legal.
  ///
  /// Counting canonical headers fixes it without pinning `.csv` to a comma:
  /// a semicolon-delimited file from a European Excel still wins, because
  /// under `;` *its* first row resolves six fields and under `,` it resolves
  /// one. The structure of the header row is evidence no frequency count has,
  /// and it is evidence about exactly the question being asked.
  ///
  /// Frequency remains the answer when the header row proves nothing — a file
  /// with no header at all (UC-10 lets the user say so), or one whose columns
  /// are named in words auto-map does not know. Those score zero on every
  /// candidate and fall through to the original behaviour unchanged.
  static String detectDelimiter(String body) {
    final candidates = _detectableDelimiters
        .where(body.contains)
        .toList(growable: false);
    if (candidates.isEmpty) return _commaDelimiter;

    var best = _commaDelimiter;
    var bestHeaders = -1;
    var bestFrequency = -1;
    for (final candidate in candidates) {
      final headers = _canonicalHeaderCount(body, candidate);
      final frequency = _frequencyScore(body, candidate);
      final isBetter =
          headers > bestHeaders ||
          (headers == bestHeaders && frequency > bestFrequency);
      if (!isBetter) continue;

      best = candidate;
      bestHeaders = headers;
      bestFrequency = frequency;
    }

    return best;
  }
}

/// How many cells of [body]'s first row name a canonical field under
/// [delimiter].
///
/// Split rather than parsed: a header auto-map recognises is a single word, so
/// it can hold neither the delimiter nor a newline, and running the whole CSV
/// parser four times to read one row would make detection cost what decoding
/// costs. Surrounding quotes are stripped because a writer may quote every
/// cell it emits.
int _canonicalHeaderCount(String body, String delimiter) {
  final probe = body.length > _headerProbeLimit
      ? body.substring(0, _headerProbeLimit)
      : body;
  final lineEnd = probe.indexOf(_lineTerminator);
  final firstLine = lineEnd == -1 ? probe : probe.substring(0, lineEnd);

  var found = 0;
  for (final cell in firstLine.split(delimiter)) {
    if (CardTransferField.fromHeader(_unquote(cell)) == null) continue;

    found += 1;
  }

  return found;
}

String _unquote(String cell) {
  final trimmed = cell.trim();
  final isQuoted =
      trimmed.length >= 2 && trimmed.startsWith('"') && trimmed.endsWith('"');
  if (!isQuoted) return trimmed;

  return trimmed.substring(1, trimmed.length - 1);
}

/// The original frequency score, reproduced so a headerless file decodes
/// exactly as it did before: occurrences over the first ten lines, plus a
/// bonus each time a line holds as many as the line before it.
int _frequencyScore(String body, String delimiter) {
  final lines = body.split(_lineTerminator);
  final limit = lines.length > _frequencyProbeLines
      ? _frequencyProbeLines
      : lines.length;

  var total = 0;
  var bonus = 0;
  var previous = -1;
  for (var i = 0; i < limit; i++) {
    final count = delimiter.allMatches(lines[i]).length;
    if (count == 0) continue;

    total += count;
    if (previous == count) bonus += _consistencyBonus;
    previous = count;
  }

  return total + bonus;
}

final RegExp _lineTerminator = RegExp(r'\r\n|\r|\n');

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
