import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_action_sheet.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The four conditions Phase 7.4 names: small screen, large text, keyboard
/// open, landscape.
///
/// Landscape is the one that had never been tested, and it is where the only
/// real defect was: portrait is 852 logical pixels tall, so a form fits with
/// room to spare no matter what. Rotate the same form and the height available
/// drops to 393 — less than half — and the keyboard takes 200 more of it.
///
/// There is deliberately no tablet or desktop case here. AD-04 fixes Android
/// phone as the release target and the web build is framed to 393x852, so a
/// large-screen branch would be a branch no code takes.
void main() {
  const portrait = Size(393, 852);
  const landscape = Size(852, 393);

  /// A soft keyboard on a Pixel-class phone, in logical pixels.
  const portraitKeyboard = EdgeInsets.only(bottom: 336);
  const landscapeKeyboard = EdgeInsets.only(bottom: 200);

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size surface = portrait,
    EdgeInsets viewInsets = EdgeInsets.zero,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: surface,
            viewInsets: viewInsets,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The card editor: the tallest fixed body the app has.
  Widget cardEditor({required bool isScrollable}) => MxContentShell(
    title: 'New card',
    isScrollable: isScrollable,
    body: Column(
      children: <Widget>[
        MxTextField(controller: TextEditingController(), label: 'Name'),
        const SizedBox(height: 16),
        MxTextField(
          controller: TextEditingController(),
          label: 'Front',
          minLines: 3,
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        MxTextField(
          controller: TextEditingController(),
          label: 'Back',
          minLines: 3,
          maxLines: 5,
        ),
      ],
    ),
  );

  group('MxContentShell', () {
    testWidgets('a fixed body overflows in landscape without isScrollable', (
      tester,
    ) async {
      // Pinned on purpose. This is the trap the flag exists for, and a test that
      // only proved the fixed path works would let someone "simplify" the flag
      // away without anything going red.
      await pump(
        tester,
        cardEditor(isScrollable: false),
        surface: landscape,
        textScale: 2,
      );

      expect(tester.takeException(), isFlutterError);
    });

    testWidgets('isScrollable survives landscape at textScaler 2', (
      tester,
    ) async {
      await pump(
        tester,
        cardEditor(isScrollable: true),
        surface: landscape,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('isScrollable survives landscape with the keyboard open', (
      tester,
    ) async {
      await pump(
        tester,
        cardEditor(isScrollable: true),
        surface: landscape,
        viewInsets: landscapeKeyboard,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('a short scrollable body still fills the viewport', (
      tester,
    ) async {
      // The reason for `ConstrainedBox(minHeight:)`. A plain
      // `SingleChildScrollView` shrink-wraps, and a body that expects the
      // viewport height — a `Center`, a `Spacer`, an action pinned to the
      // bottom — would silently move up the screen on every device, not only on
      // the short ones.
      await pump(
        tester,
        const MxContentShell(
          isScrollable: true,
          body: Center(child: Text('centred')),
        ),
      );

      final height = tester.getSize(find.text('centred')).height;
      final centre = tester.getCenter(find.text('centred'));

      expect(height, greaterThan(0));
      // Vertically centred in the 852-tall viewport, not parked at the top.
      expect(centre.dy, greaterThan(portrait.height / 3));
    });

    testWidgets('a scrollable body scrolls once it stops fitting', (
      tester,
    ) async {
      await pump(
        tester,
        cardEditor(isScrollable: true),
        surface: landscape,
        textScale: 2,
      );

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;

      expect(position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('a body that already fits does not gain a scroll offset', (
      tester,
    ) async {
      // Padding is subtracted from `minHeight`; without that every screen would
      // scroll by exactly the padding height and feel loose.
      await pump(
        tester,
        const MxContentShell(isScrollable: true, body: SizedBox.shrink()),
      );

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;

      expect(position.maxScrollExtent, 0);
    });
  });

  group('components that already carry their own scrolling', () {
    const empty = MxEmptyState(
      title: 'Nothing due today',
      message: 'You have finished every card scheduled for now.',
      actionLabel: 'Browse decks',
      onAction: _noop,
    );
    const error = MxErrorState(
      title: 'Something went wrong',
      message: 'This part could not be displayed.',
      retryLabel: 'Try again',
      onRetry: _noop,
    );
    const dialog = MxConfirmDialog(
      title: 'Delete this deck?',
      message: 'This removes 4 sub-decks and 11 cards. It cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: MxConfirmDialogVariant.destructive,
      onConfirm: _noop,
      onCancel: _noop,
    );
    final sheet = Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: MxActionSheet(
          title: 'Add to this deck',
          actions: <MxActionSheetAction>[
            for (var i = 0; i < 6; i++)
              MxActionSheetAction(label: 'Action $i', onPressed: _noop),
          ],
        ),
      ),
    );

    final cases = <String, Widget>{
      'MxEmptyState': const Scaffold(body: empty),
      'MxErrorState': const Scaffold(body: error),
      'MxConfirmDialog': const Scaffold(body: Center(child: dialog)),
      'MxActionSheet': sheet,
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} survives landscape at textScaler 2', (
        tester,
      ) async {
        await pump(tester, entry.value, surface: landscape, textScale: 2);

        expect(tester.takeException(), isNull);
      });

      testWidgets('${entry.key} survives the keyboard in portrait', (
        tester,
      ) async {
        await pump(tester, entry.value, viewInsets: portraitKeyboard);

        expect(tester.takeException(), isNull);
      });
    }
  });
}

void _noop() {}
