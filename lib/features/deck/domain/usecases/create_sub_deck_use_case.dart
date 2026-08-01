import '../entities/deck_entity.dart';
import '../failures/deck_validation_failure.dart';
import '../models/deck_name_model.dart';
import '../repositories/deck_repository.dart';

/// Creates a sub-deck under a parent (UC-08).
///
/// No scheduler argument: a sub-deck inherits from its root and must leave the
/// scheduler columns null (BR-06). Depth (BR-55) and the first-child content lock
/// (BR-62) stay in the repository, inside its transaction, because both need the
/// tree as it stands at the moment of writing — a check here would answer a
/// question about a moment that has already passed.
class CreateSubDeckUseCase {
  const CreateSubDeckUseCase(this._repository);

  final DeckRepository _repository;

  Future<DeckEntity> call({
    required String rawName,
    required String parentDeckId,
  }) async {
    final parsed = DeckName.parse(rawName);
    refuseInvalidDeckForm(<DeckValidationProblem>{?parsed.problem});
    final name = parsed.name;
    if (name == null) {
      throw StateError('unreachable: refuseInvalidDeckForm would have thrown');
    }

    return _repository.createSubDeck(name: name, parentDeckId: parentDeckId);
  }
}
