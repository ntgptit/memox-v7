import '../models/card_transfer_source_model.dart';
import '../repositories/card_import_source_repository.dart';

/// Opens the file picker for an import source (UC-10 step 2).
///
/// Null is a cancel, and a cancel is not an error (UC-10 A5): the caller
/// keeps whatever source was already chosen. An unsupported extension comes
/// back as a typed failure, because pickers on some providers ignore their
/// type filters.
class PickCardImportSourceUseCase {
  const PickCardImportSourceUseCase(this._repository);

  final CardImportSourceRepository _repository;

  Future<CardTransferFileSource?> call() => _repository.pickFile();
}
