import 'card_text_model.dart';
import 'tag_name_model.dart';

/// Stage 3 of the pipeline: one canonical, validated card-content record.
///
/// Parsed through the same value objects a manual create uses — `CardText`,
/// `CardDetailText`, `TagName` (BR-169) — so nothing downstream ever looks
/// at the text again. It is the input to preview classification, duplicate
/// detection and the atomic commit today, and the shape a future export
/// encoder serializes from.
///
/// **Content only, by contract** (see `card_transfer_field_model.dart`): no
/// ids, no timestamps, no scheduler or study state. That absence is what
/// makes export-then-import a content transfer rather than a backup.
final class CardTransferRecord {
  const CardTransferRecord({
    required this.front,
    required this.back,
    required this.tags,
    this.example,
    this.hint,
    this.pronunciation,
    this.sourceRowNumber,
  });

  final CardText front;
  final CardText back;
  final CardDetailText? example;
  final CardDetailText? hint;
  final CardDetailText? pronunciation;
  final List<TagName> tags;

  /// Where the record came from, when it came from a file — the preview
  /// names rows by it. Null for records that never had a source row, which
  /// is what a future export produces.
  final int? sourceRowNumber;
}
