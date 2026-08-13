import '../../domain/models/card_transfer_encoder_model.dart';
import '../../domain/models/card_transfer_format_model.dart';
import 'card_delimited_transfer_encoder_data_source.dart';
import 'card_xlsx_transfer_encoder_data_source.dart';

/// The encode registry: the one place a format chooses its encoder (M99.21).
///
/// The mirror of `cardTransferDecoderFor`, and deliberately a **second**
/// registry rather than a mode of the first (AD-20): import and export are two
/// pipelines, and a single function that both decoded and encoded would be one
/// object with two reasons to change. Every [CardTransferFormat] resolves here
/// exhaustively, so adding a format fails to compile until it is decided — and
/// nowhere else in the feature may switch on format. CSV and TSV share one
/// strategy, configured apart only by their delimiter.
CardTransferEncoder cardTransferEncoderFor(CardTransferFormat format) =>
    switch (format) {
      CardTransferFormat.csv =>
        const CardDelimitedTransferEncoderDataSource.comma(),
      CardTransferFormat.tsv =>
        const CardDelimitedTransferEncoderDataSource.tab(),
      CardTransferFormat.xlsx => const CardXlsxTransferEncoderDataSource(),
    };
