/// A place a batch may be restored to (BR-261).
///
/// **Only targets that would actually be accepted appear as one of these.** The
/// picker draws this list and nothing else, so it has no disabled rows — a
/// greyed-out row is one the reader still has to read and which cannot say why
/// it is grey (wireframe T8).
///
/// A sealed class rather than a nullable deck id, because "the top level" and "a
/// deck" are two different destinations with two different rules, and a null
/// that means one of them is the kind of thing a caller forgets to handle.
sealed class TrashRestoreTarget {
  const TrashRestoreTarget();

  /// The deck this target writes into, or null for the top level.
  String? get deckId;
}

/// The library's top level — the only target a deleted **root** deck has
/// (BR-56, BR-261).
final class TrashTopLevelTarget extends TrashRestoreTarget {
  const TrashTopLevelTarget();

  @override
  String? get deckId => null;
}

/// An active deck that may receive this batch.
///
/// [parentName] rides along so the picker can tell two same-named decks apart
/// without a second read — the same reason `cardMoveTargets` carries it.
final class TrashDeckTarget extends TrashRestoreTarget {
  const TrashDeckTarget({
    required this.deckId,
    required this.name,
    required this.parentName,
  });

  /// Non-null for this branch, and typed as nullable only because the base
  /// class has to admit the top level.
  @override
  final String? deckId;

  final String name;
  final String? parentName;
}
