import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/data/datasources/card_import_file_data_source.dart';
import 'package:memox/features/card/data/repositories/card_import_source_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_transfer_failure.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';

/// The pick boundary (UC-10 A5/E1, BR-173): what comes back from the
/// platform is checked, mapped or passed through — never trusted and never
/// leaked.
final class _ScriptedPicker implements CardImportFilePicker {
  _ScriptedPicker({this.result, this.error});

  final PickedImportFile? result;
  final Exception? error;

  @override
  Future<PickedImportFile?> pick() async {
    final failure = error;
    if (failure != null) throw failure;

    return result;
  }
}

void main() {
  CardTransferProblem? problemOf(Object failure) => failure is ValidationFailure
      ? failure.problems.whereType<CardTransferProblem>().firstOrNull
      : null;

  test('a supported pick becomes a typed source with its format', () async {
    final repository = CardImportSourceRepositoryImpl(
      picker: _ScriptedPicker(result: (name: 'words.tsv', bytes: Uint8List(4))),
    );

    final source = await repository.pickFile();

    expect(source!.name, 'words.tsv');
    expect(source.format, CardTransferFormat.tsv);
  });

  test('cancel stays a null, not an error (UC-10 A5)', () async {
    final repository = CardImportSourceRepositoryImpl(
      picker: _ScriptedPicker(),
    );

    expect(await repository.pickFile(), isNull);
  });

  test('an unsupported extension refuses with its own typed value', () async {
    final repository = CardImportSourceRepositoryImpl(
      picker: _ScriptedPicker(result: (name: 'words.pdf', bytes: Uint8List(4))),
    );

    expect(
      repository.pickFile,
      throwsA(
        predicate(
          (Object? e) => problemOf(e!) == CardTransferProblem.unsupportedFile,
        ),
      ),
    );
  });

  test('a platform or read error maps to unreadableFile, and the raw '
      'exception with its path never escapes (H, BR-173)', () async {
    final repository = CardImportSourceRepositoryImpl(
      picker: _ScriptedPicker(
        error: Exception('open failed: /storage/emulated/0/secret/words.csv'),
      ),
    );

    await expectLater(
      repository.pickFile,
      throwsA(
        predicate((Object? e) {
          if (problemOf(e!) != CardTransferProblem.unreadableFile) return false;
          final failure = e as Failure;

          // The sanitized diagnostic carries no path and no platform text.
          return !failure.message.contains('/storage') && failure.cause == null;
        }),
      ),
    );
  });
}
