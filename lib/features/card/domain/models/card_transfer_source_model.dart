import 'dart:typed_data';

import 'card_transfer_format_model.dart';

/// Where transfer rows come from: a picked file or pasted text (UC-10).
///
/// Sealed so the decode boundary dispatches exhaustively — a third source
/// kind fails to compile until every switch has answered for it. Plain Dart
/// on purpose: bytes and strings are values, and holding them here is what
/// lets parsing run without knowing pickers or clipboards exist.
sealed class CardTransferSource {
  const CardTransferSource();
}

/// A picked file: its display name, raw bytes and the format its extension
/// declared. The bytes live in app memory only (BR-173) — no copy is written
/// anywhere, and [name] is never logged.
final class CardTransferFileSource extends CardTransferSource {
  const CardTransferFileSource({
    required this.name,
    required this.bytes,
    required this.format,
  });

  final String name;
  final Uint8List bytes;
  final CardTransferFormat format;
}

/// Pasted CSV or TSV rows (UC-10 A1). The delimiter is detected, not
/// declared: pasted text carries no extension to promise one.
final class CardTransferTextSource extends CardTransferSource {
  const CardTransferTextSource({required this.text});

  final String text;
}
