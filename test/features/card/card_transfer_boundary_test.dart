import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The card-transfer layering, enforced instead of reviewed (M99.19).
///
/// Each check is a source scan with a named reason: the boundaries are what
/// make Export addable later without rewriting Import, and they erode one
/// convenient import at a time.
void main() {
  List<File> dartFilesUnder(String path) => Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .where((File f) => !f.path.endsWith('.g.dart'))
      .where((File f) => !f.path.endsWith('.freezed.dart'))
      .toList();

  Iterable<String> offenders(
    List<File> files,
    bool Function(String source, String path) isOffence,
  ) sync* {
    for (final file in files) {
      final source = file.readAsStringSync();
      if (isOffence(source, file.path)) yield file.path;
    }
  }

  test('presentation never sees a codec, a picker package or dart:io', () {
    // The wizard speaks domain models; which package parsed the bytes is a
    // data-layer fact. A widget importing `csv` is the seam leaking.
    final files = dartFilesUnder('lib/features/card/presentation');
    final found = offenders(
      files,
      (source, _) =>
          source.contains("package:csv/") ||
          source.contains("package:excel/") ||
          source.contains("package:file_selector/") ||
          source.contains("'dart:io'"),
    ).toList();

    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('decoders never see the database', () {
    // A codec is bytes to rows. The moment one reads a table, Export has to
    // drag SQLite into what should be a pure encoding path.
    final files = <File>[
      File(
        'lib/features/card/data/datasources/card_delimited_transfer_data_source.dart',
      ),
      File(
        'lib/features/card/data/datasources/card_xlsx_transfer_data_source.dart',
      ),
      File(
        'lib/features/card/data/datasources/card_transfer_resolver_data_source.dart',
      ),
    ];
    final found = offenders(
      files,
      (source, _) =>
          source.contains('package:drift/') ||
          source.contains('app_database.dart'),
    ).toList();

    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('the commit repository never sees a codec or the picker', () {
    // The DB half speaks canonical records. If it imports `csv`, the format
    // boundary has collapsed and the resolver is no longer the one dispatch.
    final source = File(
      'lib/features/card/data/repositories/card_import_repository_impl.dart',
    ).readAsStringSync();

    expect(source.contains('package:csv/'), isFalse);
    expect(source.contains('package:excel/'), isFalse);
    expect(source.contains('package:file_selector/'), isFalse);
    expect(source.contains('card_import_file_data_source.dart'), isFalse);
    expect(source.contains('transfer_data_source.dart'), isFalse);
  });

  test('format dispatch happens in the resolver alone', () {
    // A `CardTransferFormat.csv =>` arm anywhere else is a second registry,
    // free to disagree with the first. The format model owns its own
    // extension parsing; everything else asks the resolver.
    final files = dartFilesUnder('lib/features/card')
        .where(
          (File f) =>
              !f.path.endsWith('card_transfer_resolver_data_source.dart') &&
              !f.path.endsWith('card_transfer_format_model.dart'),
        )
        .toList();
    final found = offenders(
      files,
      (source, _) =>
          source.contains('CardTransferFormat.csv =>') ||
          source.contains('CardTransferFormat.xlsx =>'),
    ).toList();

    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('no dead export surface exists yet', () {
    // Export arrives with its first caller (M99.19 out of scope). A file or
    // API named for it today would be untested scaffolding pretending to be
    // a feature.
    final files = dartFilesUnder('lib/features/card');
    final named = files
        .where((File f) => f.path.toLowerCase().contains('export'))
        .toList();

    expect(named, isEmpty, reason: named.join('\n'));
  });
}
