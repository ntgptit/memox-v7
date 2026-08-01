/// Why a card form may not proceed, and how it says so.
library;

import '../../../../core/error/failure.dart';

/// Which side of a card a rule is about.
///
/// Carried as a value rather than duplicated as two parallel code paths: front
/// and back obey the same two rules, and the only thing that differs is which
/// input a screen must mark.
enum CardSide {
  front,
  back;

  /// The problem this side reports when it is empty after trimming (BR-07).
  CardValidationProblem get emptyProblem => switch (this) {
    CardSide.front => CardValidationProblem.frontEmpty,
    CardSide.back => CardValidationProblem.backEmpty,
  };

  /// The problem this side reports when it exceeds [kCardSideMaxLength]
  /// (BR-08).
  CardValidationProblem get tooLongProblem => switch (this) {
    CardSide.front => CardValidationProblem.frontTooLong,
    CardSide.back => CardValidationProblem.backTooLong,
  };
}

/// Every way a card form can be wrong — one value per field-and-reason.
///
/// The same shape as `DeckValidationProblem`, for the same reason: the value
/// names the field as well as the rule, so a screen marks the right input
/// without a separate field key, and one enum serves both the domain that
/// throws and the presentation that renders copy.
///
/// **A card can be wrong in two places at once**, which is why these travel in
/// `ValidationFailure.problems` — a `Set` — rather than in `Failure.reason`,
/// which holds one. Both sides blank is the ordinary case on an empty form, and
/// reporting it as one problem makes the user submit twice to discover the
/// second.
enum CardValidationProblem {
  /// Front is empty, or nothing but whitespace, after trimming (BR-07).
  frontEmpty,

  /// Front is longer than [kCardSideMaxLength] after trimming (BR-08). Never
  /// truncated silently.
  frontTooLong,

  /// Back is empty, or nothing but whitespace, after trimming (BR-07).
  backEmpty,

  /// Back is longer than [kCardSideMaxLength] after trimming (BR-08).
  backTooLong,
}

/// The values that belong to the front input.
///
/// Named because two places need the same answer, and a second literal set is
/// how the two drift apart.
const Set<CardValidationProblem> kCardFrontProblems = <CardValidationProblem>{
  CardValidationProblem.frontEmpty,
  CardValidationProblem.frontTooLong,
};

/// The values that belong to the back input.
const Set<CardValidationProblem> kCardBackProblems = <CardValidationProblem>{
  CardValidationProblem.backEmpty,
  CardValidationProblem.backTooLong,
};

/// BR-08's limit, measured after trimming. Lives beside the rule that uses it.
const int kCardSideMaxLength = 2000;

/// Refuses when [problems] has anything in it.
///
/// One place, so every use case refuses the same way and the controller has one
/// shape to read. [Failure.message] stays a sanitized diagnostic for the log —
/// the screen renders ARB copy chosen from the problems.
void refuseInvalidCardForm(Set<CardValidationProblem> problems) {
  if (problems.isEmpty) return;

  throw ValidationFailure(
    message:
        'The card form is invalid: '
        '${problems.map((problem) => problem.name).join(', ')}.',
    problems: problems,
  );
}
