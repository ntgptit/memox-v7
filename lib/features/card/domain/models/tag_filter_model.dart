/// Which tags the card list is narrowed to (BR-231).
///
/// **A type rather than a bare `Set<String>`, and the reason is BR-231's
/// identity clause.** "No tag selected applies no tag predicate" is a rule that
/// every caller would otherwise re-state as `if (tagIds.isNotEmpty)` — the list
/// read, the count read, the select-all read, and the controller that decides
/// whether the pill looks active. Four copies of one rule is four chances for
/// one of them to say `!= null` instead, and the failure is silent: the count
/// filters and the list does not, so the screen reads "Showing 12 of 3".
///
/// So the rule lives here, once, as [isActive], and the empty selection is a
/// named constant rather than something each caller constructs.
///
/// **The semantics between selected tags is OR** (BR-231): a card carrying any
/// of them matches. The whole predicate is then ANDed with the state filter and
/// the search term — see `cardListPredicate`. Two tags therefore *widen* the
/// result, which is the opposite of what the four state pills do, and it is why
/// the filter overlay says so in words (wireframe M4.14 W6).
final class TagFilter {
  const TagFilter._(this.tagIds);

  /// The resting state: no tag predicate at all.
  ///
  /// **Not "match every tag" and not "match no tag"** — the identity of the
  /// composition, so a list read with this is byte-for-byte the read the screen
  /// performed before tag filtering existed.
  static const TagFilter none = TagFilter._(<String>{});

  /// Takes a copy, so a caller mutating the set it passed cannot change what a
  /// live stream is filtered by underneath it.
  factory TagFilter.of(Iterable<String> tagIds) {
    final ids = tagIds.toSet();
    if (ids.isEmpty) return none;

    return TagFilter._(Set<String>.unmodifiable(ids));
  }

  /// The selected tag ids. Unmodifiable; empty means [none].
  final Set<String> tagIds;

  /// Whether a tag predicate should be applied at all (BR-231).
  bool get isActive => tagIds.isNotEmpty;

  /// How many tags are selected — the number the `Tags` pill shows (M4.14 T4).
  int get length => tagIds.length;

  bool contains(String tagId) => tagIds.contains(tagId);

  /// The same selection with [tagId] added or removed. Used by the filter
  /// overlay's draft; the applied filter is only ever replaced whole.
  TagFilter toggled(String tagId) => TagFilter.of(
    tagIds.contains(tagId)
        ? tagIds.where((String id) => id != tagId)
        : <String>[...tagIds, tagId],
  );

  /// Drops any id that is no longer in [available] — a tag deleted or merged
  /// away while the filter was applied must stop narrowing the list, rather
  /// than leaving it permanently empty with no way to see why.
  TagFilter retaining(Set<String> available) =>
      TagFilter.of(tagIds.where(available.contains));

  @override
  bool operator ==(Object other) =>
      other is TagFilter &&
      other.tagIds.length == tagIds.length &&
      other.tagIds.containsAll(tagIds);

  @override
  int get hashCode => Object.hashAllUnordered(tagIds);

  @override
  String toString() => 'TagFilter(${tagIds.length})';
}
