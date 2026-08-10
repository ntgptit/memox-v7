import 'package:memox/features/study/domain/entities/study_queue_item_entity.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_queue_item_status_model.dart';
import 'package:memox/features/study/domain/models/study_turn_model.dart';

/// One `recall` turn, as the queue hands it over.
///
/// **`isRevealed` and `round` are parameters because both decide a phase.** A
/// turn resumed with the back already uncovered is a different screen from one
/// resumed with the clock running (BR-133), and the same card in a later round
/// is a different turn from the one that timed out (BR-116) — the two facts the
/// widget reads off the row rather than assuming.
StudyTurnModel recallTurn(
  String id, {
  String back = 'công',
  int round = 1,
  bool isRevealed = false,
  int? remainingMs,
}) => StudyTurnModel(
  item: StudyQueueItemEntity(
    sessionId: 's1',
    mode: StudyMode.recall,
    round: round,
    cardId: id,
    position: 0,
    status: StudyQueueItemStatus.pending,
    availableAt: 0,
    answersInSession: 0,
    remainingMs: remainingMs,
    isRevealed: isRevealed,
  ),
  progress: StudyStageProgressModel(
    round: round,
    done: 0,
    total: 1,
    completedCardIds: const <String>[],
  ),
  card: StudyCardModel(
    id: id,
    front: 'front-$id',
    back: back,
    example: null,
    hint: null,
    pronunciation: null,
    backFolded: back,
  ),
);
