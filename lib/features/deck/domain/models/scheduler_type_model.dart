/// The scheduler a root deck was created with (BR-11, AD-06).
///
/// `unknown` exists for reading only. A database value this build has never
/// heard of — written by a newer app version — maps to it instead of crashing
/// every screen that lists decks. It is not a real scheduler: writing it back
/// would persist a value no scheduler owns, so [dbValue] fails fast instead.
enum SchedulerType {
  eightBox('eight_box'),
  sm2('sm2'),

  /// A database value this build does not recognise. Read-only.
  unknown(null);

  const SchedulerType(this._dbValue);

  final String? _dbValue;

  /// The value stored in the database.
  ///
  /// Throws for [unknown]: an unrecognised value must never round-trip back
  /// into the database, where it would masquerade as a decision.
  String get dbValue {
    final value = _dbValue;
    if (value == null) {
      throw StateError('SchedulerType.unknown cannot be written to storage');
    }

    return value;
  }

  /// Maps a stored value to the enum, tolerating values from newer schemas.
  static SchedulerType fromDbValue(String value) {
    for (final type in values) {
      if (type._dbValue == value) return type;
    }

    return unknown;
  }
}
