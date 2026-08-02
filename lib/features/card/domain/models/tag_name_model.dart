import '../failures/tag_validation_failure.dart';

/// A tag name that has been through BR-93.
///
/// **The point of the type is that it cannot be constructed from an invalid
/// string** — `DeckName` and `CardText` applied a third time, for the same
/// reason: the repository contract takes a `TagName`, so "did anyone validate
/// this?" is answered by the signature.
///
/// **Trim happens here and nowhere else**, and so does folding. [parse] is the
/// only entry point; [value] is what a chip renders and [folded] is what the
/// unique index compares.
final class TagName {
  const TagName._(this.value, this.folded);

  /// The trimmed name, as the user typed it. Safe to persist as-is.
  final String value;

  /// `value` lowercased — the form BR-93's uniqueness is measured in, and the
  /// form written to `tags.name_folded`.
  ///
  /// **This is a stored column rather than `COLLATE NOCASE`, and that is not a
  /// preference.** SQLite folds ASCII only, so `Động từ` and `động từ` compare
  /// as different under NOCASE and both get in. Folding in Dart uses the full
  /// Unicode mapping, and writing the result means the database compares bytes.
  final String folded;

  /// BR-93's limit, measured after trimming.
  static const int maxLength = kTagNameMaxLength;

  /// Parses [raw], reporting the rule it broke instead of throwing.
  ///
  /// Returns exactly one of the two, so a caller can combine this with other
  /// field checks and refuse once with everything wrong — the shape
  /// `parseCardSides` needs.
  static ({TagName? name, TagValidationProblem? problem}) parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (name: null, problem: TagValidationProblem.nameEmpty);
    }
    if (trimmed.length > maxLength) {
      return (name: null, problem: TagValidationProblem.nameTooLong);
    }

    return (name: TagName._(trimmed, trimmed.toLowerCase()), problem: null);
  }

  /// Whether two names collide under BR-93's case-insensitive uniqueness.
  ///
  /// Named rather than left to callers comparing [folded] by hand: the whole
  /// point of the fold is that one place decides what "the same tag" means.
  bool collidesWith(TagName other) => folded == other.folded;

  @override
  bool operator ==(Object other) => other is TagName && other.folded == folded;

  @override
  int get hashCode => folded.hashCode;

  @override
  String toString() => value;
}
