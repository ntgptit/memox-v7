import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/domain/models/card_export_scope_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_export_format_options_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_selection_bar_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'support/card_export_sheet_harness.dart';

/// The two entry points and the sheet's anatomy (wireframe M4.13 W1, W2).
///
/// Split from `card_export_states_test.dart` at the 400-line guard, along
/// the same seam the import wizard's two files use: what the sheet *is*
/// here, what it *does* there.
void main() {
  final h = installCardExportSheetHarness();
  final AppLocalizationsEn english = h.english;

  Finder primary(String label) => find.widgetWithText(FilledButton, label);

  group('entry points (M4.13 W1)', () {
    testWidgets('the overflow offers Export cards on a deck that has cards', (
      tester,
    ) async {
      await h.pump(tester);
      await h.openOverflow(tester);

      expect(find.text(english.cardExportEntryAction), findsOneWidget);
      expect(find.text(english.cardImportEntryAction), findsOneWidget);
    });

    testWidgets('an empty deck offers no export anywhere', (tester) async {
      h.seed(cardCount: 0, deckTotal: 0);
      await h.pump(tester);
      await h.openOverflow(tester);

      expect(find.text(english.cardExportEntryAction), findsNothing);
      // Import is still there: a whole file should not have to start from a
      // hand-typed first card. Scoped to the menu, because the empty state
      // below carries the same words as its secondary action.
      expect(
        find.descendant(
          of: find.byType(PopupMenuItem<int>),
          matching: find.text(english.cardImportEntryAction),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the whole-deck entry names the deck total, not the window', (
      tester,
    ) async {
      // Nine cards in the deck, three in the loaded window.
      h.seed(deckTotal: 9);
      await h.pump(tester);
      await h.openWholeDeckExport(tester);

      expect(find.text(english.cardExportScopeAllLabel(9)), findsOneWidget);
      expect(primary(english.cardExportSubmitAction(9)), findsOneWidget);
    });

    testWidgets('the selection entry carries the selected ids and its count', (
      tester,
    ) async {
      await h.pump(tester);
      await h.selectCards(tester);
      await h.openSelectionExport(tester);

      expect(
        find.text(english.cardExportScopeSelectedLabel(2)),
        findsOneWidget,
      );
      await tester.tap(primary(english.cardExportSubmitAction(2)));
      await tester.pumpAndSettle();

      final scope = h.exports.scopes.single;
      expect(scope, isA<CardExportSelectionScope>());
      expect((scope as CardExportSelectionScope).cardIds, <String>{'c0', 'c1'});
    });

    testWidgets('exporting the selection leaves the selection alone (BR-178)', (
      tester,
    ) async {
      await h.pump(tester);
      await h.selectCards(tester);
      await h.openSelectionExport(tester);
      await tester.tap(primary(english.cardExportSubmitAction(2)));
      await tester.pumpAndSettle();

      expect(find.byType(CardSelectionBarWidget), findsOneWidget);
      expect(find.text(english.cardSelectionCountLabel(2)), findsOneWidget);
    });
  });

  group('the sheet (M4.13 W2)', () {
    testWidgets('opens on CSV with every format offered and Recommended '
        'readable', (tester) async {
      await h.pump(tester);
      await h.openWholeDeckExport(tester);

      final options = tester
          .widget<CardExportFormatOptionsWidget>(
            find.byType(CardExportFormatOptionsWidget),
          )
          .selected;
      expect(options, CardTransferFormat.csv);
      expect(find.text(english.cardExportRecommendedBadge), findsOneWidget);
      // Every format the app speaks is renderable: a fourth one added to the
      // enum must not go missing from the sheet.
      for (final format in CardTransferFormat.values) {
        expect(
          find.text(format.fileExtension.toUpperCase()),
          findsOneWidget,
          reason: '${format.name} has no option row',
        );
      }
    });

    testWidgets('says what the file holds and what it does not', (
      tester,
    ) async {
      await h.pump(tester);
      await h.openWholeDeckExport(tester);

      expect(find.text(english.cardExportIncludesLine), findsOneWidget);
      expect(find.text(english.cardExportExcludesLine), findsOneWidget);
    });

    testWidgets('the chosen format reaches the request', (tester) async {
      await h.pump(tester);
      await h.openWholeDeckExport(tester);
      await tester.tap(
        find.text(CardTransferFormat.tsv.fileExtension.toUpperCase()),
      );
      await tester.pumpAndSettle();
      await tester.tap(primary(english.cardExportSubmitAction(3)));
      await tester.pumpAndSettle();

      expect(h.encoders.formats, <CardTransferFormat>[CardTransferFormat.tsv]);
    });

    testWidgets('the format option announces its selected state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await h.pump(tester);
      await h.openWholeDeckExport(tester);

      // One node per option, carrying the words *and* the selected state:
      // colour alone would say nothing here, and a `selected` flag on a node
      // with no label would say nothing either.
      expect(
        tester.getSemantics(
          find.text(CardTransferFormat.csv.fileExtension.toUpperCase()),
        ),
        isSemantics(
          isSelected: true,
          isButton: true,
          hasTapAction: true,
          label:
              'CSV\n${english.cardExportRecommendedBadge}\n'
              '${english.cardExportCsvSubtitle}',
        ),
      );
      expect(
        tester.getSemantics(
          find.text(CardTransferFormat.tsv.fileExtension.toUpperCase()),
        ),
        isSemantics(isSelected: false),
      );
      handle.dispose();
    });

    testWidgets('the selected option wears the app-wide selected mark, in '
        'dark too (W6)', (tester) async {
      // **Measured, not eyeballed.** The border carried `primary`, which is
      // 2.90:1 against `surface` in dark — under WCAG 1.4.11's 3:1 — and only
      // 1.42:1 against the hairline of the two options beside it, so in dark
      // the edge stopped saying which option was picked. `card_tile_widget`
      // already answers "this one is selected" with `secondaryContainer` +
      // `secondary`, which measures 8.77:1 on the same ground; there is no
      // reason for the sheet to hold a second opinion.
      //
      // A token comparison rather than a contrast computation on purpose: the
      // pair's contrast is already asserted in `app_theme_test.dart`, and what
      // can regress here is which token this widget reaches for.
      await h.pump(tester, brightness: Brightness.dark);
      await h.openWholeDeckExport(tester);

      final csv = tester.widget<MxCard>(
        find
            .ancestor(
              of: find.text(CardTransferFormat.csv.fileExtension.toUpperCase()),
              matching: find.byType(MxCard),
            )
            .first,
      );
      // The token itself now lives in [MxCard.isSelected] and is pinned by
      // mx_card_test; what can regress *here* is whether this widget still
      // hands the state to the card instead of spelling a colour again.
      expect(csv.isSelected, isTrue);

      // The resting option is the same case `borderControl` was written for:
      // its fill *is* the sheet's, so the edge is the whole component. The
      // option recipe owns that edge now, so the claim reads the rendered
      // border — the observable outcome — rather than a parameter the closed
      // API no longer has.
      final tsvFinder = find
          .ancestor(
            of: find.text(CardTransferFormat.tsv.fileExtension.toUpperCase()),
            matching: find.byType(MxCard),
          )
          .first;
      final tsv = tester.widget<MxCard>(tsvFinder);
      expect(tsv.isSelected, isFalse);
      final tsvBox = tester.widget<DecoratedBox>(
        find
            .descendant(of: tsvFinder, matching: find.byType(DecoratedBox))
            .first,
      );
      final tsvBorder =
          ((tsvBox.decoration as BoxDecoration).border! as Border).top;
      expect(
        tsvBorder.color,
        buildDarkTheme().extension<AppSemanticColors>()!.borderControl,
      );
    });

    testWidgets('the icon-only entry controls carry labels', (tester) async {
      await h.pump(tester);

      // The menu is an MxMenuButton now; the named-anchor claim is the same.
      expect(find.byTooltip(english.cardSelectionMoreLabel), findsOneWidget);
    });
  });
}
