import 'package:flutter/foundation.dart';

/// The five content values a card save writes, normalised the way it writes
/// them.
///
/// The editor holds one of these from the moment the card loads and compares
/// every keystroke against it. That comparison — rather than a "has been
/// edited" flag — is what lets a user type a word, delete it again, and find
/// `Save changes` disabled, which is the state they are actually in.
///
/// **Trimmed, because that is what `parseCardForm` stores.** Comparing raw
/// controller text would call a form dirty because a trailing space was typed
/// and removed nothing — a save that would write the same row byte for byte.
/// The normalisation is one `trim()` per field and it is stated here rather
/// than borrowed from the domain: this is presentation's model of what a save
/// would cost, not the validation rule itself. It has no opinion on emptiness
/// or length; those refusals belong to `CardText` and arrive as a failure.
@immutable
class CardContentDraft {
  CardContentDraft({
    required String front,
    required String back,
    required String example,
    required String hint,
    required String pronunciation,
  }) : front = front.trim(),
       back = back.trim(),
       example = example.trim(),
       hint = hint.trim(),
       pronunciation = pronunciation.trim();

  final String front;
  final String back;
  final String example;
  final String hint;
  final String pronunciation;

  @override
  bool operator ==(Object other) =>
      other is CardContentDraft &&
      other.front == front &&
      other.back == back &&
      other.example == example &&
      other.hint == hint &&
      other.pronunciation == pronunciation;

  @override
  int get hashCode => Object.hash(front, back, example, hint, pronunciation);
}
