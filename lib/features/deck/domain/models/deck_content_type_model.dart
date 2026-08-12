/// What a deck holds — one kind of child, never both (BR-60…BR-66, BR-163,
/// AD-10).
///
/// `unknown` exists for reading only, mirroring [SchedulerType]: an
/// unrecognised stored value maps to it, and mapping it back fails fast so it
/// can never be persisted.
enum DeckContentType {
  /// No child created yet; the first child decides (BR-62).
  unset('unset'),

  /// Holds cards only (BR-63).
  card('card'),

  /// Holds sub-decks only (BR-64). Every root deck is 'deck', immutably.
  deck('deck'),

  /// A database value this build does not recognise. Read-only.
  unknown(null);

  const DeckContentType(this._dbValue);

  final String? _dbValue;

  /// The value stored in the database.
  ///
  /// Throws for [unknown] — see [SchedulerType.dbValue] for why.
  String get dbValue {
    final value = _dbValue;
    if (value == null) {
      throw StateError('DeckContentType.unknown cannot be written to storage');
    }

    return value;
  }

  /// Maps a stored value to the enum, tolerating values from newer schemas.
  static DeckContentType fromDbValue(String value) {
    for (final type in values) {
      if (type._dbValue == value) return type;
    }

    return unknown;
  }
}
