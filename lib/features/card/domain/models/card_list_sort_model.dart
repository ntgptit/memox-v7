/// How the management list is ordered (D3).
///
/// **Orthogonal to the filter.** A filter narrows *which* cards; a sort decides
/// *in what order* — so every sort is available under every filter, and the two
/// combine without a query per pair. The SQL is one `$order` Dart template in
/// `card.drift`: drift inlines real ordering terms, so the emitted statement is
/// the same text a hand-written `ORDER BY` would produce and the composite index
/// still supplies the order (a `CASE`-based ORDER BY would not — it forces the
/// temp B-tree the index exists to avoid).
enum CardListSort {
  /// Newest first — the default, and the order UC-04 A4 needs: a card just added
  /// is at the top where the person who added it is looking.
  newest,

  /// Soonest due first. A card with no `due_at` is a new card, due immediately,
  /// and sorts to the front — which is what SQLite's NULLs-first ASC already
  /// does, so the rule needs no `COALESCE` to express.
  dueFirst,
}
