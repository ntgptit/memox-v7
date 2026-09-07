import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A whole-screen review render must stand in the frame production draws.
///
/// **The defect this exists for, measured.** Eight rows of the screen gallery
/// were pumped as `ReviewApp(home: <Screen>)` — no router, so no
/// `AppNavigationShell` and no `MxNavigationBar` — while every one of those
/// screens production-routes inside a `StatefulShellBranch`. Regenerating them
/// through the router moved each by **10.2–10.5% of the frame**: the bar, and
/// the inset it takes out of the body. That is not a rounding difference, it is
/// the difference between a picture of the app and a picture of a frame the app
/// never draws (EV-04, `docs/reviews/impeccable-uiux-audit.md` §2).
///
/// The lesson was already written down, in the one demo file that got it right:
/// *"a bare pump loses the shell's navigation bar and its safe area, and those
/// are exactly the parts a layout review has to score"*
/// (`study_options_demo_test.dart`). It was applied in one file and not in its
/// siblings. This test is what stops that happening a third time.
///
/// **The subject list is read from the route table, not restated here.** Every
/// route in this app lives inside the one `StatefulShellRoute`, so a screen the
/// table constructs is a screen the shell wraps — and a screen added to the
/// table joins this contract by *existing*, not by somebody remembering.
void main() {
  /// Mounted over the shell rather than inside it, by a route-table decision.
  ///
  /// `CardImportScreen` is declared with `parentNavigatorKey: rootNavigatorKey`
  /// — it is a full-screen task that deliberately covers the bar (M4.12 I1). A
  /// bare mount is therefore the *faithful* render for it, and requiring the
  /// shell here would make the guard demand a picture production never draws.
  const overTheShell = <String>{'CardImportScreen'};

  /// Fixtures that still mount a branch-routed screen bare, and why.
  ///
  /// **Not silent.** EV-04's scope was the eight rows of
  /// `feature_screens_demo_test.dart`; these are the Card feature's own
  /// fixtures, which have the same shape and were left out of it. They are
  /// listed so the gap is a named debt rather than an absence — and so the next
  /// person to touch them has to decide, rather than inherit.
  const knownBare = <String, String>{
    'card_export_demo_test.dart':
        'CardListScreen behind the export sheet — EV-04 scope was the eight '
        'feature_screens rows; the Card fixtures were not in it.',
    'card_overflow_menu_demo_test.dart':
        'CardListScreen behind the overflow menu — same scope note.',
    'card_screens_demo_test.dart':
        'CardListScreen and CardEditorScreen — same scope note.',
    'tag_management_demo_test.dart':
        'CardListScreen and TagCatalogScreen — same scope note.',
  };

  String withoutComments(String source) {
    final withoutBlocks = source.replaceAll(
      RegExp(r'/\*.*?\*/', dotAll: true),
      '',
    );

    return withoutBlocks
        .split('\n')
        .map((String line) {
          final trimmed = line.trimLeft();
          if (trimmed.startsWith('///') || trimmed.startsWith('//')) return '';
          return line;
        })
        .join('\n');
  }

  test('every branch-routed screen in a demo fixture is mounted in the shell', () {
    final routed =
        RegExp(r'\b([A-Z]\w*Screen)\(')
            .allMatches(
              File('lib/app/router/app_router.dart').readAsStringSync(),
            )
            .map((RegExpMatch m) => m.group(1)!)
            .toSet()
          ..removeAll(overTheShell);

    expect(
      routed,
      isNotEmpty,
      reason:
          'no screen was read out of the route table, so this guard is watching '
          'nothing. The parse is what broke, not the app.',
    );

    final offenders = <String>[];
    final staleAllowances = knownBare.keys.toSet();

    for (final file in Directory('test/demo').listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (!name.endsWith('_test.dart')) continue;

      final source = withoutComments(file.readAsStringSync());
      final mounted =
          routed
              .where(
                (String screen) => RegExp('\\b$screen\\(').hasMatch(source),
              )
              .toList()
            ..sort();
      if (mounted.isEmpty) continue;

      // The shell can be reached three ways: this helper, a feature harness
      // that builds the router, or the router built in the file itself.
      final usesShell =
          source.contains('shellChild(') ||
          source.contains('ShellWith(') ||
          source.contains('createAppRouter');

      if (usesShell) {
        staleAllowances.remove(name);
        continue;
      }
      if (knownBare.containsKey(name)) {
        staleAllowances.remove(name);
        continue;
      }

      offenders.add(
        '$name mounts ${mounted.join(', ')} without the navigation shell. '
        'Production routes it inside a StatefulShellBranch, so the picture '
        'would be missing the bar and the inset it takes. Mount it with '
        'shellChild(<location>), or add it to knownBare with a reason.',
      );
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A whole-screen review render must stand in the frame production '
          'draws.\n${offenders.join('\n')}',
    );

    // The same staleness rule the icon-ink guard carries: an allowance nobody
    // prunes stops being a list of exceptions and becomes a list of files.
    expect(
      staleAllowances,
      isEmpty,
      reason:
          'These fixtures no longer mount a branch-routed screen bare, so their '
          'entry in knownBare is stale and should be deleted: '
          '${staleAllowances.join(', ')}',
    );
  });
}
