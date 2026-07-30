/// Why a deck form may not proceed, and how it says so.
library;

import '../../../../core/error/failure.dart';

/// Every way a deck form can be wrong — one value per field-and-reason.
///
/// **One enum, shared by domain and presentation.** The domain throws these; the
/// screen maps them to ARB copy. There used to be two — `DeckNameProblem` in the
/// entity and `DeckFormProblem` in presentation — with a switch converting
/// between them, and the conversion re-ran the rule to decide which value to
/// produce. That made presentation a second owner of BR-01.
///
/// The value names the field as well as the reason, which is what lets the screen
/// mark the right input without a separate field key.
enum DeckValidationProblem {
  /// Empty, or nothing but whitespace, after trimming (BR-01).
  nameEmpty,

  /// Longer than [kDeckNameMaxLength] after trimming (BR-01). Never truncated
  /// silently.
  nameTooLong,

  /// The mandatory scheduler choice is still missing (BR-11). Only the
  /// create-root flow can produce it; nothing else offers the choice.
  schedulerMissing,
}

/// The values that belong to the name input.
///
/// Named because two places need the same answer, and a second literal set is how
/// the two drift apart.
const Set<DeckValidationProblem> kDeckNameProblems = <DeckValidationProblem>{
  DeckValidationProblem.nameEmpty,
  DeckValidationProblem.nameTooLong,
};

/// BR-01's limit. Lives beside the rule that uses it.
const int kDeckNameMaxLength = 200;

/// Refuses when [problems] has anything in it.
///
/// One place, so every use case refuses the same way and the controller has one
/// shape to read. [Failure.message] stays a sanitized diagnostic for the log —
/// the screen renders ARB copy chosen from the problems.
void refuseInvalidDeckForm(Set<DeckValidationProblem> problems) {
  if (problems.isEmpty) return;

  throw ValidationFailure(
    message:
        'The deck form is invalid: '
        '${problems.map((problem) => problem.name).join(', ')}.',
    problems: problems,
  );
}
