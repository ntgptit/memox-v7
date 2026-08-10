import 'dart:async';

import 'package:memox/features/study/domain/models/study_answer_commit_model.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';

/// A receipt for a write that went through.
///
/// **Named rather than built inline in forty places**, because what a test is
/// usually saying is "the transaction committed" — the round and the card id
/// only matter where the test is about them.
StudyAnswerCommitModel commitOf(
  String cardId, {
  int round = 1,
  StudyQueueItemStatus status = StudyQueueItemStatus.completed,
}) => StudyAnswerCommitModel(
  cardId: cardId,
  round: round,
  currentItemStatus: status,
);

/// A write held open, so a test can look at the screen **between** the tap and
/// the commit.
///
/// **A `Completer<void>` cannot express what these tests are about.** BR-157
/// splits three outcomes that a plain future collapses into one: still open,
/// committed, and refused. `Completer<void>` says only "finished", which is the
/// shape that let the board treat a refusal as a success in the first place.
///
/// Not completing it at all is the pending case; [commit] is the success case;
/// [refuse] is the null receipt a refused or superseded write produces.
final class PendingCommit {
  PendingCommit();

  final Completer<StudyAnswerCommitModel?> _completer =
      Completer<StudyAnswerCommitModel?>();

  Future<StudyAnswerCommitModel?> get future => _completer.future;

  bool get isPending => !_completer.isCompleted;

  void commit(
    String cardId, {
    StudyQueueItemStatus status = StudyQueueItemStatus.completed,
  }) => _completer.complete(commitOf(cardId, status: status));

  /// The write did not happen: refused by the repository, or a second
  /// submission arriving while the first was open.
  void refuse() => _completer.complete(null);
}
