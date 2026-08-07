/// What the user answered — in the vocabulary of the algorithm, not the screen.
///
/// **The two algorithms have different action sets** (BR-30). `eight_box` uses
/// [forgotten] / [remembered]; `sm2` uses [again] / [hard] / [good] / [easy].
/// A screen that renders four buttons is wrong for every `eight_box` deck, which
/// is why buttons come from the scheduler's `supportedActions` and never from a
/// list written into a widget.
///
/// **The label on screen is not this value** (BR-132). "Remembered" and "I knew
/// it" and a green tick can all mean [remembered]; only the canonical value is
/// stored, so renaming a button never rewrites history.
enum StudyAction {
  /// `eight_box`: wrong.
  forgotten('forgotten'),

  /// `eight_box`: right.
  remembered('remembered'),

  /// `sm2`: complete blank.
  again('again'),

  /// `sm2`: right, with difficulty.
  hard('hard'),

  /// `sm2`: right.
  good('good'),

  /// `sm2`: right, immediately.
  easy('easy');

  const StudyAction(this.dbValue);

  /// The value stored in the database.
  final String dbValue;

  /// Whether this action counts as a lapse (BR-20).
  ///
  /// Only meaningful on a `scheduled` turn; the caller decides that, because the
  /// action alone does not know which kind of turn it belongs to.
  bool get isLapse => this == forgotten || this == again;

  /// Maps a stored value to the enum.
  static StudyAction fromDbValue(String value) {
    for (final action in values) {
      if (action.dbValue == value) return action;
    }

    throw StateError('Unknown StudyAction: $value');
  }
}
