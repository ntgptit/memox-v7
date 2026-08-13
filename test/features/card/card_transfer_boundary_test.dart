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

  test('presentation never sees a codec, a plugin or dart:io', () {
    // The wizard speaks domain models; which package parsed the bytes is a
    // data-layer fact. A widget importing `csv` is the seam leaking.
    //
    // `share_plus` joined the list at M99.21 for the export direction (AD-20,
    // "presentation không thấy codec hay plugin"): the export sheet asks a use
    // case to hand a file over and must not know that a share sheet is what
    // takes it, or the sheet stops being testable without a device.
    final files = dartFilesUnder('lib/features/card/presentation');
    final found = offenders(
      files,
      (source, _) =>
          source.contains("package:csv/") ||
          source.contains("package:excel/") ||
          source.contains("package:file_selector/") ||
          source.contains("package:share_plus/") ||
          source.contains("'dart:io'"),
    ).toList();

    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('share_plus is imported by the destination adapter and nowhere '
      'else', () {
    // The export direction's one platform seam (BR-181). A second importer is
    // a second place the app can write a file, ask for a permission or name a
    // path — and the first one it would break is the web build, which has no
    // `dart:io` and is the E2E channel.
    const adapter = 'card_export_destination_repository_impl.dart';
    final files = dartFilesUnder(
      'lib/features/card',
    ).where((File f) => !f.path.endsWith(adapter)).toList();
    final found = offenders(
      files,
      (source, _) => source.contains('package:share_plus/'),
    ).toList();

    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('the export read repository never sees a codec or the share '
      'sheet', () {
    // The decode side's rule applied to the read half (M99.21): it speaks
    // canonical records, so a format, a byte or a plugin appearing here means
    // the three narrow contracts AD-20 keeps apart have collapsed into one.
    final source = File(
      'lib/features/card/data/repositories/card_export_repository_impl.dart',
    ).readAsStringSync();

    expect(source.contains('package:csv/'), isFalse);
    expect(source.contains('package:excel/'), isFalse);
    expect(source.contains('package:share_plus/'), isFalse);
    expect(source.contains('transfer_encoder_data_source.dart'), isFalse);
    expect(source.contains("'dart:io'"), isFalse);
  });

  test('the share adapter never sees the database or a codec', () {
    // The other direction of the same seam: handing a file to the OS is not a
    // place to read a row or encode one, and an adapter that could do either
    // would need a database to be tested.
    final source = File(
      'lib/features/card/data/repositories/'
      'card_export_destination_repository_impl.dart',
    ).readAsStringSync();

    expect(source.contains('package:drift/'), isFalse);
    expect(source.contains('app_database.dart'), isFalse);
    expect(source.contains('package:csv/'), isFalse);
    expect(source.contains('package:excel/'), isFalse);
    // `dart:io` would compile out of the web build, which is the E2E channel.
    // The artifact travels as bytes precisely so this stays true.
    expect(source.contains("'dart:io'"), isFalse);
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

  test('format dispatch happens in the resolvers alone', () {
    // A `CardTransferFormat.csv =>` arm anywhere else is a third registry,
    // free to disagree with the other two. There are exactly two — decode and
    // encode, one per pipeline (AD-20) — and the format model owns its own
    // extension parsing, its extension and its MIME type as members so a
    // filename builder never needs a switch.
    final files = dartFilesUnder('lib/features/card')
        .where(
          (File f) =>
              !f.path.endsWith('card_transfer_resolver_data_source.dart') &&
              !f.path.endsWith(
                'card_transfer_encoder_resolver_data_source.dart',
              ) &&
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

  test('encoders never see the database, the UI or the share sheet', () {
    // The decode-side rule, mirrored (M99.21). An encoder is records to bytes:
    // the moment one reads a table, renders a widget or knows how the file
    // leaves the app, the export pipeline stops being testable without a
    // device and the boundary that made Export addable at all is gone.
    final files = <File>[
      File(
        'lib/features/card/data/datasources/card_delimited_transfer_encoder_data_source.dart',
      ),
      File(
        'lib/features/card/data/datasources/card_xlsx_transfer_encoder_data_source.dart',
      ),
      File(
        'lib/features/card/data/datasources/card_transfer_encoder_resolver_data_source.dart',
      ),
    ];
    final found = offenders(
      files,
      (source, _) =>
          source.contains('package:drift/') ||
          source.contains('app_database.dart') ||
          source.contains('package:flutter/') ||
          source.contains('package:share_plus/') ||
          source.contains("'dart:io'"),
    ).toList();

    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('one tags codec serves both directions (BR-176)', () {
    // A second `split(kCardTransferTagsSeparator)` or a bare `join(';')` is
    // the exact bug BR-176 exists to prevent: two implementations that agree
    // on `a;b` and disagree the moment a tag contains a `;`.
    final files = dartFilesUnder('lib/features/card')
        .where(
          (File f) => !f.path.endsWith('card_transfer_tag_codec_model.dart'),
        )
        .toList();
    final found = offenders(
      files,
      (source, _) =>
          source.contains('split(kCardTransferTagsSeparator)') ||
          source.contains("split(';')") ||
          source.contains("join(';')") ||
          source.contains('join(kCardTransferTagsSeparator)'),
    ).toList();

    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('only the export read restores stored text past its limit', () {
    // `fromStored` drops BR-08/BR-93/BR-95's length caps so an export cannot be
    // refused over a limit tightened after the row was written. That is a read
    // affordance and nothing else: a write path calling it would put text into
    // the database that the editor can never show or fix, which is the bug the
    // value objects exist to make impossible.
    const reader = 'card_export_repository_impl.dart';
    final files = dartFilesUnder('lib')
        .where(
          (File f) =>
              !f.path.endsWith(reader) &&
              !f.path.endsWith('card_text_model.dart') &&
              !f.path.endsWith('tag_name_model.dart'),
        )
        .toList();
    // Named per type rather than a bare `.fromStored(`: `StudyCardLimit` has
    // one too, for its own unrelated reason, and a guard that fires on a word
    // instead of on the thing it protects gets weakened the first time it is
    // wrong.
    final found = offenders(
      files,
      (source, _) =>
          source.contains('CardText.fromStored(') ||
          source.contains('CardDetailText.fromStored(') ||
          source.contains('TagName.fromStored('),
    ).toList();

    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('the export use case never sees a package, a plugin or the database', () {
    // Domain stays plain Dart (AD-12): the use case orchestrates a read, an
    // encode and a hand-off, and must not know which package does any of them.
    final source = File(
      'lib/features/card/domain/usecases/export_cards_use_case.dart',
    ).readAsStringSync();

    expect(source.contains('package:csv/'), isFalse);
    expect(source.contains('package:excel/'), isFalse);
    expect(source.contains('package:share_plus/'), isFalse);
    expect(source.contains('package:drift/'), isFalse);
    expect(source.contains('package:flutter/'), isFalse);
    expect(source.contains("'dart:io'"), isFalse);
    // BR-180's other half — no ambient clock read anywhere in domain — is the
    // guard's `memox.data_model.scheduler_no_ambient_now`, which already scans
    // every domain file. Restating it here would be a second owner of one rule.
  });
}
