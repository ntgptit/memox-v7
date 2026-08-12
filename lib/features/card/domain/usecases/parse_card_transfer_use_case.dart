import '../models/card_transfer_document_model.dart';
import '../models/card_transfer_source_model.dart';
import '../repositories/card_transfer_repository.dart';

/// Decodes a chosen source into sheets of rows (UC-10 step 3).
///
/// Reads nothing and writes nothing to the database — decoding is a pure
/// transformation of bytes the user handed over, and it happens entirely in
/// app memory (BR-173). It runs when the user asks for a preview, never per
/// keystroke (wireframe I4).
class ParseCardTransferUseCase {
  const ParseCardTransferUseCase(this._repository);

  final CardTransferRepository _repository;

  Future<CardTransferDocument> call(CardTransferSource source) =>
      _repository.parse(source);
}
