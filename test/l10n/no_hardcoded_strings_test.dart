import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fails if a user-visible string literal appears anywhere in `lib/`.
///
/// This exists as a test, not only as a guard rule, because it has to hold for
/// `lib/app/**` too. The code-verification-guard i18n rule runs on product UI
/// (`lib/features/*/presentation`, `lib/shared`) and deliberately does not
/// cover the app shell — so without this test the shell is the one place a
/// hardcoded string could reappear unnoticed. That is exactly where the two it
/// used to have lived.
void main() {
  test('no Text() literal anywhere in lib/', () {
    // `Text('...')` with at least two letters inside. Interpolations and
    // single-character strings are not prose and are not the target here.
    final textLiteral = RegExp(
      r"""\bText\s*\(\s*(['"])(?![$])[^'"]*[A-Za-z]{2,}[^'"]*\1""",
    );

    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      // Generated bindings legitimately contain every translated string.
      if (entity.path.replaceAll(r'\', '/').contains('lib/l10n/generated/')) {
        continue;
      }

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (textLiteral.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'User-visible strings must come from the ARB files. Add the key '
          'to lib/l10n/app_en.arb and app_vi.arb, then use '
          'context.l10n.<key>.\n${offenders.join('\n')}',
    );
  });
}
