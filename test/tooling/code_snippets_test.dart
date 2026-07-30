import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Validates `.vscode/memox.code-snippets` against the VS Code snippet schema.
///
/// **Why a test for an editor file.** The snippets are checked in on purpose —
/// they carry the four things easiest to leave out of a hand-written controller —
/// but nothing else in the project reads them, so a malformed entry sits there
/// silently doing nothing. That already happened once: a `"//": [...]` entry was
/// added as a comment, and because every top-level key is treated as a snippet
/// definition, it was a broken snippet rather than prose. `flutter analyze` has no
/// opinion on JSON, and the guard has no rule for it, so this is the only gate
/// that would have caught it.
///
/// The file is JSONC — real `//` comments are valid — so they are stripped before
/// parsing, the same way VS Code does.
void main() {
  const path = '.vscode/memox.code-snippets';

  late final Map<String, dynamic> snippets;

  setUpAll(() {
    final file = File(path);
    expect(file.existsSync(), isTrue, reason: 'missing $path');
    snippets =
        jsonDecode(_stripJsonComments(file.readAsStringSync()))
            as Map<String, dynamic>;
  });

  test('every top-level entry is a snippet object', () {
    // The rule the `"//"` entry broke. VS Code has no notion of a top-level
    // comment key: whatever is there is a snippet, and a snippet without a
    // prefix can never be triggered — so it is dead weight that reads as
    // coverage.
    for (final entry in snippets.entries) {
      expect(
        entry.value,
        isA<Map<String, dynamic>>(),
        reason: '"${entry.key}" is not a snippet object',
      );

      final snippet = entry.value as Map<String, dynamic>;
      expect(
        snippet['prefix'],
        isA<String>().having((it) => it.trim(), 'trimmed', isNotEmpty),
        reason: '"${entry.key}" has no prefix, so nothing can trigger it',
      );
      expect(
        snippet['body'],
        isA<List<dynamic>>().having((it) => it, 'lines', isNotEmpty),
        reason: '"${entry.key}" has no body',
      );
      expect(
        snippet['description'],
        isA<String>().having((it) => it.trim(), 'trimmed', isNotEmpty),
        reason:
            '"${entry.key}" has no description. The picker shows the prefix and '
            'the description; without one, choosing between eight snippets means '
            'guessing.',
      );
    }
  });

  test('no two snippets share a prefix', () {
    // Two snippets on one prefix is a picker where the right answer depends on
    // ordering nobody controls.
    final byPrefix = <String, List<String>>{};
    for (final entry in snippets.entries) {
      final prefix = (entry.value as Map<String, dynamic>)['prefix'] as String;
      (byPrefix[prefix] ??= <String>[]).add(entry.key);
    }

    final clashes = byPrefix.entries.where((e) => e.value.length > 1).toList();

    expect(
      clashes,
      isEmpty,
      reason: clashes.map((e) => '${e.key}: ${e.value}').join('\n'),
    );
  });

  test('every body has exactly one final cursor stop', () {
    // `$0` is where the cursor lands when tabbing ends. None means it lands
    // after the snippet; two means the later one silently wins.
    for (final entry in snippets.entries) {
      final body = ((entry.value as Map<String, dynamic>)['body'] as List)
          .cast<String>()
          .join('\n');
      final stops = RegExp(r'\$0').allMatches(body).length;

      expect(
        stops,
        1,
        reason: '"${entry.key}" has $stops occurrences of \$0, expected 1',
      );
    }
  });

  test('placeholder indices are contiguous from 1', () {
    // A gap means a Tab press jumps somewhere unexpected, which is the kind of
    // defect nobody reports and everybody works around.
    for (final entry in snippets.entries) {
      final body = ((entry.value as Map<String, dynamic>)['body'] as List)
          .cast<String>()
          .join('\n');
      final indices =
          RegExp(r'\$\{(\d+):')
              .allMatches(body)
              .map((match) => int.parse(match.group(1)!))
              .toSet()
              .toList()
            ..sort();

      if (indices.isEmpty) continue;

      expect(
        indices,
        List<int>.generate(indices.length, (i) => i + 1),
        reason:
            '"${entry.key}" has placeholder indices $indices — expected 1..'
            '${indices.length} with no gaps',
      );
    }
  });

  test('nothing hardcodes a user-visible string into a Text widget', () {
    // The snippets emit production code, so they are held to the same rule as
    // the code they produce: copy comes from ARB (`context.l10n.<key>`), never a
    // literal. A snippet that shipped a literal would seed the violation into
    // every feature built from it.
    final offenders = <String>[];
    final literal = RegExp(r"""Text\(\s*(['"])(?![$])[^'"]*[A-Za-z]{2,}""");

    for (final entry in snippets.entries) {
      final lines = ((entry.value as Map<String, dynamic>)['body'] as List)
          .cast<String>();
      for (final line in lines) {
        if (literal.hasMatch(line)) offenders.add('${entry.key}: $line');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}

/// Strips `//` line comments, leaving anything inside a string literal alone.
///
/// Hand-written rather than pulled in as a dependency: this is the only JSONC
/// file in the project, and a package for twenty lines would be a dependency to
/// audit forever.
String _stripJsonComments(String source) {
  final out = StringBuffer();
  var inString = false;
  var escaped = false;

  for (var i = 0; i < source.length; i++) {
    final char = source[i];

    if (inString) {
      out.write(char);
      if (escaped) {
        escaped = false;
      } else if (char == r'\') {
        escaped = true;
      } else if (char == '"') {
        inString = false;
      }
      continue;
    }

    if (char == '"') {
      inString = true;
      out.write(char);
      continue;
    }

    final isLineComment =
        char == '/' && i + 1 < source.length && source[i + 1] == '/';
    if (!isLineComment) {
      out.write(char);
      continue;
    }

    // Skip to the end of the line, keeping the newline so line numbers in a
    // parse error still mean something.
    while (i < source.length && source[i] != '\n') {
      i++;
    }
    if (i < source.length) out.write('\n');
  }

  return out.toString();
}
