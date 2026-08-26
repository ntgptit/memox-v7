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

      // Four exclusions, and each is excluded for the same reason: it has no
      // layout of its own, so a stress specimen would be measuring whatever the
      // caller passed rather than the component.
      //
      // * `MxAsyncView` renders whichever of three builders the `AsyncValue`
      //   selects; its branches are covered by `mx_async_view_test.dart`.
      // * `MxFormSheet` is a `showModalBottomSheet` configuration plus a host
      //   that returns its child untouched. What it *does* own — the keyboard
      //   inset, and closing on the `shouldClose` transition rather than on the
      //   value — is behaviour a static specimen cannot show, so it is covered
      //   by `mx_form_sheet_test.dart` instead.
      // * `MxFailureLabelsWidget` contains no widget at all: it is the
      //   `Failure` → copy mapping, and `_widget` stays in the file name for
      //   the same reason `deck_labels_widget.dart` keeps it — the suffix is
      //   what puts the file in scope for the rules meant to cover it.
      // * `MxUndoSnackBar` contains no widget either: it is one function that
      //   configures Material's own `SnackBar` and hands it to the
      //   `ScaffoldMessenger`. There is nothing to lay out at 320dp — what it
      //   owns is the duration and the single-tap guarantee, which
      //   `deck_undo_widget` and `card_undo_widget` exercise through it.
      // * `MxBreadcrumbStep` is not a component: `mx_breadcrumb_step.dart` is
      //   a `part` of `mx_breadcrumb.dart` holding its private step and
      //   separator, and the specimen for both is the breadcrumb itself.
      // * `MxDialogTone` contains no widget: it is the severity enum and the
      //   token lookup behind it. What it produces — an icon inside a headline
      //   row — is stressed as `MxConfirmDialog (toned)`.
      // * `MxAsyncConfirmDialog` renders an `MxConfirmDialog` and adds no
      //   layout to it. What it owns is the close policy and the fire-once
      //   transition, which a static specimen cannot show and
      //   `mx_async_confirm_dialog_test.dart` covers instead — the same trade
      //   as `MxFormSheet` above.
      // * `MxSheetInsets` is padding: a specimen would measure whatever child
      //   it was handed. What it owns is the bottom obstruction formula, and
      //   `mx_sheet_insets_test.dart` measures that against a real
      //   `viewPadding` — which is the only configuration the bug it fixes is
      //   visible in.
      // * `MxDialogMetrics` is two constants and one arithmetic expression —
      //   there is nothing to lay out. What reads them is asserted where it
      //   matters, in `mx_button_pair_test.dart` and `mx_form_dialog_test.dart`.
      expect(files.difference(covered), <String>{
        'MxAsyncConfirmDialog',
        'MxAsyncView',
        'MxBreadcrumbStep',
        'MxDialogMetrics',
        'MxDialogTone',
        'MxFailureLabelsWidget',
        'MxFormSheet',
        'MxSheetInsets',
        'MxUndoSnackBar',
      });
    });
  });
}

/// `mx_list_tile.dart` -> `MxListTile`.
String _classNameOf(String fileName) => fileName
    .replaceAll('.dart', '')
    .split('_')
    .map((part) => part[0].toUpperCase() + part.substring(1))
    .join();
