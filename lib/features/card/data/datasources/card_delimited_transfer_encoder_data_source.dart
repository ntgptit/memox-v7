import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../../domain/models/card_transfer_encoder_model.dart';
import '../../domain/models/card_transfer_record_model.dart';

/// Comma — the CSV contract.
///
/// **Writing it is not enough to be read back as it.** The decoder detects the
/// delimiter of a `.csv` file rather than assuming one, so what makes the round
/// trip hold is that detection reads the header row first — a tags cell full of
/// semicolons used to outvote the commas holding the columns apart, and the
/// file this class writes stopped being readable by the importer this app
/// ships. `CardDelimitedTransferDataSource.detectDelimiter` owns that half of
/// the contract; `card_export_round_trip_test.dart` pins the pair.
const String _commaDelimiter = ',';

/// Tab — the `.tsv` contract, pinned on both sides.
const String _tabDelimiter = '\t';

/// The delimited-text encode strategy: CSV and TSV, one implementation
/// (M99.21) — the mirror of `CardDelimitedTransferDataSource`.
///
/// The two formats differ only by delimiter, so they are two configurations of
/// one class rather than two classes, exactly as they are on the decode side.
///
/// **Nothing here joins or escapes by hand.** Quoting is the `csv` package's
/// contract: a cell holding the delimiter, a quote, a CR or an LF comes back
/// quoted, and a quote inside it comes back doubled. A hand-rolled `join` is
/// where round-trip bugs live, and it is the one thing a test written by the
/// same hand would not catch.
///
/// Text stays text. Cells are already `String`s by the time they arrive
/// (`cardTransferCellsOf`), and the decoder leaves `dynamicTyping` off — so
/// `001` stays `001`, `1e3` stays `1e3` and `+84 912 345 678` stays a phone
/// number rather than becoming a `double` on the way back in.
///
/// UTF-8 with a BOM (BR-179): symmetric with the encodings import accepts
/// (BR-173), and the reason a Korean or Vietnamese export opens correctly in
/// Excel instead of as mojibake.
final class CardDelimitedTransferEncoderDataSource
    implements CardTransferEncoder {
  const CardDelimitedTransferEncoderDataSource.comma()
    : _fieldDelimiter = _commaDelimiter;

  const CardDelimitedTransferEncoderDataSource.tab()
    : _fieldDelimiter = _tabDelimiter;

  final String _fieldDelimiter;

  @override
  Uint8List encode(List<CardTransferRecord> records) {
    final rows = <List<String>>[
      cardTransferHeaderRow,
      for (final record in records) cardTransferCellsOf(record),
    ];

    final text = CsvEncoder(
      fieldDelimiter: _fieldDelimiter,
      addBom: true,
    ).convert(rows);

    return Uint8List.fromList(utf8.encode(text));
  }
}
