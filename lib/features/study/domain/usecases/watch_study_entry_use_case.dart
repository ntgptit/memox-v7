import '../models/study_entry_summary_model.dart';
import '../repositories/study_repository.dart';

/// Watches the numbers the study entry point shows (BR-150, BR-154).
///
/// [now] is a parameter, never a clock read in here: the caller decides which
/// instant "due" is measured against, and a use case that read the clock itself
/// could not be tested at the `due_at == now` boundary.
class WatchStudyEntryUseCase {
  const WatchStudyEntryUseCase(this._repository);

  final StudyRepository _repository;

  Stream<StudyEntrySummaryModel> call(String deckId, {required DateTime now}) =>
      _repository.watchStudyEntry(deckId, now: now);
}
