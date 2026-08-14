import '../../../../core/text/search_fold.dart';
import '../failures/card_validation_failure.dart';

/// One side of a card that has been through BR-07 and BR-08.
///
/// **The point of the type is that it cannot be constructed from invalid text.**
/// The repository contract takes a `CardText`, not a `String`, so "did anyone
/// validate this?" is answered by the signature rather than by reading three
/// layers to find out.
///
/// This is `DeckName` applied to the second feature, and the history is the
/// argument for it: before `DeckName`, BR-01 ran in three places for one submit
/// — the use case checked it, the repository called `validateName` again, and
/// the screen re-derived the problem to decide which field to mark. The card
/// repository was still doing the middle one of those three
/// (`CardEntity.validateSide`, called inside the write transaction) when this
/// type replaced it.
///
/// **Trim happens here and nowhere else.** [parse] is the only entry point, it
/// normalises once, and [value] is the normalised result — so no layer can trim
/// what another layer already trimmed, and none of them needs to know whether
/// someone else did.
final class CardText {
  const CardText._(this.value, this.folded);

  /// The trimmed text. Safe to persist as-is.
  final String value;

  /// [value] case-folded for comparison — what `cards.front_folded` and
  /// `cards.back_folded` store, and what search matches against.
  ///
  /// **Folded here rather than in SQL, and that is the whole point.** SQLite's
  /// `lower()` and `COLLATE NOCASE` fold ASCII only, so they leave `Ô`, `Ê` and
  /// `Đ` untouched. Dart's `toLowerCase()` is Unicode-aware, so folding both the
  /// stored text and the search term in Dart makes the comparison byte-for-byte
  /// and correct for Vietnamese as well as English. `TagName.folded` reached the
  /// same conclusion first (BR-93); this is that decision applied to the two
  /// sides a card is searched by.
  ///
  /// Case only. `công` still does not match `cong` — diacritic-insensitive
  /// search is a separate product decision (S1).
  final String folded;

  /// BR-08's limit for [side], measured after trimming.
  ///
  /// **Per side, not one number.** This was a single `maxLength` constant while
  /// BR-08 gave both sides 2000; at M4.10at it became 60 and 240, and a shared
  /// constant would have quietly handed the front the back's allowance.
  static int maxLengthOf(CardSide side) => side.maxLength;

  /// Parses [raw] for [side], reporting the rule it broke instead of throwing.
  ///
  /// Returns exactly one of the two: a [CardText] or a
  /// [CardValidationProblem]. Reporting rather than throwing is what lets the
  /// caller parse **both** sides and refuse once with both problems — a card
  /// with two blank fields is the ordinary state of an empty form, and throwing
  /// on the first would make the user submit twice to find the second.
  ///
  /// [side] decides both which problem value comes back **and** which limit
  /// applies — BR-08 gives the front 60 characters and the back 240. It used to
  /// only pick the problem, back when the two shared one number.
  static ({CardText? text, CardValidationProblem? problem}) parse(
    String raw, {
    required CardSide side,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (text: null, problem: side.emptyProblem);
    }
    if (trimmed.length > side.maxLength) {
      return (text: null, problem: side.tooLongProblem);
    }

    return (text: CardText._(trimmed, foldForSearch(trimmed)), problem: null);
  }

  /// Reads text that is **already stored** for [side], without BR-08's length
  /// limit.
  ///
  /// **Only a read path may call this, and only for text the database already
  /// holds** — `card_transfer_boundary_test.dart` pins that to the export
  /// repository. Every write still goes through [parse]; this is not a way to
  /// get a longer card in.
  ///
  /// The limit exists to stop a user typing more than a card can show. It says
  /// nothing about a row written when the limit was a different number — BR-08
  /// went from 2000 to 60/240 at M4.10at and no migration truncated anything,
  /// so a database can legitimately hold a front the current rule would refuse.
  /// Running such a row through [parse] made the whole export fail
  /// (`readFailed`), which took the app's only way of getting data *out* and
  /// pointed it at a card the user cannot even find, let alone shorten. BR-175
  /// asks for the six content fields as they stand; refusing a deck over a
  /// limit tightened after the fact is data loss dressed as validation.
  ///
  /// **Emptiness is still refused**, and the asymmetry is the point: a length
  /// cap is a policy that changed, while "a card has two sides" (BR-07) never
  /// did, and BR-169 makes a row with a blank side unimportable — so an empty
  /// side is a genuinely unrepresentable record rather than an old one.
  static ({CardText? text, CardValidationProblem? problem}) fromStored(
    String raw, {
    required CardSide side,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (text: null, problem: side.emptyProblem);
    }

    return (text: CardText._(trimmed, foldForSearch(trimmed)), problem: null);
  }

