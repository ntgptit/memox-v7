/// What kind of thing a deletion batch is about (BR-182, BR-192).
///
/// The **item root** — what the user actually touched — not what the batch
/// happens to contain. Deleting a deck marks cards too, and the batch is still
/// a deck batch: it is restored as a deck, to a deck target, and the Trash row
/// reads as a deck.
///
/// This is what BR-192 splits a multi-selection on, so it is a stored column
/// rather than something derived from what the batch holds — a deck batch that
/// happens to contain no cards is still a deck batch, and a derived answer
/// would call it neither.
enum TrashItemType {
  card('card'),
  deck('deck');

  const TrashItemType(this.dbValue);

  /// The value stored in `delete_batches.item_type`.
  final String dbValue;

  /// Maps a stored value to the enum, or null for one this build does not know.
  ///
  /// Null rather than a throw: Trash is the screen a user opens when something
  /// has already gone wrong, and a row written by a newer build must make it
  /// unreadable rather than uncloseable. The repository drops such a row.
  static TrashItemType? fromDbValue(String value) {
    for (final type in values) {
      if (type.dbValue == value) return type;
    }

    return null;
  }
}
