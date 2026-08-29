import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `Icon(` in feature presentation code **and in the shared kit**
/// resolves its colour through `AppInk` — as `MxIcon(ink: …)` or, off the size
/// steps, as `color: <AppInk>.resolve(context)`.
///
/// **`lib/shared/widgets/` was outside this scan until M100.4, and that is the
/// whole story of how the kit fell behind the features it serves.** A sweep of
/// all 41 shared widgets measured `AppInk` at 82 files under `lib/features/`
/// against **three** widgets in the kit that defines it. The features were at
/// 82 because this test held them there; the kit was at three because nothing
/// did. `MxEmptyState` reached for `colors.primary` — the *fill* of a filled
/// button — and inked its glyph at 3.29:1 on the dark page, which M100.3 had
/// to measure and fix. The rule existed. The kit sat outside it.
///
/// **Colourless stays legal, and that exemption does the heavy lifting here.**
/// Six kit widgets wrap a glyph inside a button and pass no colour at all, so
/// it takes the `IconTheme` the button's own `ButtonStyle` resolves per state.
/// Naming an ink there would freeze one value and leave the icon lit while the
/// button goes disabled. The check below skips them for the same reason it
/// always did.
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

  /// Kit files allowed to pass a `Color` to a raw `Icon`, and why.
  ///
  /// Two entries, both argued rather than assumed. A third should cost the
  /// same argument — that is the difference between an exception and a habit,
  /// and the staleness check below makes a spent entry fail rather than
  /// quietly become permission for whatever is edited into that file next.
  const Map<String, String> allowedInKit = <String, String>{
    'mx_pill_button.dart':
        'reads DefaultTextStyle.of(context).style.color — the chip theme has '
        'already resolved its WidgetStateColor for this row. There is no '
        'AppInk member for "whatever the chip decided", and naming one would '
        'drop the selected and disabled states the theme resolves.',
  };

  Iterable<File> dartFilesUnder(String root) => Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((File file) {
        final path = file.path.replaceAll(r'\', '/');

        return path.endsWith('.dart') &&
            !path.endsWith('.g.dart') &&
            !path.endsWith('.freezed.dart');
      });

  /// Every `Icon(` in [file] that names a colour without going through
  /// `AppInk`, as `path:line` strings.
  List<String> offendersIn(File file) {
    final found = <String>[];
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
      found.add('${file.path.replaceAll(r'\', '/')}:$line');
    }

    return found;
  }

  test('shared kit Icons take their colour from AppInk', () {
    final offenders = <String>[];
    for (final file in dartFilesUnder('lib/shared/widgets')) {
      if (allowedInKit.containsKey(file.uri.pathSegments.last)) {
        continue;
      }
      offenders.addAll(offendersIn(file));
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Icon(color:) in the shared kit bypasses AppInk — and the kit is '
          'where the vocabulary is defined, so a raw colour here teaches every '
          'caller that one is fine. Use MxIcon(ink: …), or add the file to '
          'allowedInKit with a reason.\n${offenders.join('\n')}',
    );
  });

  test('no kit exemption outlives the reason for it', () {
    for (final name in allowedInKit.keys) {
      final file = File('lib/shared/widgets/$name');
      expect(
        file.existsSync(),
        isTrue,
        reason: '$name is exempted but no longer exists',
      );
      expect(
        offendersIn(file),
        isNotEmpty,
        reason:
            '$name no longer passes a Color to a raw Icon, so its exemption is '
            'spent — delete the entry rather than leaving a standing licence '
            'behind',
      );
    }
  });

  test('feature Icons take their colour from AppInk', () {
    final offenders = <String>[];
    final files = dartFilesUnder('lib/features').where(
      (File file) => file.path.replaceAll(r'\', '/').contains('/presentation/'),
    );

    for (final file in files) {
      offenders.addAll(offendersIn(file));
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
