import '../models/study_options_model.dart';
import '../repositories/study_repository.dart';

/// The options actually in force for a deck (BR-147).
///
/// One read returning both tiers already resolved. Handing back the app default
/// and the deck override separately would leave "which one wins" to be decided
/// again at every call site, and the settings screen and the session opener are
/// two call sites that must never disagree.
class GetStudyOptionsUseCase {
  const GetStudyOptionsUseCase(this._repository);

  final StudyRepository _repository;

  Future<StudyOptionsModel> call(String deckId) =>
      _repository.effectiveOptions(deckId);
}
