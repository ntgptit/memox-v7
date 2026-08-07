/// One of the six ways a card can be put in front of the user (BR-108).
///
/// **The set of modes belongs to the SRS algorithm, not to the deck and not to
/// the screen.** `eight_box` walks five of them, `sm2` walks two, and a UI that
/// hardcoded a list would be wrong for half the decks (BR-97). The algorithm
/// declares its own sequence; this enum only says what a mode *is*.
///
/// `unknown` exists for reading only, for the same reason `SchedulerType` has
/// one: a row written by a newer build must not take down the screen that reads
/// it. Writing it back is impossible by construction.
enum StudyMode {
  /// Front and back at once, no flip, no action, no history row (BR-111,
  /// BR-112). It is the only mode that grades nothing, which is why it can
  /// never appear in `study_answers.mode` and never appears as a review choice.
  browse('browse'),

  /// Flip, then the user picks the action themselves (BR-112).
  ///
  /// It takes the action **directly** rather than grading — the one mode where
  /// BR-107's binary-to-action mapping does not apply (BR-106).
  selfAssess('self_assess'),

  /// Pairs on a board. Needs at least two pairs to be worth playing (BR-153).
  match('match'),

  /// One question, five options, exactly one correct (BR-121).
  guess('guess'),

  /// Twenty seconds to recall it, and running out counts as wrong (BR-128,
  /// BR-107).
  recall('recall'),

  /// Type the answer; graded against the folded back, diacritics intact
  /// (BR-134).
  fill('fill'),

  /// A stored value this build does not recognise. Read-only.
  unknown(null);

  const StudyMode(this._dbValue);

  final String? _dbValue;

  /// The value stored in the database.
  ///
  /// Throws for [unknown]: a value nothing owns must never round-trip back into
  /// storage, where it would look like a decision somebody made.
  String get dbValue {
    final value = _dbValue;
    if (value == null) {
      throw StateError('StudyMode.unknown cannot be written to storage');
    }

    return value;
  }

  /// Whether this mode produces an action, and therefore a history row.
  ///
  /// Only [browse] does not (BR-111). Asking the mode is what keeps that rule
  /// in one place instead of in every caller's `if`.
  bool get producesAnswer => this != browse && this != unknown;

  /// Whether this mode repeats by round rather than by BR-26's comeback.
  ///
  /// The four graded modes do (BR-115); [selfAssess] does not, and [browse] has
  /// nothing to repeat. Getting this backwards is not a small bug: a
  /// [selfAssess] queue driven by rounds would drop BR-26's ceiling of 3, and a
  /// [match] queue driven by BR-26 would never finish its failed set.
  bool get usesRounds => switch (this) {
    match || guess || recall || fill => true,
    browse || selfAssess || unknown => false,
  };

  /// Maps a stored value to the enum, tolerating values from newer schemas.
  static StudyMode fromDbValue(String value) {
    for (final mode in values) {
      if (mode._dbValue == value) return mode;
    }

    return unknown;
  }
}
