import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

/// What a picker hands back: a display name and the bytes, read immediately
/// into app memory so no file handle or shared-storage copy outlives the pick
/// (BR-173).
typedef PickedImportFile = ({String name, Uint8List bytes});

/// The seam between the repository and the platform picker.
///
/// An interface so host tests inject fixture bytes instead of a platform
/// channel — the system dialog itself is device-suite territory, and
/// everything after the pick is testable without it.
abstract interface class CardImportFilePicker {
  /// Null when the user cancelled. Cancel is not an error (UC-10 A5).
  Future<PickedImportFile?> pick();
}

/// The real picker, on `file_selector`'s system dialog.
///
/// The type group filters to the three supported extensions; providers that
/// ignore filters can still return anything, which is why the repository
/// re-checks the extension of what actually came back. No broad storage
/// permission is requested — the system picker grants access to the one file
/// the user chose.
final class CardImportFileDataSource implements CardImportFilePicker {
  const CardImportFileDataSource();

  static const XTypeGroup _spreadsheets = XTypeGroup(
    label: 'Spreadsheets',
    extensions: <String>['csv', 'tsv', 'xlsx'],
  );

  @override
  Future<PickedImportFile?> pick() async {
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[_spreadsheets],
    );
    if (file == null) return null;

    return (name: file.name, bytes: await file.readAsBytes());
  }
}
