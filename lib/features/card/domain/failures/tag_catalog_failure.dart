/// Why a catalog operation on a tag was refused, and what a rename did.
library;

/// What a rename actually did (BR-185, BR-186).
///
/// **A returned value, not something the caller re-derives.** Whether a rename
/// keeps the tag or merges it into another one is decided *inside* the
/// transaction, by reading the folded name as it stands at the moment of the
/// write — so a caller that compared names beforehand and drew its own
/// conclusion would be describing a database from a moment earlier. The UI
/// discloses the merge before submitting (M4.14 W4) from the catalog it already
/// holds; this is what it confirms afterwards.
enum TagRenameOutcome {
  /// The folded name was free, so the tag kept its id and every link (BR-185).
  /// Also covers a rename that only changed the spelling's case.
  renamed,

  /// The folded name belonged to another tag, so this one was merged into it
  /// and its row deleted (BR-186).
  merged,
}

/// Why a catalog operation could not run.
///
/// One value for now, and it is deliberately not folded into a bare
/// [NotFoundFailure] with no reason: the catalog is a live stream, so "the tag
/// is gone" is a normal outcome of two surfaces being open at once, and the
/// screen answers it by closing the overlay rather than by showing a generic
/// error. That is a different response from any other failure, so it needs a
/// value to switch on.
enum TagCatalogProblem {
  /// The tag no longer exists — deleted or merged away between the moment the
  /// overlay opened and the moment it submitted (UC-12 E3).
  tagMissing,
}
