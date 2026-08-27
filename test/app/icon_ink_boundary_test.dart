import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `Icon(` in feature presentation code resolves its colour through
/// `AppInk` — as `MxIcon(ink: …)` or, off the size steps, as
/// `color: <AppInk>.resolve(context)`.
///
/// **Why a Dart test and not a guard rule.** The guard reads one line at a
/// time, and `dart format` splits a wide `Icon(` call so that `Icon(` and
/// `color:` land on different lines. Forty call sites were carrying open
/// `ColorScheme` colours this way while the line-anchored `no_raw_icon_color`
/// rule reported the repo clean — not because the rule was wrong, but because
/// its window was. This test walks the balanced parentheses of each call, so
/// the argument list is one string no matter how many lines it spans.
///
/// The precedent is `architecture_boundary_test.dart`: when a rule needs to
/// see structure rather than a line, it becomes a test the suite runs.
void main() {
  /// Comments blanked but newlines kept, so offender line numbers stay true.
  String withoutComments(String source) {
    String blank(Match match) =>
        match.group(0)!.replaceAll(RegExp('[^\n]'), ' ');

    return source
        .replaceAllMapped(RegExp(r'/\*.*?\*/', dotAll: true), blank)
        .replaceAllMapped(RegExp('//.*'), blank);
  }

  /// The argument list of the call opening at [openParen], or `null` when the
  /// parentheses never balance (a truncated file — the analyzer's problem).
  String? balancedArgs(String source, int openParen) {
    var depth = 0;
    for (var i = openParen; i < source.length; i++) {
      final char = source[i];
      if (char == '(') {
        depth += 1;
      }
      if (char == ')') {
        depth -= 1;
        if (depth == 0) {
          return source.substring(openParen + 1, i);
        }
      }
    }

    return null;
  }

  test('feature Icons take their colour from AppInk', () {
    final offenders = <String>[];
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) {
          final path = file.path.replaceAll(r'\', '/');

          return path.contains('/presentation/') &&
              path.endsWith('.dart') &&
              !path.endsWith('.g.dart') &&
              !path.endsWith('.freezed.dart');
        });

    for (final file in files) {
      final source = withoutComments(file.readAsStringSync());
      for (final match in RegExp(r'\bIcon\s*\(').allMatches(source)) {
        final openParen = source.indexOf('(', match.start);
        final args = balancedArgs(source, openParen);
        if (args == null) {
          continue;
        }
        if (!RegExp(r'\bcolor\s*:').hasMatch(args)) {
          // Colourless is legal: the icon inherits its slot's IconTheme.
          continue;
        }
        if (args.contains('.resolve(')) {
          // The one open spelling: an AppInk resolved at an off-step size.
          continue;
        }
        final line = source.substring(0, match.start).split('\n').length;
        offenders.add('${file.path.replaceAll(r'\', '/')}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Icon(color:) in a feature bypasses AppInk. Use MxIcon(ink: …), '
          'or — only when the size has no MxIconSize step — '
          'color: <AppInk>.resolve(context).\n${offenders.join('\n')}',
    );
  });
}
