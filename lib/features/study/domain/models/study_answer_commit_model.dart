import 'study_queue_item_status_model.dart';

/// What the transaction actually wrote, handed back to whoever asked for it.
///
/// **The controller must not infer this from the action.** `action.isLapse` says
/// what the user did; it does not say what happened to the row, because that is
/// the mode's [StudyLapsePolicy] and two modes answer it differently for the
/// same lapse. A screen that guessed would empty a `match` slot the database
/// still holds open — and it would be right about `guess` and wrong about
/// `match` while looking identical in both.
///
/// Small on purpose: it carries what a caller can act on without re-reading,
/// and nothing that would make it a second copy of the queue.
final class StudyAnswerCommitModel {
  const StudyAnswerCommitModel({
    required this.cardId,
    required this.round,
    required this.currentItemStatus,
  });

  final String cardId;

  /// The round the answer was given in — not the round the card may now also
  /// belong to. A lapse enrols the card in the next one (BR-116); this names
  /// the row that was written, so a caller comparing it against the turn on
  /// screen is comparing like with like.
  final int round;

  /// The status the row holds **after** the transaction committed.
  ///
  /// `completed` means the card has left this round's board; `pending` means it
  /// is still there to be answered (BR-118).
  final StudyQueueItemStatus currentItemStatus;

  /// Whether the card has left the current round.
  bool get isCleared => currentItemStatus == StudyQueueItemStatus.completed;
}
