import '../../../../core/error/failure.dart';
import '../../domain/failures/card_transfer_failure.dart';
import '../../domain/models/card_transfer_format_model.dart';
import '../../domain/models/card_transfer_source_model.dart';
import '../../domain/repositories/card_import_source_repository.dart';
import '../datasources/card_import_file_data_source.dart';

/// The pick boundary (M99.19): the injected picker chooses the file, this
/// class checks that what came back resolves to a supported format. It never
/// decodes and never touches the database.
final class CardImportSourceRepositoryImpl
    implements CardImportSourceRepository {
  const CardImportSourceRepositoryImpl({
    required CardImportFilePicker picker,
    // A named parameter can't start with `_`, so the formal is impossible.
    // ignore: prefer_initializing_formals
  }) : _picker = picker;

  final CardImportFilePicker _picker;

  @override
  Future<CardTransferFileSource?> pickFile() async {
    final PickedImportFile? picked;
    try {
      picked = await _picker.pick();
    } on Failure {
      rethrow;
    } on Object {
      // A platform channel or file read can fail after the user chose — a
      // revoked grant, a vanished provider, an unreadable volume. The raw
      // exception carries paths and provider names the UI must never see
      // (BR-173), so it maps to the same typed value as a corrupt file: the
      // recovery is identical, pick or export a fresh copy.
      throw const ValidationFailure(
        message: 'The picked file could not be read.',
        problems: <Enum>{CardTransferProblem.unreadableFile},
      );
    }
    if (picked == null) return null;

    final format = CardTransferFormat.fromFileName(picked.name);
    if (format == null) {
      // Providers can ignore the picker's type filter, so the answer is
      // checked, not trusted (UC-10 E1).
      throw const ValidationFailure(
        message: 'The picked file is not a supported spreadsheet type.',
        problems: <Enum>{CardTransferProblem.unsupportedFile},
      );
    }

    return CardTransferFileSource(
      name: picked.name,
      bytes: picked.bytes,
      format: format,
    );
  }
}
