import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_export_result_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_export_action_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_export_error_band_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_export_format_options_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/card_export_sheet_harness.dart';

/// Every state the export sheet can be in (UC-11 A3-A5, E1-E6; M4.13 W3).
///
/// The companion of `card_export_sheet_test.dart`, split at the 400-line
/// guard: that file proves what the sheet shows, this one proves what it does.
void main() {
  final h = installCardExportSheetHarness();
  final AppLocalizationsEn english = h.english;

  Finder primary(String label) => find.widgetWithText(FilledButton, label);

  group('counts read as sentences', () {
    testWidgets('one card is singular everywhere it is counted', (
      tester,
    ) async {
      // "Export 1 cards" and "All 1 cards in this deck" were what a deck of one
      // said, and selecting a single card then exporting it is an ordinary
      // thing to do rather than an edge case. The repo already plurals fifteen
      // other counts; these three had been written as bare placeholders.
      h.seed(cardCount: 1);
      await h.pump(tester);
      await h.openWholeDeckExport(tester);

      expect(find.text('All 1 card in this deck'), findsOneWidget);
      expect(primary('Export 1 card'), findsOneWidget);
      expect(english.cardExportScopeSelectedLabel(1), '1 selected card');
    });

    testWidgets('more than one stays plural', (tester) async {
      h.seed();
      await h.pump(tester);
      await h.openWholeDeckExport(tester);

      expect(find.text('All 3 cards in this deck'), findsOneWidget);
      expect(primary('Export 3 cards'), findsOneWidget);
      expect(english.cardExportScopeSelectedLabel(3), '3 selected cards');
    });
  });

  group('submitting (UC-11 steps 4-7, A4)', () {
    testWidgets('the primary runs exactly one export', (tester) async {
      await h.pump(tester);
      await h.openWholeDeckExport(tester);
      await tester.tap(primary(english.cardExportSubmitAction(3)));
      await tester.pumpAndSettle();

      expect(h.exports.readCalls, 1);
      expect(h.destination.shareCalls, 1);
    });

    testWidgets('a second press while generating does nothing (A4)', (
      tester,
    ) async {
      final gate = Completer<void>();
      h.destination.shareGate = gate;
      await h.pump(tester);
      await h.openWholeDeckExport(tester);

      await tester.tap(primary(english.cardExportSubmitAction(3)));
      await tester.pump();

      // The action row is replaced in place: the primary now says Exporting…
      expect(primary(english.cardExportSubmittingLabel), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The body did not move — scope and format are still readable (E7).
      expect(find.text(english.cardExportScopeAllLabel(3)), findsOneWidget);

      await tester.tap(primary(english.cardExportSubmittingLabel));
      await tester.pump();
      gate.complete();
      await tester.pumpAndSettle();

      expect(h.destination.shareCalls, 1, reason: 'one artifact per press');
    });

    testWidgets('Exporting… is painted, not merely laid out (W6)', (
      tester,
    ) async {
      // **The label was in the semantics tree and nowhere on the screen.**
      // `MxActionButton`'s default keeps the button's width by putting the
      // label at `Opacity(0)` and letting `alwaysIncludeSemantics` carry it,
      // which answers a screen reader and answers nobody else — W6 and this
      // string's own ARB description both ask for real text. `findsOneWidget`
      // cannot see the difference, because an invisible widget is still found.
      final gate = Completer<void>();
      h.destination.shareGate = gate;
      await h.pump(tester);
      await h.openWholeDeckExport(tester);
      await tester.tap(primary(english.cardExportSubmitAction(3)));
      await tester.pump();

      final label = find.text(english.cardExportSubmittingLabel);
      expect(label, findsOneWidget);
      expect(
        tester
            .widgetList<Opacity>(
              find.ancestor(of: label, matching: find.byType(Opacity)),
            )
            .map((opacity) => opacity.opacity),
        everyElement(greaterThan(0)),
        reason: 'a label at alpha 0 is still a mute spinner to the eye',
      );

      gate.complete();
      await tester.pumpAndSettle();
    });

    for (final viewport in <({Size size, double scale, String name})>[
      (size: const Size(393, 852), scale: 1, name: '393dp at 1.0x'),
      (size: const Size(320, 852), scale: 2, name: '320dp at 2.0x'),
    ]) {
      testWidgets('E7 in ${viewport.name}: the action panel is replaced in '
          'place', (tester) async {
        // **The case E7 was written for, and the only one it still covers.**
        // E7a narrowed the rule to the action panel precisely because W3
        // states 5–7 require a band to appear inside the sheet, which cannot
        // happen at a fixed height.
        //
        // **The panel, not the sheet, and both viewports.** Measuring the
        // sheet is vacuous wherever the sheet already fills the screen —
        // `Flexible` absorbs a taller action row by shrinking the scroll view,
        // so the outer rect is constant no matter what the row does. This was
        // written the wrong way first and proved nothing: a generating label
        // long enough to wrap still passed. The panel's own rect is what E7
        // constrains and what a wrapped label moves.
        final gate = Completer<void>();
        h.destination.shareGate = gate;
        await h.pump(tester, surface: viewport.size, textScale: viewport.scale);
        await h.openWholeDeckExport(tester);

        final before = tester.getRect(find.byType(CardExportActionBarWidget));
        await tester.tap(primary(english.cardExportSubmitAction(3)));
        await tester.pump();
        final during = tester.getRect(find.byType(CardExportActionBarWidget));

        expect(
          during.height,
          moreOrLessEquals(before.height, epsilon: 0.5),
          reason: 'the panel changed height, so everything above it moved',
        );
        expect(
          during.top,
          moreOrLessEquals(before.top, epsilon: 0.5),
          reason: 'the panel moved under the finger that just pressed it',
        );

        gate.complete();
        await tester.pumpAndSettle();
      });
    }

    testWidgets('Cancel while generating hands nothing over (W4)', (
      tester,
    ) async {
      // W4: `Cancel` stays live while an export runs and closes the sheet
      // "without creating a file". It used to close the sheet only — the read,
      // the encode and the hand-off carried on, so the OS share sheet appeared
      // for a user who had already said no, and because the export sheet was
      // gone by then nothing confirmed or denied where the file went.
      final gate = Completer<void>();
      h.exports.readGate = gate;
      await h.pump(tester);
      await h.openWholeDeckExport(tester);

      await tester.tap(primary(english.cardExportSubmitAction(3)));
      await tester.pump();
      expect(primary(english.cardExportSubmittingLabel), findsOneWidget);

      await tester.tap(find.text(english.commonCancelAction).last);
      await tester.pumpAndSettle();
      gate.complete();
      await tester.pumpAndSettle();

      expect(h.destination.shareCalls, 0, reason: 'no file may be handed over');
      expect(find.text(english.cardExportSharedMessage), findsNothing);
    });

    testWidgets('Back cancels on the pop frame, before disposal could', (
      tester,
    ) async {
      // The narrow window the `PopScope` exists to close: the export finishes
      // reading and encoding *while the sheet is popping*. Relying on the
      // provider's disposal alone loses this race for a small deck, and the
      // file goes to the OS after the user backed out.
      final gate = Completer<void>();
      h.exports.readGate = gate;
      await h.pump(tester);
      await h.openWholeDeckExport(tester);

      await tester.tap(primary(english.cardExportSubmitAction(3)));
      await tester.pump();

      // One frame only: the pop has been invoked, the provider has not been
      // disposed yet. Completing here is the race, run deliberately.
      await tester.binding.handlePopRoute();
      gate.complete();
      await tester.pumpAndSettle();

      expect(
        h.destination.shareCalls,
        0,
        reason: 'the cancel must land on the pop frame, not on disposal',
      );
    });

    testWidgets('Android Back while generating hands nothing over (W4)', (
      tester,
    ) async {
      // Back reaches `cancel()` through the sheet's `PopScope`, on the frame
      // the pop starts. Disposal would cancel too, but only on whichever
      // frame Riverpod gets to it — which for a small deck can be after the
      // hand-off already happened, so the pop callback is what makes the
      // promise deterministic rather than probable (M4.13 W4).
      final gate = Completer<void>();
      h.exports.readGate = gate;
      await h.pump(tester);
      await h.openWholeDeckExport(tester);

      await tester.tap(primary(english.cardExportSubmitAction(3)));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      gate.complete();
      await tester.pumpAndSettle();

      expect(h.destination.shareCalls, 0, reason: 'no file may be handed over');
      expect(find.text(english.cardExportSharedMessage), findsNothing);
    });

    testWidgets('a shared result closes the sheet and confirms without '
        'claiming a save (BR-181, E9)', (tester) async {
      await h.pump(tester);
      await h.openWholeDeckExport(tester);
      await tester.tap(primary(english.cardExportSubmitAction(3)));
      await tester.pumpAndSettle();

      expect(find.text(english.cardExportFormatHeading), findsNothing);
      expect(find.text(english.cardExportSharedMessage), findsOneWidget);
    });

    testWidgets('a dismissed share sheet is a cancel: back to initial, no '
        'error, format kept (BR-181, E5)', (tester) async {
      h.destination.resultToReturn = CardExportResult.dismissed;
      await h.pump(tester);
      await h.openWholeDeckExport(tester);
      await tester.tap(
        find.text(CardTransferFormat.xlsx.fileExtension.toUpperCase()),
      );
      await tester.pumpAndSettle();
      await tester.tap(primary(english.cardExportSubmitAction(3)));
      await tester.pumpAndSettle();

      expect(find.byType(CardExportErrorBandWidget), findsNothing);
      expect(find.text(english.cardExportSharedMessage), findsNothing);
      expect(primary(english.cardExportSubmitAction(3)), findsOneWidget);
      expect(
        tester
            .widget<CardExportFormatOptionsWidget>(
              find.byType(CardExportFormatOptionsWidget),
            )
            .selected,
        CardTransferFormat.xlsx,
      );
    });

    testWidgets('Cancel closes without exporting and without a message', (
      tester,
    ) async {
      await h.pump(tester);
      await h.openWholeDeckExport(tester);
      await tester.tap(find.text(english.commonCancelAction));
      await tester.pumpAndSettle();

      expect(find.text(english.cardExportFormatHeading), findsNothing);
      expect(h.exports.readCalls, 0);
      expect(find.text(english.cardExportSharedMessage), findsNothing);
    });
  });

  group('locales and themes', () {
    testWidgets('the sheet reads Vietnamese', (tester) async {
      await h.pump(tester, locale: const Locale('vi'));
      await h.openWholeDeckExport(tester, l10n: h.vietnamese);

      expect(
        find.text(h.vietnamese.cardExportScopeAllLabel(3)),
        findsOneWidget,
      );
      expect(
        find.text(h.vietnamese.cardExportRecommendedBadge),
        findsOneWidget,
      );
      expect(find.text(h.vietnamese.cardExportSubmitAction(3)), findsOneWidget);
    });

    testWidgets('the sheet renders in dark without overflowing', (
      tester,
    ) async {
      await h.pump(tester, brightness: Brightness.dark);
      await h.openWholeDeckExport(tester);

      expect(find.text(english.cardExportFormatHeading), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