  /// Folds a search term the same way a stored side is folded.
  ///
  /// Exists so the two sides of the comparison cannot drift apart: a query that
  /// folds its term by hand is one `toLowerCase()` away from being asymmetric
  /// again, which is the bug this column pair was added to fix.
  ///
  /// **The rule itself moved to `core/text/search_fold.dart`** when Global
  /// Library Search became the fourth implementer of it (M99.23). This stays as
  /// the card-side name for it — `card_list_query_mapper.dart` and the export
  /// path both read it — but it no longer *decides* anything.
  static String fold(String raw) => foldForSearch(raw);

  @override
  bool operator ==(Object other) => other is CardText && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// An optional detail — example, hint or pronunciation — that has been through
/// BR-95.
///
/// Like [CardText], it cannot be built from invalid text; unlike it, empty is
/// **valid** and means "no value", so [parse] returns `(null, null)` for a blank
/// field. The repository takes a `CardDetailText?`, where null clears the column.
final class CardDetailText {
  const CardDetailText._(this.value);

  /// The trimmed text — never empty (an empty field parses to null instead).
  final String value;

  /// Parses [raw] for [field]. Three outcomes, distinguished by which of the
  /// pair is set: `(value, null)` a detail, `(null, null)` an empty field that
  /// folds to null, `(null, problem)` too long (BR-95).
  static ({CardDetailText? text, CardValidationProblem? problem}) parse(
    String raw, {
    required CardDetailField field,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return (text: null, problem: null);
    if (trimmed.length > kCardDetailMaxLength) {
      return (text: null, problem: field.tooLongProblem);
    }

    return (text: CardDetailText._(trimmed), problem: null);
  }

  /// Reads an optional detail that is **already stored**, without BR-95's
  /// length limit — [CardText.fromStored]'s reasoning, applied to the three
  /// optional fields.
  ///
  /// No problem is possible here: an empty detail is a detail with no value,
  /// which is what null means, so the only two outcomes are a value and none.
  static CardDetailText? fromStored(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    return CardDetailText._(trimmed);
  }

  @override
  bool operator ==(Object other) =>
      other is CardDetailText && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// One parsed card form: the two required sides plus the three optional details
/// (BR-07, BR-08, BR-95).
typedef ParsedCardForm = ({
  CardText front,
  CardText back,
  CardDetailText? example,
  CardDetailText? hint,
  CardDetailText? pronunciation,
});

/// Parses a whole card form and refuses once, with everything wrong.
///
/// Supersedes [parseCardSides] for the write use cases: the details join the
/// sides so a form with a blank front *and* an over-long hint reports both in
/// one refusal, rather than the user fixing the front and resubmitting to find
/// the hint. The details default to empty, so a caller that has none passes none.
ParsedCardForm parseCardForm({
  required String rawFront,
  required String rawBack,
  String rawExample = '',
  String rawHint = '',
  String rawPronunciation = '',
}) {
  final parsedFront = CardText.parse(rawFront, side: CardSide.front);
  final parsedBack = CardText.parse(rawBack, side: CardSide.back);
  final parsedExample = CardDetailText.parse(
    rawExample,
    field: CardDetailField.example,
  );
  final parsedHint = CardDetailText.parse(rawHint, field: CardDetailField.hint);
  final parsedPronunciation = CardDetailText.parse(
    rawPronunciation,
    field: CardDetailField.pronunciation,
  );

  refuseInvalidCardForm(<CardValidationProblem>{
    ?parsedFront.problem,
    ?parsedBack.problem,
    ?parsedExample.problem,
    ?parsedHint.problem,
    ?parsedPronunciation.problem,
  });

  final front = parsedFront.text;
  final back = parsedBack.text;
  if (front == null || back == null) {
    throw StateError('unreachable: refuseInvalidCardForm would have thrown');
  }

  return (
    front: front,
    back: back,
    example: parsedExample.text,
    hint: parsedHint.text,
    pronunciation: parsedPronunciation.text,
  );
}

/// Parses both sides of a card form and refuses once, with everything wrong.
///
/// **One place, deliberately.** Deck's equivalent — parse, refuse, then a
/// three-line `StateError('unreachable: …')` to convince the compiler the value
/// is non-null — is copy-pasted verbatim into each of its three validating use
/// cases, and a fourth would get a fourth copy. Card has two sides and two
/// write operations, so the same shape would have been four copies of a
/// six-line block. It lives here instead, and the use cases are one line each.
///
/// Both sides are parsed before either is refused: a form with two blank fields
/// reports both, so the user does not fix one and resubmit to discover the
/// other. That is what `ValidationFailure.problems` being a `Set` is for.
({CardText front, CardText back}) parseCardSides({
  required String rawFront,
  required String rawBack,
}) {
  final parsedFront = CardText.parse(rawFront, side: CardSide.front);
  final parsedBack = CardText.parse(rawBack, side: CardSide.back);

  refuseInvalidCardForm(<CardValidationProblem>{
    ?parsedFront.problem,
    ?parsedBack.problem,
  });

  final front = parsedFront.text;
  final back = parsedBack.text;
  if (front == null || back == null) {
    throw StateError('unreachable: refuseInvalidCardForm would have thrown');
  }

  return (front: front, back: back);
}
