import '../entities/tag_entity.dart';
import '../repositories/card_repository.dart';

/// One card's tags as a stream, for the editor's chip strip and the row's chips
/// (BR-93).
class WatchCardTagsUseCase {
  const WatchCardTagsUseCase(this._repository);

  final CardRepository _repository;

  Stream<List<TagEntity>> call(String cardId) =>
      _repository.watchCardTags(cardId);
}
