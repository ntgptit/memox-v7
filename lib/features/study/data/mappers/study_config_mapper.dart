import 'dart:convert';

import '../../domain/models/new_card_order_model.dart';

/// The keys `decks.study_config` uses. One name, one place.
const String kStudyConfigCardLimit = 'card_limit';
const String kStudyConfigNewCardOrder = 'new_card_order';

/// A root deck's override of the app-wide study options (BR-147).
///
/// Both fields are nullable and independent: a deck MAY override one and leave
/// the other to the default, so an absent key means "not overridden", never
/// "overridden to nothing".
typedef StudyOptionsOverride = ({int? cardLimit, NewCardOrder? newCardOrder});

const StudyOptionsOverride kNoStudyOptionsOverride = (
  cardLimit: null,
  newCardOrder: null,
);

/// Reads `decks.study_config`, and never refuses to study over it.
///
/// **Every failure degrades to "no override".** Not valid JSON, not an object,
/// a card limit stored as a string, a key that is not there at all — each one
/// falls back to the app-wide default, which is exactly what a deck that never
/// set an override already gets. The alternative is a user unable to open a deck
/// because a preference is malformed, which trades a wrong number for no app.
///
/// This is not a swallowed error: only `FormatException` is caught, the fallback
/// is the documented behaviour rather than a shrug, and a value out of range is
/// handled by `StudyCardLimit.fromStored` on the way out rather than dropped
/// here.
StudyOptionsOverride studyOptionsOverrideFromJson(String? raw) {
  if (raw == null || raw.trim().isEmpty) return kNoStudyOptionsOverride;

  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return kNoStudyOptionsOverride;
  }

  if (decoded is! Map<String, Object?>) return kNoStudyOptionsOverride;

  final limit = decoded[kStudyConfigCardLimit];
  final order = decoded[kStudyConfigNewCardOrder];

  return (
    cardLimit: limit is int ? limit : null,
    newCardOrder: order is String ? NewCardOrder.fromDbValue(order) : null,
  );
}

/// Writes the override back, with both fields always present.
///
/// Both, rather than only what differs from the default: a config that omitted a
/// field would start following the app-wide default again the moment that
/// default changed, which is not what "I set this deck to 30" means.
String studyOptionsOverrideToJson({
  required int cardLimit,
  required NewCardOrder newCardOrder,
}) => jsonEncode(<String, Object>{
  kStudyConfigCardLimit: cardLimit,
  kStudyConfigNewCardOrder: newCardOrder.dbValue,
});
