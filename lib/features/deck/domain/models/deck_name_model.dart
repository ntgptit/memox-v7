import '../failures/deck_validation_failure.dart';

/// A deck name that has been through BR-01.
///
/// **The point of the type is that it cannot be constructed from an invalid
/// string.** The repository contract takes a `DeckName`, not a `String`, so
/// "did anyone validate this?" is answered by the signature rather than by
/// reading three layers to find out.
///
/// Before this existed the rule ran in three places for one submit: the use case
/// checked it, the repository called `DeckEntity.validateName` again, and the
/// screen re-derived the problem from the raw input to decide which field to mark.
/// Three owners of BR-01, free to disagree, while the documentation said there
/// was one.
///
/// **Trim happens here and nowhere else.** [parse] is the only entry point, it
/// normalises once, and [value] is the normalised result — so no layer can trim a
/// value another layer already trimmed, and none of them needs to know whether
/// someone else did.
final class DeckName {
  const DeckName._(this.value);

  /// The trimmed name. Safe to persist as-is.
  final String value;

  /// BR-01's limit, measured after trimming.
  static const int maxLength = kDeckNameMaxLength;

  /// Parses [raw], reporting the rule it broke instead of throwing.
  ///
  /// Returns exactly one of the two: a [DeckName] or a [DeckValidationProblem].
  /// One call rather than a `problemOf` followed by a `parse`, so the rule is
  /// evaluated once and the trim is applied once — which is what the caller needs
  /// in order to combine this with other field checks and report them together.
  static ({DeckName? name, DeckValidationProblem? problem}) parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (name: null, problem: DeckValidationProblem.nameEmpty);
    }
    if (trimmed.length > maxLength) {
      return (name: null, problem: DeckValidationProblem.nameTooLong);
    }

    return (name: DeckName._(trimmed), problem: null);
  }

  /// For a caller that has no form in front of it and wants the failure.
  ///
  /// Used by nothing in the Deck feature today — every write goes through a use
  /// case that collects problems across fields first. Kept because a future
  /// importer or background job has no form to report into, and its absence would
  /// invite that caller to re-implement the rule.
  static DeckName parseOrThrow(String raw) {
    final result = parse(raw);
    final name = result.name;
    if (name != null) return name;

    refuseInvalidDeckForm(<DeckValidationProblem>{result.problem!});
    // `refuseInvalidDeckForm` always throws when the set is non-empty; this is
    // unreachable and exists only because the analyser cannot see that.
    throw StateError('unreachable');
  }

  @override
  bool operator ==(Object other) => other is DeckName && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
