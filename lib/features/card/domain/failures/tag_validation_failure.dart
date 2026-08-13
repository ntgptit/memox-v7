/// Why a tag may not be created, and how it says so.
library;

import '../../../../core/error/failure.dart';

/// Every way a tag name can be wrong — one value per reason.
///
/// The same shape as `CardValidationProblem` and `DeckValidationProblem`: the
/// value names the rule, so a screen renders the right copy without a separate
/// field key, and one enum serves both the domain that throws and the
/// presentation that reads.
enum TagValidationProblem {
  /// Empty, or nothing but whitespace, after trimming (BR-93).
  nameEmpty,

  /// Longer than [kTagNameMaxLength] after trimming (BR-93). Never truncated
  /// silently — a tag cut to 50 characters is a tag the user did not create.
  nameTooLong,

  /// A tag with this name already exists, ignoring case (BR-93).
  ///
  /// **Reported rather than silently reused.** Adding `noun` when `Noun` exists
  /// could quietly attach the existing one, and that is the right *behaviour* —
  /// but the caller has to choose it, because the same collision from a rename
  /// is a refusal. The domain reports the fact; the use case decides.
  nameTaken,

  /// The card already carries [kMaxTagsPerCard] tags (BR-94).
  tooManyTags,

  /// Holds an ASCII control character (BR-93 — a tag name is text a chip
  /// renders, and a control character is not text).
  ///
  /// **A rule the database was already relying on.** Both the card list and the
  /// export read concatenate a card's tag names with `char(31)` and split them
  /// apart in Dart, on the stated grounds that a tag can never contain one.
  /// Nothing enforced that: `parse` trimmed and measured length, and Dart's
  /// `trim` does not touch U+001F — so a name carrying one arrived through
  /// import, and the split then turned one tag into two or into an unreadable
  /// empty one. Enforcing it here makes the invariant a property of the type,
  /// which is the only place a `SELECT` can safely assume it.
  nameHasControlCharacter,
}

/// BR-93's limit, measured after trimming.
const int kTagNameMaxLength = 50;

/// BR-94's limit.
///
/// A user-interface bound raised to a rule, and it admits as much: the card row
/// draws tags as a chip strip, and an unbounded strip overflows at 320 with
/// `textScaler` 2.0. Ten is wide enough that nobody meets it in practice and
/// narrow enough that a row has a predictable height.
const int kMaxTagsPerCard = 10;

/// Refuses when [problems] has anything in it.
///
/// One place, so every use case refuses the same way and the controller has one
/// shape to read.
void refuseInvalidTag(Set<TagValidationProblem> problems) {
  if (problems.isEmpty) return;

  throw ValidationFailure(
    message:
        'The tag is invalid: '
        '${problems.map((problem) => problem.name).join(', ')}.',
    problems: problems,
  );
}
