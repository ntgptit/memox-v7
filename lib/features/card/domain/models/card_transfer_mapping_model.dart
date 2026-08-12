import 'card_transfer_field_model.dart';

/// Which source column feeds which canonical field (UC-10 step 4).
///
/// Ignore is the absence of an assignment, not a seventh field value — an
/// enum member meaning "none" would make every exhaustive switch carry a
/// branch that does nothing.
///
/// **One destination, one column — held structurally.** [assign] removes the
/// field from whatever column held it before adding the new pair, so the
/// "mapping trùng destination" state BR-169 forbids cannot be represented,
/// and no validator has to look for it. The same shape makes "Front and Back
/// on one column" unrepresentable too.
final class CardTransferMapping {
  const CardTransferMapping._(this._byColumn);

  const CardTransferMapping.empty()
    : _byColumn = const <int, CardTransferField>{};

  /// Auto-map from a header row (UC-10 step 4): the canonical spellings,
  /// case-insensitive, first occurrence wins — a file with two "front"
  /// columns maps one and leaves the duplicate for the user to see.
  factory CardTransferMapping.fromHeader(List<String> header) {
    final byColumn = <int, CardTransferField>{};
    final taken = <CardTransferField>{};
    for (var column = 0; column < header.length; column++) {
      final field = CardTransferField.fromHeader(header[column]);
      if (field == null || !taken.add(field)) continue;
      byColumn[column] = field;
    }

    return CardTransferMapping._(
      Map<int, CardTransferField>.unmodifiable(byColumn),
    );
  }

  final Map<int, CardTransferField> _byColumn;

  CardTransferField? fieldOf(int column) => _byColumn[column];

  /// The column feeding [field], or null when it is unmapped.
  int? columnOf(CardTransferField field) {
    for (final entry in _byColumn.entries) {
      if (entry.value == field) return entry.key;
    }

    return null;
  }

  /// Reassigns [column]: null means Ignore. The field is first taken away
  /// from any other column, which is what keeps a destination single-owner.
  CardTransferMapping assign(int column, CardTransferField? field) {
    final byColumn = <int, CardTransferField>{..._byColumn}..remove(column);
    if (field != null) {
      byColumn.removeWhere((_, CardTransferField held) => held == field);
      byColumn[column] = field;
    }

    return CardTransferMapping._(
      Map<int, CardTransferField>.unmodifiable(byColumn),
    );
  }

  /// BR-169's gate for Continue: both required fields have a column.
  bool get isComplete =>
      columnOf(CardTransferField.front) != null &&
      columnOf(CardTransferField.back) != null;
}
