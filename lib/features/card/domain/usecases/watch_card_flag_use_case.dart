import '../repositories/card_repository.dart';

/// One card's flag as a stream, for the editor's toggle (BR-92). Thin — the read
/// is what it forwards, and it keeps the toggle off the repository (AD-12).
class WatchCardFlagUseCase {
  const WatchCardFlagUseCase(this._repository);

  final CardRepository _repository;

  Stream<bool> call(String cardId) => _repository.watchCardFlag(cardId);
}
