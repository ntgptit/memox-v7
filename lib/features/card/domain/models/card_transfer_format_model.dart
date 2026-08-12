/// The file shapes card transfer speaks (UC-10). `.apkg`, `.xls`, JSON and
/// media archives are deliberately absent — not advertised, not resolved.
///
/// One enum for both directions: import decodes these today, and an export
/// encoder added later extends the same axis rather than inventing a second
/// format vocabulary. The value is *representation only* — nothing about
/// cards, decks or scheduling may depend on which of these carried the rows.
enum CardTransferFormat {
  csv,
  tsv,
  xlsx;

  /// The format [fileName]'s extension claims, or null when it is none of the
  /// three. Case-insensitive, because pickers return whatever the provider
  /// stored.
  static CardTransferFormat? fromFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return null;

    return switch (fileName.substring(dot + 1).toLowerCase()) {
      'csv' => CardTransferFormat.csv,
      'tsv' || 'tab' => CardTransferFormat.tsv,
      'xlsx' => CardTransferFormat.xlsx,
      _ => null,
    };
  }
}
