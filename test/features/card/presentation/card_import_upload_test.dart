import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_transfer_document_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_source_model.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/card_import_wizard_harness.dart';

/// The upload half of the Source step (M4.12 state 1) and the XLSX sheet
/// choice: the compact file summary, Replace/Remove, a cancelled pick, and
/// re-previewing on a sheet change. Split from
/// `card_import_states_test.dart` at the 400-line guard.
void main() {
  final h = installCardImportWizardHarness();
  final AppLocalizationsEn english = h.english;

  group('upload and sheets', () {
    testWidgets('a picked file shows its name, extension and size', (
      tester,
    ) async {
      // §18: filename, extension, size and Replace — the name alone does not
      // say how big the batch is about to be.
      h.picker.fileToPick = CardTransferFileSource(
        name: 'words.csv',
        bytes: Uint8List.fromList(utf8.encode('front,back\n사과,apple')),
        format: CardTransferFormat.csv,
      );
      await h.pump(tester);
      await tester.tap(find.text(english.cardImportChooseFileAction));
      await tester.pumpAndSettle();

      expect(find.text('words.csv'), findsOneWidget);
      // Meta and readiness in one status line (state 1)…
      expect(
        find.text(
          english.cardImportSourceStatusLine(
            english.cardImportFileMetaLabel(
              'CSV',
              english.cardImportFileSizeKilobytes(1),
            ),
            english.cardImportFileReadyStatus,
          ),
        ),
        findsOneWidget,
      );
      // …with Replace as the card's tap and Remove as the trailing X.
      expect(
        find.bySemanticsLabel(english.cardImportReplaceFileAction),
        findsOneWidget,
      );
      expect(find.byTooltip(english.cardImportRemoveFileLabel), findsOneWidget);
    });

    testWidgets('a cancelled replace keeps the previously picked file', (
      tester,
    ) async {
      h.picker.fileToPick = CardTransferFileSource(
        name: 'words.csv',
        bytes: Uint8List.fromList(utf8.encode('front,back\n사과,apple')),
        format: CardTransferFormat.csv,
      );
      await h.pump(tester);
      await tester.tap(find.text(english.cardImportChooseFileAction));
      await tester.pumpAndSettle();
      expect(find.text('words.csv'), findsOneWidget);

      // The next picker run is dismissed. Cancel is "never mind", not a
      // decision about the draft (UC-10 A5) — the working file survives.
      h.picker.fileToPick = null;
      await tester.tap(
        find.bySemanticsLabel(english.cardImportReplaceFileAction),
      );
      await tester.pumpAndSettle();

      expect(h.picker.pickCalls, 2);
      expect(find.text('words.csv'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('removing the picked file returns to the empty chooser', (
      tester,
    ) async {
      h.picker.fileToPick = CardTransferFileSource(
        name: 'words.csv',
        bytes: Uint8List.fromList(utf8.encode('front,back\n사과,apple')),
        format: CardTransferFormat.csv,
      );
      await h.pump(tester);
      await tester.tap(find.text(english.cardImportChooseFileAction));
      await tester.pumpAndSettle();
      expect(find.text('words.csv'), findsOneWidget);

      await tester.tap(find.byTooltip(english.cardImportRemoveFileLabel));
      await tester.pumpAndSettle();

      // The chooser is back, the file is gone, and the primary is disabled
      // again — the X is a real draft mutation, not a visual dismiss.
      expect(find.text('words.csv'), findsNothing);
      expect(find.text(english.cardImportChoosePrompt), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(h.button(english.cardImportPreviewAction))
            .onPressed,
        isNull,
      );
    });

    testWidgets('a multi-sheet workbook offers the sheet choice, defaults to '
        'the first non-empty one, and re-previews on change', (tester) async {
      CardTransferRow row(int number, List<String> cells) =>
          CardTransferRow(sourceRowNumber: number, cells: cells);
      h.transfer.documentToReturn = CardTransferDocument(
        sheets: <CardTransferSheet>[
          CardTransferSheet(
            name: 'Empty',
            rows: <CardTransferRow>[
              row(1, <String>['', '']),
            ],
          ),
          CardTransferSheet(
            name: 'Nouns',
            rows: <CardTransferRow>[
              row(1, <String>['front', 'back']),
              row(2, <String>['사과', 'apple']),
            ],
          ),
          CardTransferSheet(
            name: 'Verbs',
            rows: <CardTransferRow>[
              row(1, <String>['front', 'back']),
              row(2, <String>['가다', 'to go']),
              row(3, <String>['보다', 'to see']),
            ],
          ),
        ],
      );
      h.picker.fileToPick = CardTransferFileSource(
        name: 'words.xlsx',
        bytes: Uint8List.fromList(const <int>[0]),
        format: CardTransferFormat.xlsx,
      );
      await h.pump(tester);
      await tester.tap(find.text(english.cardImportChooseFileAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.cardImportPreviewAction));
      await tester.pumpAndSettle();

      // The default is the first non-empty sheet (UC-10 A2), and the empty
      // one is not offered at all.
      expect(find.text(english.cardImportSheetLabel), findsOneWidget);
      expect(find.text('Nouns'), findsOneWidget);
      expect(find.text('Empty'), findsNothing);
      expect(
        find.text(
          english.cardImportStatusCountChip(
            english.cardImportRowStatusReadyLabel,
            1,
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Nouns'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verbs').last);
      await tester.pumpAndSettle();

      // The other sheet's rows, re-classified under its own header row.
      expect(
        find.text(
          english.cardImportStatusCountChip(
            english.cardImportRowStatusReadyLabel,
            2,
          ),
        ),
        findsOneWidget,
      );
    });
  });
}
