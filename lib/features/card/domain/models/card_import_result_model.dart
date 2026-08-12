/// What one committed import did (UC-10 step 8).
final class CardImportResult {
  const CardImportResult({
    required this.imported,
    required this.duplicatesSkipped,
  });

  /// Zero writes happened at all when this is zero (BR-171) — the deck's
  /// content type included.
  final int imported;

  /// Rows the in-transaction recheck skipped under the chosen policy
  /// (BR-170). May exceed the preview's count: the database moves between
  /// preview and commit, and the recheck is the one that decides.
  final int duplicatesSkipped;
}
