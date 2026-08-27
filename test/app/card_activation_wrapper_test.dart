import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A feature must not rebuild `MxCard`'s activation with a `GestureDetector`.
///
/// The card owns its interactive contract — ink, keyboard activation, focus
/// ring, semantics, the 48dp floor — precisely so no call site has to. A
/// `GestureDetector(onTap: …)` wrapped around a card gives the tap back while
/// silently dropping every one of those, which is invisible in review because
/// the screen still "works" under a finger.
///
/// **Narrow on purpose.** Only an *activation* wrapper is a finding:
/// - a gesture that is not a tap — swipe, drag, long-press pan — stays legal,
///   because the card deliberately does not own those;
/// - a tap handler whose body is focus plumbing (`requestFocus`) stays legal:
///   the fill-mode answer card is a text field's surface, its tap moves focus
///   into the editable, and the semantics live on the `EditableText` — that
///   is field behaviour, not a rebuilt button.
///
/// Balanced-parentheses scan on the `icon_ink_boundary_test.dart` precedent:
/// `dart format` splits wide calls across lines, so a line-anchored rule
/// reports clean while the tree is not.

/// Comments blanked but newlines kept, so offender line numbers stay true.
String withoutComments(String source) {
  String blank(Match match) => match.group(0)!.replaceAll(RegExp('[^\n]'), ' ');

  return source
      .replaceAllMapped(RegExp(r'/\*.*?\*/', dotAll: true), blank)
      .replaceAllMapped(RegExp('//.*'), blank);
}

/// The argument list of the call opening at [openParen], or `null` when the
/// parentheses never balance.
String? balancedArgs(String source, int openParen) {
  var depth = 0;
  for (var i = openParen; i < source.length; i++) {
    final char = source[i];
    if (char == '(') depth += 1;
    if (char == ')') {
      depth -= 1;
      if (depth == 0) return source.substring(openParen + 1, i);
    }
  }

  return null;
}

/// Offender lines in [source]: every `GestureDetector(` whose arguments carry
/// a tap activation and a card-family child, minus the focus-plumbing
/// exemption.
List<int> activationWrapperLines(String source) {
  final cleaned = withoutComments(source);
  final offenders = <int>[];

  for (final match in RegExp(r'\bGestureDetector\s*\(').allMatches(cleaned)) {
    final openParen = cleaned.indexOf('(', match.start);
    final args = balancedArgs(cleaned, openParen);
    if (args == null) continue;
    if (!RegExp(r'\bonTap\s*:').hasMatch(args)) continue;
    if (!RegExp(r'\bMxCard\b').hasMatch(args)) continue;
    if (args.contains('requestFocus')) continue;

    offenders.add(cleaned.substring(0, match.start).split('\n').length);
  }

  return offenders;
}

void main() {
  test('no feature wraps a card in a tap-activation GestureDetector', () {
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) {
          final path = file.path.replaceAll(r'\', '/');

          return path.contains('/presentation/') &&
              path.endsWith('.dart') &&
              !path.endsWith('.g.dart') &&
              !path.endsWith('.freezed.dart');
        })
        .toList();

    // A scan of nothing proves nothing.
    expect(files, isNotEmpty, reason: 'no presentation files found to scan');

    final offenders = <String>[];
    for (final file in files) {
      for (final line in activationWrapperLines(file.readAsStringSync())) {
        offenders.add('${file.path.replaceAll(r'\', '/')}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A GestureDetector rebuilt a card\'s activation without its ink, '
          'focus, semantics or 48dp floor. Pass onTap to the MxCard recipe '
          'instead.\n${offenders.join('\n')}',
    );
  });

  group('fault injection — the scan fires both ways', () {
    test('a tap-activation wrapper around a card is a finding', () {
      const source = '''
Widget build(BuildContext context) => GestureDetector(
  onTap: () => controller.open(),
  child: MxCard.flat(child: Text('x')),
);
''';
      expect(activationWrapperLines(source), hasLength(1));
    });

    test('a swipe wrapper around a card passes', () {
      const source = '''
Widget build(BuildContext context) => GestureDetector(
  onHorizontalDragEnd: (details) => controller.next(),
  child: MxCard.focal(child: Text('x')),
);
''';
      expect(activationWrapperLines(source), isEmpty);
    });

    test('the focus-plumbing exemption passes, and only it', () {
      const source = '''
Widget build(BuildContext context) => GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: focusNode.requestFocus,
  child: MxCard.recessed(child: field),
);
''';
      expect(activationWrapperLines(source), isEmpty);
    });

    test('a tap wrapper around a non-card widget passes here', () {
      // Not this rule's business: raw InkWell/button rules own the general
      // case, this one owns the card family.
      const source = '''
Widget build(BuildContext context) => GestureDetector(
  onTap: onDismiss,
  child: ColoredBox(color: color),
);
''';
      expect(activationWrapperLines(source), isEmpty);
    });

    test('a card mentioned only in a comment does not trip the scan', () {
      const source = '''
Widget build(BuildContext context) => GestureDetector(
  // Not an MxCard wrapper: the card sits elsewhere.
  onTap: onDismiss,
  child: ColoredBox(color: color),
);
''';
      expect(activationWrapperLines(source), isEmpty);
    });
  });
}
