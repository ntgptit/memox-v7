import '../entities/card_entity.dart';
import '../repositories/card_repository.dart';

/// One card by id, for the editor to prefill (UC-04 A1).
///
/// Thin, and that is the accepted cost AD-12 names: a read gets a use case even
/// when it forwards, so a new feature is a clone rather than a judgement call at
/// every operation.
class GetCardUseCase {
  const GetCardUseCase(this._repository);

  final CardRepository _repository;

  Future<CardEntity> call(String cardId) => _repository.getCard(cardId);
}
