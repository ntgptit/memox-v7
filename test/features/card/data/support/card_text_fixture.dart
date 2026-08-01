import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';

/// A [CardText] from a literal, for tests whose subject is something else.
///
/// The contract takes validated text, so a data-layer test that wants "any
/// valid card" has to say so in the type. This goes through the real
/// [CardText.parse] rather than a back door into the private constructor —
/// a fixture that could build text production cannot would let a repository
/// test pass on a value the app can never hand it.
///
/// Invalid input is the caller's mistake and says so immediately, instead of
/// surfacing later as a null dereference in the test that used it.
CardText cardText(String raw, {CardSide side = CardSide.front}) {
  final parsed = CardText.parse(raw, side: side);
  final text = parsed.text;
  if (text == null) {
    throw ArgumentError.value(
      raw,
      'raw',
      'is not valid card text (${parsed.problem?.name}) — a fixture must be '
          'valid; refusal is tested in card_text_test.dart',
    );
  }

  return text;
}
