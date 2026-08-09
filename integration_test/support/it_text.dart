/// The user-facing copy the scenarios drive, named once.
///
/// Taken from `lib/l10n/app_en.arb`. Scenarios assert meaning rather than
/// wording (execution guide §9), but the robot has to *find* things, and a
/// literal repeated across twenty tests is twenty edits when the copy changes.
abstract final class ItText {
  static const String newDeck = 'New deck';
  static const String createSubmit = 'Create';
  static const String cancel = 'Cancel';
  static const String eightBox = 'Eight boxes';
  static const String sm2 = 'SM-2';
  static const String decksEmpty = 'No decks yet';
  static const String addToThisDeck = 'Add to this deck';
  static const String newSubDeck = 'New sub-deck';
  static const String newCard = 'New card';
  static const String cardListEmptyAction = 'Add card';
  static const String saveCard = 'Save card';
  static const String deckActions = 'Deck actions';
  static const String rename = 'Rename';
  static const String delete = 'Delete';
  static const String move = 'Move';
  static const String resetContentType = 'Allow cards or decks again';
  static const String allowBoth = 'Allow both';
  static const String decksTab = 'Decks';

  /// The deck level's way into its card list (BR-63, W1).
  static const String openCards = 'Open cards';

  /// The second tab. It read `Review` until #186 renamed Review to Study in
  /// `lib/` — the same rename that left four deck goldens a version behind.
  static const String studyTab = 'Study';
  static const String cardEditorClose = 'Close';
  static const String detailsToggle = 'Add details';
  static const String detailsLabel = 'Details';
  static const String deleteCard = 'Delete card';
  static const String flagCard = 'Flag card';
  static const String unflagCard = 'Remove flag';
  static const String addTagHint = 'Add tag';

  // Study (M5.15). The counts and the two entry buttons come from the study
  // entry screen; the rest is the session frame every mode wears.
  /// The card list's progress panel, on a deck whose cards are all new. It is
  /// the only way into a first session: the deck tile's Study button appears
  /// only when something is due (BR-150).
  static const String studyLearnEntry = 'new cards';
  static const String studyLearnNew = 'Learn new';
  static const String studyReview = 'Review';

  /// **Uppercase, and that is the widget rather than this constant shouting.**
  /// `MxSessionTopBar` uppercases the mode chip itself (#239), so the string on
  /// screen is not the ARB string — a `find.text('Browse')` matches nothing and
  /// says "no Browse on screen", which sends the reader looking for a missing
  /// stage instead of a changed label.
  static const String studyBrowseMode = 'BROWSE';
  static const String studyBrowseHint = 'Read both sides, then continue';
  static const String studyContinue = 'Next';
  static const String studyClose = 'Close session';
  static const String studyRevealAnswer = 'Show answer';
  static const String studyFillSubmit = 'Check';
  static const String studyActionRemembered = 'Remembered';
  static const String studyBackToDeck = 'Back to deck';
}
