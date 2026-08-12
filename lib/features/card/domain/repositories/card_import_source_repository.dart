import '../models/card_transfer_source_model.dart';

/// The pick half of card import (M99.19): the one platform seam the wizard
/// needs. Its own contract so the decode and commit halves stay free of the
/// picker — and so a headless test never has to fake a system dialog it
/// cannot open.
abstract interface class CardImportSourceRepository {
  /// Opens the system file picker for the supported transfer formats. Null
  /// means the user cancelled — not an error, and not a reason to drop a
  /// previously chosen source (UC-10 A5). A picked file whose extension
  /// resolves to no supported format throws with
  /// `CardTransferProblem.unsupportedFile`, because pickers on some
  /// providers ignore their type filters.
  Future<CardTransferFileSource?> pickFile();
}
