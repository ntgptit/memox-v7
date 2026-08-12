import '../models/card_import_result_model.dart';
import '../repositories/card_import_repository.dart';

/// Writes one import batch (UC-10 step 7, BR-171).
///
/// No validation here, twice over. The entries were parsed through the card
/// value objects before a plan could exist, so BR-169 is already answered by
/// the types; and every rule that needs the data as it stands at the moment
/// of writing — the target checks of BR-168, the duplicate recheck of
/// BR-170, the content-type step of BR-172 — lives inside the repository's
/// transaction, where it cannot race the write.
class CommitCardImportUseCase {
  const CommitCardImportUseCase(this._repository);

  final CardImportRepository _repository;

  Future<CardImportResult> call({
    required String deckId,
    required CardImportPlan plan,
  }) => _repository.commitImport(deckId: deckId, plan: plan);
}
