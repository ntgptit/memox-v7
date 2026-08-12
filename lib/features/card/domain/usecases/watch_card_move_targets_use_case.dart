import '../models/card_move_target_model.dart';
import '../repositories/card_repository.dart';

/// The decks a card may move into (UC-04 A5, BR-165).
class WatchCardMoveTargetsUseCase {
  const WatchCardMoveTargetsUseCase(this._repository);

  final CardRepository _repository;

  Stream<List<CardMoveTarget>> call(String sourceDeckId) =>
      _repository.watchMoveTargets(sourceDeckId);
}
