/// The file shapes card transfer speaks (UC-10). `.apkg`, `.xls`, JSON and
/// media archives are deliberately absent — not advertised, not resolved.
///
/// One enum for both directions: import decodes these today, and an export
/// encoder added later extends the same axis rather than inventing a second
/// format vocabulary. The value is *representation only* — nothing about
/// cards, decks or scheduling may depend on which of these carried the rows.
enum CardTransferFormat {
  csv('csv', 'text/csv'),
  tsv('tsv', 'text/tab-separated-values'),
  xlsx(
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  const CardTransferFormat(this.fileExtension, this.mimeType);

  /// The extension an export writes (BR-180), without the dot.
  ///
  /// **A member, not a switch somewhere else.** Format dispatch belongs to the
  /// decoder and encoder resolvers alone (AD-20); a filename builder that
  /// switched on format to pick `.csv` would be a third registry, free to
  /// disagree with them. `.tab` is accepted on the way *in* by [fromFileName]
  /// and is deliberately never written on the way out — one spelling per
  /// format keeps exported files predictable.
  final String fileExtension;

  /// What the artifact declares itself to be when it is handed to the OS
  /// (BR-181). Here for the same reason as [fileExtension].
  final String mimeType;

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
