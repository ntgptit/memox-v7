/// Where a `recall` turn is between being asked and being answered.
///
/// **A phase is not an outcome, and merging the two is the defect this enum was
/// split out of.** `RecallOutcome` used to carry a `revealed` member that stood
/// for both "the back is on screen" and "the learner got it right": pressing
/// *Show answer* wrote a correct answer and moved on, so a card the learner had
/// given up on was promoted a box for giving up. The two questions are
/// genuinely different — *what is the screen showing?* and *what did the learner
/// know?* — and only the second one is ever written down.
///
/// The order below is the order a turn moves through them. Every transition is
/// one-way; nothing here returns to [countdownRunning], because the clock is
/// spent once it has been stopped (BR-128, BR-133).
enum RecallPhase {
  /// Front up, back covered, clock running. Nothing has been written and
  /// nothing can be: the learner has told the app nothing yet.
  countdownRunning,

  /// The learner pressed *Show answer* before the mark. The clock stops, the
  /// back is uncovered, and the turn is now a question with two answers
  /// (BR-129). **Still no write** — revealing is not evidence of recall.
  selfAssessment,

  /// One of the two answers is being written. Both controls are disabled: a
  /// second tap during the transaction is a second answer to the same turn
  /// (BR-25, BR-126).
  submittingAssessment,

  /// The clock reached zero and the wrong answer is being written with
  /// `timeout` as its reason (BR-130, BR-131). The back stays covered until the
  /// write commits — a back revealed before the row exists is a verdict the
  /// session has no record of (BR-157).
  timedOutSubmitting,

  /// The timeout is recorded and the learner is reading the answer they missed.
  /// **Nothing advances by itself here**: the card was lost to a clock, so the
  /// one thing the screen owes them is as long as they want with the back of
  /// it. The only control is *Next*, and it writes nothing.
  timedOutReview,

  /// The timeout could not be written.
  ///
  /// Terminal in the same sense [timedOutReview] is: BR-130 says the outcome is
  /// locked to wrong and this turn will not offer *Remembered* again, whatever
  /// happened to the transaction. What it offers instead is the same wrong
  /// answer, once more.
  timedOutUnrecorded,

  /// The answer is in and the session is fetching what comes next. The card
  /// stays on screen (BR-158) and takes no further input.
  advancing;

  /// Whether the back of the card is readable.
  ///
  /// [timedOutSubmitting] is deliberately absent: the learner has already lost
  /// the card, so there is nothing to protect them from except a verdict that
  /// is not yet true.
  bool get isBackVisible =>
      this == selfAssessment ||
      this == submittingAssessment ||
      this == timedOutReview ||
      this == timedOutUnrecorded ||
      this == advancing;

  /// Whether the turn is still the learner's to answer, and therefore still
  /// worth saving for a Resume (BR-133).
  ///
  /// Once a write has started, the turn no longer belongs to this screen: it
  /// either committed — and the queue row is not pending any more — or it
  /// failed, and BR-85 has ended the session.
  bool get isUnanswered => this == countdownRunning || this == selfAssessment;
}
