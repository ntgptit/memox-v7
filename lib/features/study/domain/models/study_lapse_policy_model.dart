/// What a wrong answer does to the queue row it was given on.
///
/// **A mode's rule, stated as a value so the repository does not have to name
/// the mode.** The effect used to be an `if (mode == StudyMode.match)` inside
/// the transaction, which put a second exhaustive branch on [StudyMode] in the
/// data layer — the thing AD-18 allows in exactly one place. `match` is not
/// special because it is `match`; it is special because its board keeps the
/// card on screen after a wrong answer, and that is a property of the mode
/// worth naming.
///
/// Four values rather than a boolean pair, because "does the row complete" and
/// "does the card come back" are independent questions and three of the four
/// combinations are real.
enum StudyLapsePolicy {
  /// There is no answer to record at all — `browse` shows a card and moves past
  /// it (BR-111). Present so the resolver stays total; nothing reaches the
  /// queue effect with it.
  noAnswer,

  /// The card stays in this one queue and comes back after at least three
  /// others (BR-26), or leaves and is flagged once it has used its three turns
  /// (BR-104). `self_assess` alone, which does not run in rounds.
  spacedRetry,

  /// The row is done and the card joins the next round (BR-115, BR-116). The
  /// card leaves the screen the moment it is answered, so there is nothing left
  /// to try again in this round.
  completeAndEnrollNextRound,

  /// The card joins the next round (BR-116) **and** the row it was answered on
  /// stays open (BR-118).
  ///
  /// `match` alone, and the reason is its board: the pair is still on screen,
  /// so completing the row would empty its slot — `completedCardIds` is what
  /// the board reads to decide which slots are done — and the user would be
  /// left looking at a board with a pair missing and no way to answer it.
  retainAndEnrollNextRound,
}
