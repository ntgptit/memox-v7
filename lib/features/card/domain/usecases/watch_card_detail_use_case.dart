import '../models/card_detail_model.dart';
import '../repositories/card_detail_repository.dart';

/// Opening a card to read it (UC-19 main flow, BR-240).
///
/// Thin, and that is the accepted cost of AD-12's one-use-case-per-interaction:
/// what it buys is that the controller depends on an interaction rather than on
/// a repository, so the day this read grows a second source the controller does
/// not change.
class WatchCardDetailUseCase {
  const WatchCardDetailUseCase(this._repository);

  final CardDetailRepository _repository;

  Stream<CardDetailModel> call(String cardId) =>
      _repository.watchCardDetail(cardId);
}
