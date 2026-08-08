/// The lowest a session ceiling can be set to.
///
/// One, because a ceiling of zero is not a preference — it is a deck that can
/// never be studied, expressed as a number nobody would recognise as that.
const int kMinCardLimit = 1;

/// The highest a session ceiling can be set to.
///
/// **Not a business rule.** BR-24 fixes the default at 20 and says nothing about
/// an upper bound; this one exists because a free-text field can otherwise
/// produce a session of a hundred thousand cards, and the failure would look
/// like the app hanging. Two hundred is far past any real session and near
/// enough to be recognisably a limit rather than an accident.
const int kMaxCardLimit = 200;

/// BR-24's default, and the value used whenever nothing else is readable.
const int kDefaultCardLimit = 20;

/// A session ceiling that has been through its bounds.
///
/// **The type is the check.** `saveStudyOptions` takes a `StudyCardLimit`, not
/// an `int`, so "has this been validated?" is answered by the signature — the
/// same reason `DeckName` exists rather than a `validateName` somebody has to
/// remember to call.
final class StudyCardLimit {
  const StudyCardLimit._(this.value);

  /// The value, safe to persist as-is.
  final int value;

  /// BR-24's default (20), which needs no parsing.
  static const StudyCardLimit standard = StudyCardLimit._(kDefaultCardLimit);

  /// Parses [raw], reporting which bound it broke instead of throwing.
  ///
  /// Takes the string rather than an `int` because the screen has a text field
  /// and "not a number at all" is one of the ways this fails — leaving that case
  /// to the caller would put a third of the rule back outside the type.
  static ({StudyCardLimit? limit, StudyCardLimitProblem? problem}) parse(
    String raw,
  ) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) {
      return (limit: null, problem: StudyCardLimitProblem.notANumber);
    }
    if (parsed < kMinCardLimit) {
      return (limit: null, problem: StudyCardLimitProblem.tooSmall);
    }
    if (parsed > kMaxCardLimit) {
      return (limit: null, problem: StudyCardLimitProblem.tooLarge);
    }

    return (limit: StudyCardLimit._(parsed), problem: null);
  }

  /// The value already in the database, which is trusted rather than re-parsed.
  ///
  /// Stored values are clamped rather than rejected: a limit that somehow landed
  /// out of range is not a reason to refuse to study, and the clamp is visible
  /// the moment the settings screen opens.
  static StudyCardLimit fromStored(int stored) =>
      StudyCardLimit._(stored.clamp(kMinCardLimit, kMaxCardLimit));

  @override
  bool operator ==(Object other) =>
      other is StudyCardLimit && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value';
}

/// Which bound a proposed card limit broke.
enum StudyCardLimitProblem { notANumber, tooSmall, tooLarge }
