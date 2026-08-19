import '../../../../core/text/search_fold.dart';

/// What the user is looking for, normalised once (BR-248).
///
/// **The point of the type is that nothing downstream can be handed a raw
/// string.** The repository contract takes a `SearchQuery`, so "has this been
/// trimmed and folded, and by which rule?" is answered by the signature rather
/// than by reading the data layer — the same argument `DeckName`, `CardText` and
/// `TagName` make, applied to the one value that is compared against all three.
///
/// **Folding happens here and nowhere else.** A query folded a second time by a
/// DAO is one `toLowerCase()` away from disagreeing with the stored columns,
/// which is precisely the asymmetry `foldForSearch` exists to prevent.
///
/// [isEmpty] is the whole of BR-249: a query that normalises to nothing is not a
/// search, so no repository call and no statement is made for it. Whitespace is
/// therefore not a cheaper search — it is not a search at all.
final class SearchQuery {
  const SearchQuery._(this.raw, this.folded);

  /// The trimmed text as the user typed it. What an empty-result message echoes
  /// back; never what anything compares against.
  final String raw;

  /// [raw] through [foldForSearch] — the form every stored column is written in.
  final String folded;

  /// The empty search: no text, no repository read, no statement.
  static const SearchQuery empty = SearchQuery._('', '');

  /// Normalises [rawInput]. Total: every string is a valid query, and the ones
  /// that carry nothing land on [empty]'s meaning through [isEmpty].
  static SearchQuery parse(String rawInput) {
    final folded = foldForSearch(rawInput);
    if (folded.isEmpty) return empty;

    return SearchQuery._(rawInput.trim(), folded);
  }

  bool get isEmpty => folded.isEmpty;

  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) =>
      other is SearchQuery && other.folded == folded && other.raw == raw;

  @override
  int get hashCode => Object.hash(raw, folded);

  @override
  String toString() => raw;
}
