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
    final picked = await _picker.pick();
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
