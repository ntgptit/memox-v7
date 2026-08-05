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
  static const String reviewTab = 'Review';
  static const String cardEditorClose = 'Close';
  static const String detailsToggle = 'Add details';
  static const String detailsLabel = 'Details';
  static const String deleteCard = 'Delete card';
  static const String flagCard = 'Flag card';
  static const String unflagCard = 'Remove flag';
  static const String addTagHint = 'Add tag';
}
