import '../failures/tag_catalog_failure.dart';
import '../failures/tag_validation_failure.dart';
import '../models/tag_name_model.dart';
import '../repositories/tag_catalog_repository.dart';

/// Renames a tag, which may turn out to be a merge (UC-12, BR-185, BR-186).
///
/// **BR-93's validation runs here, at the type boundary** — the same place
/// `AddCardTagUseCase` runs it, through the same `TagName.parse`. A rename that
/// validated its own way would be a second definition of what a tag name is,
/// and the two would agree until the day one of them changed.
///
/// **What does *not* run here is the collision test.** Whether the folded name
/// is free depends on the database as it stands at the moment of the write, so
/// it belongs inside the repository's BR-186 transaction. Hoisting it up to
/// this layer would put the check outside the transaction and make it a race —
/// the rule would be in a tidier place and be wrong.
class RenameTagUseCase {
  const RenameTagUseCase(this._repository);

  final TagCatalogRepository _repository;

  Future<TagRenameOutcome> call({
    required String tagId,
    required String rawName,
  }) async {
    final parsed = TagName.parse(rawName);
    final problem = parsed.problem;
    if (problem != null) {
      refuseInvalidTag(<TagValidationProblem>{problem});
    }

    return _repository.renameTag(tagId: tagId, name: parsed.name!);
  }
}
