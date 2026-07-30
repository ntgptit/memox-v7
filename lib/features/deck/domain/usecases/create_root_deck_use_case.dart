import '../entities/deck_entity.dart';
import '../failures/deck_validation_failure.dart';
import '../models/scheduler_type_model.dart';
import '../repositories/deck_repository.dart';

/// Creates a root deck (UC-02).
///
/// The scheduler is mandatory and has no default (BR-11): "not chosen yet" is a
/// real state the form starts in, and passing `eight_box` as a placeholder is
/// exactly the implicit default the rule exists to prevent.
///
/// The name check used to run twice — once in the controller and once again in
/// the repository — with nothing to catch the two disagreeing. It runs here now,
/// in the layer that owns BR-01.
class CreateRootDeckUseCase {
  const CreateRootDeckUseCase(this._repository);

  final DeckRepository _repository;

  Future<DeckEntity> call({
    required String name,
    required SchedulerType? schedulerType,
  }) {
    // Both checks run, so one attempt reports both problems. Reporting only the
    // first would send the user round twice.
    refuseInvalidDeckForm(<String, String>{
      ...?deckNameFieldError(name),
      if (schedulerType == null) DeckField.schedulerType: 'missing',
    });

    return _repository.createRootDeck(
      name: name,
      // Non-null past the refusal above, which is what makes it so.
      schedulerType: schedulerType!,
    );
  }
}
