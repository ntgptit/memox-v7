import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

import 'mx_stress_specimens.dart';

/// Every shared component, under the three conditions that actually break one.
///
/// This is the "sandbox gallery" idea as a test rather than as a hidden screen.
/// A screen would be production code — it would need an MX-VIS-001 audit
/// companion, it would ship inside the app, and nothing would fail if it rotted.
/// A test runs on every commit and names the component that broke.
///
/// The three conditions, and why these three:
///
/// - **320 x 640.** The narrowest width the app supports (M4.8b). Horizontal
///   overflow is a width problem and 393 hides it.
/// - **2.0x text scale.** The accessibility setting most likely to be on, and
///   the one that turns a one-line label into three.
/// - **Vietnamese copy long enough to wrap.** One of the two shipped locales,
///   ~25% longer than the English for the same sentence, with diacritics that
///   raise the line box. A layout sized against English fails here and nowhere
///   else.
///
/// Light *and* dark, because a theme changes text style, not just colour.
///
/// What it asserts is deliberately narrow: **no exception**, and **tap targets
/// large enough**. It does not assert pixels — the goldens do that, and a golden
/// at 2.0x scale would be a file nobody could read a diff of.
void main() {
  const Size narrow = Size(320, 640);
  const double largeTextScale = 2;

  Future<void> pumpSpecimen(
    WidgetTester tester,
    MxStressSpecimen specimen, {
    required ThemeData theme,
  }) async {
    tester.view.physicalSize = narrow;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // A component that sizes itself to its parent gets the whole body; one that
    // sizes itself to its content gets centred. Centring the former measures the
    // centring, not the component.
    final Widget child = specimen.needsBoundedHeight
        ? specimen.build()
        : Center(child: specimen.build());

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          // `copyWith`, never a fresh `MediaQueryData`: constructing one zeroes
          // `size`, `padding` and `viewInsets`, so the widget under test is told
          // the screen is 0x0 while `tester.view` says otherwise.
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(largeTextScale)),
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('no layout overflow at 320px and 2.0x text scale', () {
    for (final specimen in stressSpecimens()) {
      for (final MapEntry<String, ThemeData> theme in <String, ThemeData>{
        'light': buildLightTheme(),
        'dark': buildDarkTheme(),
      }.entries) {
        testWidgets('${specimen.name} · ${theme.key}', (tester) async {
          await pumpSpecimen(tester, specimen, theme: theme.value);

          // A `RenderFlex overflowed` is reported as a Flutter error, not thrown,
          // so a widget test passes while the frame shows a yellow-and-black
          // stripe. This is the line that turns that into a failure.
          expect(
            tester.takeException(),
            isNull,
            reason:
                '${specimen.name} overflowed in ${theme.key}. Wrap the text in '
                'Flexible/Expanded, or give it maxLines with an overflow.',
          );
        });
      }
    }
  });

  group('tap targets stay reachable at 2.0x text scale', () {
    for (final specimen in stressSpecimens().where(
      (specimen) => specimen.isInteractive,
    )) {
      testWidgets(specimen.name, (tester) async {
        await pumpSpecimen(tester, specimen, theme: buildLightTheme());

        // 48x48 (Material) rather than 44x44 (iOS): Android is the release
        // target (AD-04), and it is the stricter of the two.
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      });
    }
  });

  group('the specimen list covers every shared component', () {
    test('no file in lib/shared/widgets is missing from it', () {
      // Without this the suite silently stops being a suite: someone adds
      // `mx_chip.dart`, never adds a specimen, and every test here still passes.
      final Set<String> files = Directory('lib/shared/widgets')
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where((name) => name.endsWith('.dart'))
          .map(_classNameOf)
          .toSet();

      final Set<String> covered = stressSpecimens()
          // 'MxActionButton (loading)' is a second state of one component.
          .map((specimen) => specimen.name.split(' ').first)
          .toSet();

      // `MxAsyncView` is excluded: it renders whichever of three builders the
      // `AsyncValue` selects and has no layout of its own. Its three branches are
      // covered by `mx_async_view_test.dart`, and its content is whatever the
      // caller passed — which is one of the components above.
      expect(files.difference(covered), <String>{'MxAsyncView'});
    });
  });
}

/// `mx_list_tile.dart` -> `MxListTile`.
String _classNameOf(String fileName) => fileName
    .replaceAll('.dart', '')
    .split('_')
    .map((part) => part[0].toUpperCase() + part.substring(1))
    .join();
