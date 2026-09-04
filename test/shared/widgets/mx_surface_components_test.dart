import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_action_sheet.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';

/// `MxConfirmDialog` and `MxActionSheet`.
///
/// `MxCard` moved to `mx_card_test.dart`, and `MxListTile` to
/// `mx_list_tile_test.dart`, each time this file crossed the 400-line guard.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool isDark = false,
    Size surface = const Size(360, 640),
    double textScale = 1,
    bool settle = true,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
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
            child: Scaffold(body: child),
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

  group('MxConfirmDialog', () {
    MxConfirmDialog build({
      MxConfirmDialogVariant variant = MxConfirmDialogVariant.normal,
      bool isSubmitting = false,
      VoidCallback? onConfirm,
      VoidCallback? onCancel,
    }) => MxConfirmDialog(
      title: 'Delete this deck?',
      // The count comes from the feature, already localized and pluralised.
      message: 'This removes 4 sub-decks and 11 cards.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: variant,
      isSubmitting: isSubmitting,
      onConfirm: onConfirm ?? () {},
      onCancel: onCancel ?? () {},
    );

    testWidgets('renders title, message and both actions', (tester) async {
      await pump(tester, build());

      expect(find.text('Delete this deck?'), findsOneWidget);
      expect(
        find.text('This removes 4 sub-decks and 11 cards.'),
        findsOneWidget,
      );
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('confirm and cancel each fire their own callback', (
      tester,
    ) async {
      var confirmed = 0;
      var cancelled = 0;

      await pump(
        tester,
        build(onConfirm: () => confirmed++, onCancel: () => cancelled++),
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(cancelled, 1);
      expect(confirmed, 1);
    });

    testWidgets('destructive does not take initial focus', (tester) async {
      // A stray Enter on a delete dialog must not delete anything.
      //
      // **Only where an Enter is possible.** `MxActionButton` drops the
      // autofocus under `FocusHighlightMode.touch`, because a focused outlined
      // button wears the focus ring instead of its border and a phone has no
      // reason to be shown one. A widget test starts in touch mode, so the
      // keyboard has to be declared for the property to exist at all.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
      });

      await pump(tester, build(variant: MxConfirmDialogVariant.destructive));

      final confirm = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Delete'),
          matching: find.byType(FilledButton),
        ),
      );
      final cancel = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Cancel'),
          matching: find.byType(OutlinedButton),
        ),
      );

      expect(confirm.autofocus, isFalse);
      expect(cancel.autofocus, isTrue);
    });

    testWidgets('normal variant autofocuses neither action', (tester) async {
      // Pre-selecting confirm makes the keyboard path skip the question the
      // dialog exists to ask.
      await pump(tester, build());

      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text('Delete'),
                matching: find.byType(FilledButton),
              ),
            )
            .autofocus,
        isFalse,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.ancestor(
                of: find.text('Cancel'),
                matching: find.byType(OutlinedButton),
              ),
            )
            .autofocus,
        isFalse,
      );
    });

    testWidgets('submitting blocks a second confirm', (tester) async {
      var confirmed = 0;

      // `pump`, never `pumpAndSettle`: while submitting the confirm button
      // shows a spinner, and a `CircularProgressIndicator` animates forever —
      // `pumpAndSettle` waits for a frame that never comes and times out after
      // ten minutes.
      await pump(
        tester,
        build(isSubmitting: true, onConfirm: () => confirmed++),
        settle: false,
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(confirmed, 0);
    });

    testWidgets('actions stack instead of overflowing on a narrow screen', (
      tester,
    ) async {
      await pump(
        tester,
        build(variant: MxConfirmDialogVariant.destructive),
        surface: const Size(320, 568),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark', (tester) async {
      await pump(
        tester,
        build(variant: MxConfirmDialogVariant.destructive),
        isDark: true,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('MxActionSheet', () {
    testWidgets('renders the title and every action', (tester) async {
      await pump(
        tester,
        MxActionSheet(
          title: 'Add to this deck',
          actions: <MxActionSheetAction>[
            MxActionSheetAction(label: 'Create card', onPressed: () {}),
            MxActionSheetAction(label: 'Create deck', onPressed: () {}),
          ],
        ),
      );

      expect(find.text('Add to this deck'), findsOneWidget);
      expect(find.text('Create card'), findsOneWidget);
      expect(find.text('Create deck'), findsOneWidget);
    });

    testWidgets('the tapped action is the one that fires', (tester) async {
      final fired = <String>[];

      await pump(
        tester,
        MxActionSheet(
          actions: <MxActionSheetAction>[
            MxActionSheetAction(
              label: 'Rename',
              onPressed: () => fired.add('rename'),
            ),
            MxActionSheetAction(
              label: 'Delete',
              variant: MxActionSheetActionVariant.destructive,
              onPressed: () => fired.add('delete'),
            ),
          ],
        ),
      );
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(fired, <String>['delete']);
    });

    testWidgets('a long list scrolls instead of overflowing', (tester) async {
      await pump(
        tester,
        MxActionSheet(
          title: 'Actions',
          actions: <MxActionSheetAction>[
            for (var i = 0; i < 12; i++)
              MxActionSheetAction(label: 'Action $i', onPressed: () {}),
          ],
        ),
        surface: const Size(320, 568),
        textScale: 2,
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sits inside a SafeArea', (tester) async {
      // A sheet is anchored where the home indicator and the keyboard are.
      await pump(
        tester,
        MxActionSheet(
          actions: <MxActionSheetAction>[
            MxActionSheetAction(label: 'Rename', onPressed: () {}),
          ],
        ),
      );

      // The claim is that the ACTIONS sit inside a SafeArea, not that exactly
      // one SafeArea exists — Material inserts its own around sheet content.
      expect(
        find.ancestor(
          of: find.text('Rename'),
          matching: find.descendant(
            of: find.byType(MxActionSheet),
            matching: find.byType(SafeArea),
          ),
        ),
        findsWidgets,
      );
    });

    testWidgets('renders in dark', (tester) async {
      await pump(
        tester,
        MxActionSheet(
          title: 'Actions',
          actions: <MxActionSheetAction>[
            MxActionSheetAction(
              label: 'Delete',
              variant: MxActionSheetActionVariant.destructive,
              onPressed: () {},
            ),
          ],
        ),
        isDark: true,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
