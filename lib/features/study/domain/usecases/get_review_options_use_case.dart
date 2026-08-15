import '../../../../core/error/failure.dart';
import '../models/study_review_options_model.dart';
import '../models/study_scheduler.dart';
import '../repositories/study_repository.dart';

/// What the entry point may offer for a review of this deck (BR-146, BR-203).
///
/// The list of modes belongs to the root deck's algorithm, so answering it needs
/// a read **and** the scheduler — which is exactly why a screen must not work it
/// out for itself.
///
/// **It returns the algorithm too, rather than only the modes.** Whether the
/// direction chooser applies is a fact about the algorithm (BR-203), and a screen
/// that asked for it in a second call would be holding two snapshots of a deck
/// that a scheduler change can move between them (AD-13).
class GetReviewOptionsUseCase {
  const GetReviewOptionsUseCase(this._repository);

  final StudyRepository _repository;

  Future<StudyReviewOptionsModel> call(String deckId) async {
    final context = await _repository.deckContext(deckId);
    final scheduler = schedulerFor(context.schedulerType);

    // A deck on an algorithm this build does not know is readable but not
    // studiable; offering it an empty chooser would be offering nothing.
    if (scheduler == null) {
      throw const ConflictFailure(
        message: 'This deck uses an algorithm this version does not know',
      );
    }

    return StudyReviewOptionsModel(
      modes: scheduler.reviewModes,
      schedulerType: context.schedulerType,
    );
  }
}
