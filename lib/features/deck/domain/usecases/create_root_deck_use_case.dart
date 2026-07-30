import '../entities/deck_entity.dart';
import '../failures/deck_validation_failure.dart';
import '../models/deck_name_model.dart';
import '../models/scheduler_type_model.dart';
import '../repositories/deck_repository.dart';

/// Creates a root deck (UC-02).
///
/// The scheduler is mandatory and has no default (BR-11): "not chosen yet" is a
/// real state the form starts in, and passing `eight_box` as a placeholder is
/// exactly the implicit default the rule exists to prevent.
///
/// **This is the only place the deck name rule is applied for this interaction.**
/// [DeckName.parse] trims once and reports the rule it broke; the repository
/// contract then takes the parsed value, so it has nothing left to check.
class CreateRootDeckUseCase {
  const CreateRootDeckUseCase(this._repository);

  final DeckRepository _repository;

  Future<DeckEntity> call({
    required String rawName,
    required SchedulerType? schedulerType,
  }) {
    // Both fields are evaluated before anything is reported, so one attempt
    // reports both problems. Reporting only the first would send the user round
    // twice.
    final parsed = DeckName.parse(rawName);
    final problems = <DeckValidationProblem>{
      ?parsed.problem,
      if (schedulerType == null) DeckValidationProblem.schedulerMissing,
    };
    refuseInvalidDeckForm(problems);

    // Both non-null past the refusal above, and the analyser can see it: the set
    // is empty only when `parsed.problem` was null and `schedulerType` was not.
    final name = parsed.name;
    if (name == null || schedulerType == null) {
      throw StateError('unreachable: refuseInvalidDeckForm would have thrown');
    }

    return _repository.createRootDeck(name: name, schedulerType: schedulerType);
  }
}
