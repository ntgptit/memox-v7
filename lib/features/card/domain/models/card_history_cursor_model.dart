/// Where the next page of a card's history starts (BR-241).
///
/// **The value of the last row read, not a row number.** History is written
/// newest-first and a review can land while the reader is paging, so an
/// `OFFSET` would push a row that has already been shown down into the next
/// page and render it twice. A cursor made of the last row's own sort key is
/// immune to how many rows arrived above it — that is the whole reason BR-241
/// names keyset pagination rather than "page 2".
///
/// **Both halves, because `answered_at` alone is not unique.** Two turns of the
/// same session can share a millisecond; `id` is the tie-break that makes the
/// order total, and it has to travel with the timestamp or the page boundary
/// falls inside a group of equal timestamps and loses rows.
///
/// A domain value, not a Drift row: nothing above `data/` ever sees what the
/// statement actually selected.
class CardHistoryCursor {
  const CardHistoryCursor({required this.answeredAt, required this.id});

  /// The `answered_at` of the last row of the previous page.
  final DateTime answeredAt;

  /// The `id` of that same row.
  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardHistoryCursor &&
          other.answeredAt == answeredAt &&
          other.id == id;

  @override
  int get hashCode => Object.hash(answeredAt, id);

  /// Deliberately without the id or the timestamp: a cursor points at a review
  /// of a private card, and BR-51 keeps that out of every log line.
  @override
  String toString() => 'CardHistoryCursor(<redacted>)';
}
