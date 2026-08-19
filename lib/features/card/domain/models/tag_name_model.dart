import '../../../../core/text/search_fold.dart';
import '../failures/tag_validation_failure.dart';

/// C0, DEL and C1 — every character that carries no glyph.
///
/// Interior only in effect: [TagName.parse] trims first, so a name padded with
/// tabs or newlines is cleaned rather than refused, and what reaches this is a
/// control character sitting *inside* the name. `char(31)` is the one that made
/// this a bug, but the whole range is the rule: none of them is text a chip can
/// render, and a delimiter the queries pick tomorrow is safe by construction
/// rather than by having checked.
final RegExp _controlCharacters = RegExp(r'[\x00-\x1F\x7F-\x9F]');

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
    if (_controlCharacters.hasMatch(trimmed)) {
      return (
        name: null,
        problem: TagValidationProblem.nameHasControlCharacter,
      );
    }

    return (name: TagName._(trimmed, foldForSearch(trimmed)), problem: null);
  }

  /// Reads a name that is **already stored**, without BR-93's length limit —
  /// [CardText.fromStored]'s reasoning, applied to the sixth canonical field.
  ///
  /// Only the length relaxes. Empty and control characters stay refused: the
  /// first cannot be written to a cell at all (the tags codec drops empty
  /// pieces), and the second is the invariant the `char(31)` join depends on,
  /// so admitting it here would re-open exactly what enforcing it closed.
  static ({TagName? name, TagValidationProblem? problem}) fromStored(
    String raw,
  ) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (name: null, problem: TagValidationProblem.nameEmpty);
    }
    if (_controlCharacters.hasMatch(trimmed)) {
      return (
        name: null,
        problem: TagValidationProblem.nameHasControlCharacter,
      );
    }

    return (name: TagName._(trimmed, foldForSearch(trimmed)), problem: null);
  }

  /// BR-93's fold, applied to text that is **not** a name being created.
  ///
  /// **`CardText.fold`'s reason, for the sixth field.** A tag search compares a
  /// typed term against the stored `name_folded` column, and both sides have to
  /// go through the same rule or the comparison is between two different
  /// foldings — the defect `searchPredicate` had to be repaired out of, where
  /// SQLite's ASCII-only `lower()` sat on one side and Dart's on the other.
  ///
  /// **Deliberately not [parse] or [fromStored].** A search term is not a name:
  /// it may be longer than the limit, and refusing it would turn "I typed too
  /// much" into "no filter at all", which shows *more* rows rather than fewer.
  /// It is not stored text either, so [fromStored] would be the read affordance
  /// applied to something that was never read — the boundary
  /// `card_transfer_boundary_test.dart` protects.
  ///
  /// Returns the empty string for a blank term, which every caller reads as
  /// "no search".
  static String fold(String raw) => raw.trim().toLowerCase();

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
