import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reads the ARB sources directly rather than the generated bindings.
///
/// The generated code cannot expose a missing translation: gen-l10n falls back
/// to the template, so `app_vi.arb` could lose a key and every widget test
/// would still pass while Vietnamese users silently read English. The only
/// place that gap is visible is the ARB files themselves.
void main() {
  Map<String, dynamic> readArb(String fileName) {
    final file = File('lib/l10n/$fileName');
    expect(file.existsSync(), isTrue, reason: 'missing ARB file: $fileName');

    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((key) => !key.startsWith('@')).toSet();

  late final Map<String, dynamic> enArb;
  late final Map<String, dynamic> viArb;

  setUpAll(() {
    enArb = readArb('app_en.arb');
    viArb = readArb('app_vi.arb');
  });

  test('app_vi.arb has exactly the keys of app_en.arb', () {
    final enKeys = messageKeys(enArb);
    final viKeys = messageKeys(viArb);

    expect(
      viKeys.difference(enKeys),
      isEmpty,
      reason: 'app_vi.arb has keys that app_en.arb does not define',
    );
    expect(
      enKeys.difference(viKeys),
      isEmpty,
      reason:
          'app_vi.arb is missing keys — Vietnamese would fall back to '
          'English without any visible failure',
    );
  });

  test('every message in both files carries a description', () {
    for (final entry in <String, Map<String, dynamic>>{
      'app_en.arb': enArb,
      'app_vi.arb': viArb,
    }.entries) {
      for (final key in messageKeys(entry.value)) {
        final metadata = entry.value['@$key'];

        expect(
          metadata,
          isA<Map<String, dynamic>>(),
          reason: '${entry.key}: "$key" has no @$key metadata block',
        );
        final description = (metadata as Map<String, dynamic>)['description'];
        expect(
          description,
          isA<String>().having((it) => it.trim(), 'trimmed', isNotEmpty),
          reason:
              '${entry.key}: "$key" has no description. A translator '
              'without context guesses, and guesses wrong on short strings.',
        );
      }
    }
  });

  test('both files declare their @@locale', () {
    expect(enArb['@@locale'], 'en');
    expect(viArb['@@locale'], 'vi');
  });

  test('no message is left empty', () {
    for (final entry in <String, Map<String, dynamic>>{
      'app_en.arb': enArb,
      'app_vi.arb': viArb,
    }.entries) {
      for (final key in messageKeys(entry.value)) {
        expect(
          (entry.value[key] as String).trim(),
          isNotEmpty,
          reason: '${entry.key}: "$key" is empty',
        );
      }
    }
  });
}
