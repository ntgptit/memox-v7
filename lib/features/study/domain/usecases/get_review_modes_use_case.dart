import '../../../../core/error/failure.dart';
import '../models/study_mode.dart';
import '../models/study_scheduler.dart';
import '../repositories/study_repository.dart';

/// Which modes this deck may be reviewed in (BR-146).
///
/// The list belongs to the root deck's algorithm, so answering it needs a read
/// **and** the scheduler — which is exactly why a screen must not work it out
/// for itself.
class GetReviewModesUseCase {
  const GetReviewModesUseCase(this._repository);

  final StudyRepository _repository;

  Future<List<StudyMode>> call(String deckId) async {
    final context = await _repository.deckContext(deckId);
    final scheduler = schedulerFor(context.schedulerType);

    // A deck on an algorithm this build does not know is readable but not
    // studiable; offering it an empty chooser would be offering nothing.
    if (scheduler == null) {
      throw const ConflictFailure(
        message: 'This deck uses an algorithm this version does not know',
      );
    }

    return scheduler.reviewModes;
  }
}
