import 'dart:typed_data';

import 'card_transfer_field_model.dart';
import 'card_transfer_format_model.dart';
import 'card_transfer_record_model.dart';
import 'card_transfer_tag_codec_model.dart';

/// One encode strategy: canonical records in, the bytes of one format out —
/// the mirror of `CardTransferDecoder` (AD-20).
///
/// **The contract sits in `domain/` while the decoder's sits in `data/`, and
/// that asymmetry is the honest one.** A decoder's only caller is the decode
/// repository, one file away in the same layer. An encoder's caller is
/// `ExportCardsUseCase`, which reads a snapshot and hands bytes to the
/// platform seam — so the contract has to be visible from `domain/` or the use
/// case would have to import `data/`, which is the dependency direction AD-12
/// exists to forbid. The implementations still live in `data/datasources/`
/// beside the decoders, because that is where the packages are.
///
/// An encoder knows nothing about Riverpod, the database, the picker, the
/// share sheet or a widget. It receives a list that is **already ordered**
/// (BR-177 makes ordering the repository's contract, not the schema's or the
/// encoder's) and turns it into bytes. It never re-sorts, never filters and
/// never decides what a row means.
abstract interface class CardTransferEncoder {
  Uint8List encode(List<CardTransferRecord> records);
}

/// How a caller gets the encoder for a format without switching on the format
/// itself.
///
/// The one implementation is the encoder resolver in `data/datasources/`, and
/// it holds the only `switch` over [CardTransferFormat] on the export side
/// (AD-20). A use case that switched here would be a second registry, free to
/// disagree with the first.
typedef CardTransferEncoderResolver =
    CardTransferEncoder Function(CardTransferFormat format);

/// The six canonical headers, in order, lowercase English, never localized
/// (BR-179).
///
/// Derived from the schema enum rather than written out, so the file's first
/// row cannot drift from the spellings auto-map recognises on the way back in.
List<String> get cardTransferHeaderRow => <String>[
  for (final field in CardTransferField.values) field.canonicalHeader,
];

/// One record as the six cells of a row, in the same order as
/// [cardTransferHeaderRow] (BR-175, BR-179).
///
/// **Shared by every encoder on purpose.** Serializing a record is a schema
/// question, not a format question — an optional field with no value is an
/// empty cell and not `null`, `-` or a placeholder, and the tags cell goes
/// through the one codec (BR-176). Letting each encoder answer those for
/// itself is how CSV and XLSX exports of the same deck end up disagreeing.
List<String> cardTransferCellsOf(CardTransferRecord record) => <String>[
  for (final field in CardTransferField.values) _cellOf(record, field),
];

String _cellOf(CardTransferRecord record, CardTransferField field) =>
    switch (field) {
      CardTransferField.front => record.front.value,
      CardTransferField.back => record.back.value,
      CardTransferField.example => record.example?.value ?? '',
      CardTransferField.hint => record.hint?.value ?? '',
      CardTransferField.pronunciation => record.pronunciation?.value ?? '',
      CardTransferField.tags => CardTransferTagCodec.encode(
        record.tags.map((tag) => tag.value),
      ),
    };
