import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import '../../support/ink_probe.dart';

/// What a screen reader and a keyboard actually get.
///
/// These assert the semantics tree and the scroll extent rather than the
/// painted frame, because every defect they cover was invisible to a passing
/// widget test: text that clips instead of throwing, and a label that vanishes
/// from the semantics tree while the pixels stay exactly where they were.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size surface = const Size(360, 640),
    double textScale = 1,
    bool settle = true,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Builder(
          // `copyWith`, never a fresh `MediaQueryData`: constructing one
          // zeroes `size`, `padding` and `viewInsets`, so the widget under
          // test is told the screen is 0x0 while `tester.view` says
          // otherwise. Anything that reads the width then branches on a
          // number no device reports.
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
      return;
    }
    await tester.pump();
  }

  group('MxActionButton while submitting', () {
    testWidgets('keeps its accessible name', (tester) async {
      // `Opacity` drops its subtree from the semantics tree at alpha 0, so the
      // label that is merely invisible on screen was also gone from the tree:
      // the button announced as "button, disabled" and named nothing. Nothing
      // about the frame changes when this breaks.
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxActionButton(label: 'Delete deck', onPressed: () {}, isLoading: true),
        settle: false,
      );

      expect(
        tester.getSemantics(find.byType(FilledButton)).label,
        'Delete deck',
      );
      handle.dispose();
    });

    testWidgets('is announced as busy', (tester) async {
      // The role comes from the spinner on the same node. It carries the busy
      // state without a string, which matters because no ARB file owns one.
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxActionButton(label: 'Delete deck', onPressed: () {}, isLoading: true),
        settle: false,
      );

      expect(
        tester.getSemantics(find.byType(FilledButton)).role,
        SemanticsRole.loadingSpinner,
      );
      handle.dispose();
    });
  });

  group('MxIconButton', () {
    testWidgets('produces exactly one labelled node', (tester) async {
      // Both `IconButton.tooltip` and `Icon.semanticLabel` carry the string, and
      // the worry is that a reader announces it twice. They merge into one
      // node — this pins that, so a future change that splits them fails here
      // rather than in someone's ears.
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxIconButton(
          icon: Icons.delete_outline,
          semanticLabel: 'Delete deck',
          onPressed: () {},
        ),
      );

      expect(find.bySemanticsLabel('Delete deck'), findsOneWidget);

      final node = tester.getSemantics(find.byType(IconButton));

      expect(node.label, 'Delete deck');
      expect(node.tooltip, 'Delete deck');
      handle.dispose();
    });

    testWidgets('keeps its 48x48 through the interaction states', (
      tester,
    ) async {
      // The state layers landed on this button in the same change that gave it
      // an overlay and a ring, and a ring that grew the box would take the
      // touch target with it. Measured hovered and focused as well as at rest,
      // because a target that only holds at rest is not a target.
      await pump(
        tester,
        MxIconButton(
          icon: Icons.delete_outline,
          semanticLabel: 'Delete deck',
          onPressed: () {},
        ),
      );
      final atRest = tester.getSize(find.byType(IconButton));
      expect(atRest.width, greaterThanOrEqualTo(48));
      expect(atRest.height, greaterThanOrEqualTo(48));

      await hover(tester, find.byType(IconButton));
      expect(tester.getSize(find.byType(IconButton)), atRest);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(IconButton)),
        atRest,
        reason: 'the focus ring changed the touch target',
      );
    });
  });

  group('MxConfirmDialog at large text', () {
    const message =
        'Dies entfernt 4 Unterstapel und 11 Karten dauerhaft von diesem Gerat. '
        'Diese Aktion kann nicht rueckgaengig gemacht werden, und der '
        'Lernfortschritt geht ebenfalls verloren.';

    Widget build() => const MxConfirmDialog(
      title: 'Delete this deck?',
      message: message,
      confirmLabel: 'Endgueltig loeschen',
      cancelLabel: 'Abbrechen',
      variant: MxConfirmDialogVariant.destructive,
      onConfirm: _noop,
      onCancel: _noop,
    );

    testWidgets('the message stays reachable rather than clipping', (
      tester,
    ) async {
      // The bug this replaces threw nothing and rendered a frame: the sentence
      // was cut mid-word and the user confirmed a delete having read half of
      // the description. `takeException()` was null throughout.
      await pump(tester, build(), surface: const Size(320, 568), textScale: 3);

      final scrollable = find.descendant(
        of: find.byType(MxConfirmDialog),
        matching: find.byType(Scrollable),
      );

      expect(scrollable, findsOneWidget);
      expect(
        tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
        greaterThan(0),
      );
    });

    testWidgets('both action labels survive the scale', (tester) async {
      // One line ellipsized "Endgueltig loeschen" to "End…", which on a
      // destructive dialog leaves nothing to tell the two buttons apart.
      await pump(tester, build(), surface: const Size(320, 568), textScale: 3);

      for (final label in <String>['Abbrechen', 'Endgueltig loeschen']) {
        final text = tester.widget<Text>(find.text(label));

        expect(text.maxLines, 2, reason: label);
      }
    });
  });
}

void _noop() {}
