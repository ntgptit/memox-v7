import '../models/card_state_distribution_model.dart';
import '../repositories/card_repository.dart';

/// The deck's four-state distribution, for the progress panel (UC-04, D5).
///
/// Thin, like the other reads. The thresholds that decide the four states live
/// in `card_state_model.dart`; this use case forwards a stream the repository
/// already shaped with them.
class WatchCardStateDistributionUseCase {
  const WatchCardStateDistributionUseCase(this._repository);

  final CardRepository _repository;

  Stream<CardStateDistributionModel> call(String deckId) =>
      _repository.watchCardStateDistribution(deckId);
}
