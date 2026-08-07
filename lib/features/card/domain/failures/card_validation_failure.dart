/// Why a card form may not proceed, and how it says so.
library;

import '../../../../core/error/failure.dart';

/// Which side of a card a rule is about.
///
/// Carried as a value rather than duplicated as two parallel code paths. The
/// two sides obey the same *rules* — non-empty after trimming, and a maximum
/// length — but **not the same numbers**: BR-08 gives the front 60 characters
/// and the back 240, because a front is a term and a back is its meaning.
///
/// That is why the limit lives on the enum. A single `maxLength` constant read
/// by both sides was correct while the number was shared, and became a silent
/// way to give the front the back's allowance the moment it stopped being.
enum CardSide {
  front,
  back;

  /// The problem this side reports when it is empty after trimming (BR-07).
  CardValidationProblem get emptyProblem => switch (this) {
    CardSide.front => CardValidationProblem.frontEmpty,
    CardSide.back => CardValidationProblem.backEmpty,
  };

  /// The problem this side reports when it exceeds [maxLength] (BR-08).
  CardValidationProblem get tooLongProblem => switch (this) {
    CardSide.front => CardValidationProblem.frontTooLong,
    CardSide.back => CardValidationProblem.backTooLong,
  };

  /// How many characters this side allows after trimming (BR-08).
  int get maxLength => switch (this) {
    CardSide.front => kCardFrontMaxLength,
    CardSide.back => kCardBackMaxLength,
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

  /// Front is longer than [kCardFrontMaxLength] after trimming (BR-08). Never
  /// truncated silently.
  frontTooLong,

  /// Back is empty, or nothing but whitespace, after trimming (BR-07).
  backEmpty,

  /// Back is longer than [kCardBackMaxLength] after trimming (BR-08).
  backTooLong,

  /// The example detail is longer than [kCardDetailMaxLength] (BR-95). There is
  /// no `exampleEmpty`: the three details are optional, so empty is valid and
  /// folds to null.
  exampleTooLong,

  /// The hint detail is longer than [kCardDetailMaxLength] (BR-95).
  hintTooLong,

  /// The pronunciation detail is longer than [kCardDetailMaxLength] (BR-95).
  pronunciationTooLong,
}

/// The three optional detail fields (BR-95). Unlike [CardSide] they have no
/// empty problem — empty is valid and folds to null — only a shared length cap.
enum CardDetailField {
  example,
  hint,
  pronunciation;

  /// The problem this field reports when it exceeds [kCardDetailMaxLength].
  CardValidationProblem get tooLongProblem => switch (this) {
    CardDetailField.example => CardValidationProblem.exampleTooLong,
    CardDetailField.hint => CardValidationProblem.hintTooLong,
    CardDetailField.pronunciation => CardValidationProblem.pronunciationTooLong,
  };
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

/// The one problem each detail input can carry (BR-95).
const Set<CardValidationProblem> kCardExampleProblems = <CardValidationProblem>{
  CardValidationProblem.exampleTooLong,
};
const Set<CardValidationProblem> kCardHintProblems = <CardValidationProblem>{
  CardValidationProblem.hintTooLong,
};
const Set<CardValidationProblem> kCardPronunciationProblems =
    <CardValidationProblem>{CardValidationProblem.pronunciationTooLong};

/// BR-95's limit for every optional detail, measured after trimming.
const int kCardDetailMaxLength = 240;

/// BR-08's limit for the front, measured after trimming.
///
/// **60, not 2000, since M4.10at.** The old number was a paste guard — it
/// stopped someone dropping a whole page in, and said nothing about what a card
/// is. A front is the term being learned, and 60 characters is the width the
/// list row and the study card are drawn for; past that the prompt wraps to
/// three lines on a phone and the answer goes below the fold.
const int kCardFrontMaxLength = 60;

/// BR-08's limit for the back, measured after trimming.
///
/// Four times the front, because a meaning carries more than a term — a gloss
/// in two languages, comma-separated, is the shape the design writes into the
/// placeholder.
const int kCardBackMaxLength = 240;

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
