import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_import_preview_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_document_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_source_model.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/card_import_wizard_harness.dart';

/// The wizard's presentation state matrix (wireframe M4.12 states 1–8): the
/// upload summary, the parsing face, the stepper's earned checks, and the
/// four outcome faces. Source/preview interactions live in
/// `card_import_wizard_test.dart`, the commit lock and reset in
/// `card_import_commit_flow_test.dart` — the three split at the 400-line
/// guard.
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

  group('parsing (state 2)', () {
    testWidgets('the decode in flight shows the one loading panel and a '
        'compact source line — never the chooser again, and no writes', (
      tester,
    ) async {
      final gate = Completer<void>();
      h.transfer.parseGate = gate;
      await h.pump(tester);
      await tester.tap(find.text(english.cardImportPasteOptionTitle));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'front,back\n사과,apple\n');
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.cardImportPreviewAction));
      await tester.pump();

      // The panel: what is being read, and the no-writes reassurance.
      expect(find.text(english.cardImportParsingPasteTitle), findsOneWidget);
      expect(find.text(english.cardImportParsingReassurance), findsOneWidget);
      // The source is one compact context line, not the chooser repeated —
      // and never the pasted content itself (BR-173).
      expect(find.text(english.cardImportPastedSourceLabel), findsOneWidget);
      // "Parsing…" rides both the status line and the parked primary — the
      // same word on purpose, so the two never disagree.
      expect(find.text(english.cardImportFileParsingStatus), findsNWidgets(2));
      expect(find.text(english.cardImportChoosePrompt), findsNothing);
      expect(find.text(english.cardImportUploadOptionTitle), findsNothing);
      // The primary is parked under its own label until rows exist.
      expect(
        tester
            .widget<FilledButton>(h.button(english.cardImportParsingAction))
            .onPressed,
        isNull,
      );
      // Reading is not writing (BR-171).
      expect(h.importer.commits, isEmpty);

      gate.complete();
      await tester.pumpAndSettle();

      // Rows arrived: the classification headline replaces the panel with
      // no step change and no layout reset.
      expect(find.text(english.cardImportParsingPasteTitle), findsNothing);
      expect(
        find.text(english.cardImportPreviewReadyOfTotal(1, 1)),
        findsOneWidget,
      );
    });
  });

  group('stepper earns its checks', () {
    Finder stepState(int step, String label, String state) =>
        find.bySemanticsLabel(
          english.cardImportStepStateSemantics(
            english.cardImportStepSemantics(step),
            label,
            state,
          ),
        );

    testWidgets('Source checks once a source exists; Preview only once the '
        'mapping is complete and something is importable', (tester) async {
      await h.pump(tester);
      // Fresh wizard: nothing is completed yet.
      expect(
        stepState(
          1,
          english.cardImportStepSourceLabel,
          english.cardImportStepStateCurrent,
        ),
        findsOneWidget,
      );

      await h.pasteAndPreview(tester, 'front,back\n사과,apple\n');

      // On Preview with mapped, importable rows: both earned their check —
      // completion is a fact about the data, not the position (M4.12).
      expect(
        stepState(
          1,
          english.cardImportStepSourceLabel,
          english.cardImportStepStateCompleted,
        ),
        findsOneWidget,
      );
      expect(
        stepState(
          2,
          english.cardImportStepPreviewLabel,
          english.cardImportStepStateCompleted,
        ),
        findsOneWidget,
      );
      expect(
        stepState(
          3,
          english.cardImportStepImportLabel,
          english.cardImportStepStateUpcoming,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Preview earns no check while nothing is importable', (
      tester,
    ) async {
      await h.pump(tester);
      // Every row invalid: mapped, classified, zero importable.
      await h.pasteAndPreview(tester, 'front,back\n사과,\n배,\n');

      expect(
        stepState(
          2,
          english.cardImportStepPreviewLabel,
          english.cardImportStepStateCurrent,
        ),
        findsOneWidget,
      );
    });
  });

  group('outcome faces (states 6-8)', () {
    Future<void> submitFromPaste(WidgetTester tester, String text) async {
      await h.pasteAndPreview(tester, text);
      await tester.tap(find.text(english.cardImportContinueAction));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
    }

    testWidgets('blank rows alone keep the success face — skipped by design '
        'is not a warning (BR-169)', (tester) async {
      await h.pump(tester);
      await submitFromPaste(tester, 'front,back\n사과,apple\n,\n');

      expect(find.text(english.cardImportSuccessTitle), findsOneWidget);
      expect(find.text(english.cardImportSkipsTitle), findsNothing);
      // The blank row still appears, as a neutral fact.
      expect(find.text(english.cardImportBlankIgnoredRowLabel), findsOneWidget);
    });

    testWidgets('invalid rows make it Imported with skips, with the fix-it '
        'hint', (tester) async {
      await h.pump(tester);
      await submitFromPaste(tester, 'front,back\n사과,apple\n배,\n');

      expect(find.text(english.cardImportSkipsTitle), findsOneWidget);
      expect(find.text(english.cardImportSkipsBody(1)), findsOneWidget);
      expect(
        find.text(english.cardImportInvalidSkippedRowLabel),
        findsOneWidget,
      );
      expect(find.text(english.cardImportFixInvalidHint), findsOneWidget);
    });

    testWidgets('a commit whose recheck skips every row is "No new cards '
        'added" — an outcome, never an error (BR-170)', (tester) async {
      await h.pump(tester);
      await h.pasteAndPreview(tester, 'front,back\n사과,apple\n');
      await tester.tap(find.text(english.cardImportContinueAction));
      await tester.pumpAndSettle();

      // Another writer landed the same card between preview and commit; the
      // in-transaction recheck is the only honest witness.
      h.importer.existingKeys = <CardImportDuplicateKey>{
        cardImportDuplicateKey(frontFolded: '사과', backFolded: 'apple'),
      };
      await tester.tap(find.text(english.cardImportSubmitAction(1)));
      await tester.pumpAndSettle();

      expect(find.text(english.cardImportZeroTitle), findsOneWidget);
      expect(find.text(english.cardImportZeroBody), findsOneWidget);
      expect(find.text(english.cardImportFailureTitle), findsNothing);
      // Success-shaped ways out — not retry.
      expect(find.text(english.cardImportAnotherAction), findsOneWidget);
      expect(find.text(english.cardImportViewCardsAction), findsOneWidget);
    });

    testWidgets('submitting shows exactly one loader and nothing '
        'determinate — the batch is atomic (state 5)', (tester) async {
      final gate = Completer<void>();
      h.importer.commitGate = gate;
      await h.pump(tester);
      await h.pasteAndPreview(tester, 'front,back\n사과,apple\n');
      await tester.tap(find.text(english.cardImportContinueAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.cardImportSubmitAction(1)));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text(english.cardImportSubmittingBody), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Back to preview after a failed commit keeps the whole plan '
        'without re-parsing', (tester) async {
      h.importer.nextCommitFailure = const DatabaseFailure(message: 'disk');
      await h.pump(tester);
      await submitFromPaste(tester, 'front,back\n사과,apple\n배,pear\n');
      expect(find.text(english.cardImportFailureTitle), findsOneWidget);

      final parses = h.transfer.parseCalls;
      await tester.tap(find.text(english.cardImportBackToPreviewAction));
      await tester.pumpAndSettle();

      // The preview is intact — classified rows, mapping, headline — and no
      // second decode ran: the draft never lived in the commit controller.
      expect(find.text(english.cardImportMappingHeading), findsOneWidget);
      expect(
        find.text(english.cardImportPreviewReadyOfTotal(2, 2)),
        findsOneWidget,
      );
      expect(h.transfer.parseCalls, parses);
      expect(h.importer.commits, hasLength(1));
      // Continue is alive again — the plan can go around once more.
      expect(
        tester
            .widget<FilledButton>(h.button(english.cardImportContinueAction))
            .onPressed,
        isNotNull,
      );
    });
  });
}
