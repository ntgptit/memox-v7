import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/card_transfer_failure.dart';
import 'package:memox/features/card/domain/models/card_import_preview_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_document_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_source_model.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/card_import_wizard_harness.dart';

/// The wizard's source and preview steps (UC-10 steps 2–5): which actions are
/// reachable when, and what survives an error. The commit side lives in
/// `card_import_commit_flow_test.dart`; the two split at the 400-line guard.
void main() {
  final h = installCardImportWizardHarness();
  final AppLocalizationsEn english = h.english;

  group('source step', () {
    testWidgets('opens on upload with the primary action disabled', (
      tester,
    ) async {
      await h.pump(tester);

      expect(find.text(english.cardImportChoosePrompt), findsOneWidget);
      final action = tester.widget<FilledButton>(
        h.button(english.cardImportPreviewAction),
      );
      expect(action.onPressed, isNull);
      // The deck context chip names the target and its count.
      expect(
        find.text(english.cardImportDeckContextLabel('TOPIK I', 1)),
        findsOneWidget,
      );
    });

    testWidgets('a cancelled pick is not an error and keeps the step', (
      tester,
    ) async {
      await h.pump(tester);

      await tester.tap(find.text(english.cardImportChooseFileAction));
      await tester.pumpAndSettle();

      expect(h.picker.pickCalls, 1);
      expect(find.text(english.cardImportChoosePrompt), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('an unsupported file shows its typed reason and keeps the '
        'previous file', (tester) async {
      h.picker.fileToPick = CardTransferFileSource(
        name: 'words.csv',
        bytes: Uint8List.fromList(utf8.encode('front,back\n사과,apple')),
        format: CardTransferFormat.csv,
      );
      await h.pump(tester);
      await tester.tap(find.text(english.cardImportChooseFileAction));
      await tester.pumpAndSettle();
      expect(find.text('words.csv'), findsOneWidget);

      h.picker.nextPickFailure = const ValidationFailure(
        message: 'unsupported',
        problems: <Enum>{CardTransferProblem.unsupportedFile},
      );
      await tester.tap(find.text(english.cardImportReplaceFileAction));
      await tester.pumpAndSettle();

      expect(find.text(english.cardImportErrorUnsupportedFile), findsOneWidget);
      expect(find.text('words.csv'), findsOneWidget);
    });

    testWidgets('a failed file read shows the typed recovery copy and keeps '
        'the previous file (H)', (tester) async {
      h.picker.fileToPick = CardTransferFileSource(
        name: 'words.csv',
        bytes: Uint8List.fromList(utf8.encode('front,back')),
        format: CardTransferFormat.csv,
      );
      await h.pump(tester);
      await tester.tap(find.text(english.cardImportChooseFileAction));
      await tester.pumpAndSettle();

      // The next replace dies in the platform layer; the repository has
      // already mapped it to unreadableFile before the controller sees it.
      h.picker.nextPickFailure = const ValidationFailure(
        message: 'read failed',
        problems: <Enum>{CardTransferProblem.unreadableFile},
      );
      await tester.tap(find.text(english.cardImportReplaceFileAction));
      await tester.pumpAndSettle();

      expect(find.text(english.cardImportErrorUnreadableFile), findsOneWidget);
      expect(find.text('words.csv'), findsOneWidget);
    });

    testWidgets('typing into the paste box enables Preview without parsing', (
      tester,
    ) async {
      await h.pump(tester);
      await tester.tap(find.text(english.cardImportPasteOptionTitle));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'front,back\n사과,apple');
      await tester.pumpAndSettle();

      final action = tester.widget<FilledButton>(
        h.button(english.cardImportPreviewAction),
      );
      expect(action.onPressed, isNotNull);
    });
  });

  group('compact width and large type (I)', () {
    const compact = Size(320, 852);

    Finder stepSemantics(int step, String label) => find.bySemanticsLabel(
      english.cardImportStepNamedSemantics(
        english.cardImportStepSemantics(step),
        label,
      ),
    );

    testWidgets('the source step renders at 320dp and 2.0x with every step '
        'still announced', (tester) async {
      await h.pump(tester, surface: compact, textScale: 2);

      expect(tester.takeException(), isNull);
      // The compact stepper keeps all three steps in semantics and the
      // current one's full label on screen — never an ellipsis stump.
      expect(
        stepSemantics(1, english.cardImportStepSourceLabel),
        findsOneWidget,
      );
      expect(
        stepSemantics(2, english.cardImportStepPreviewLabel),
        findsOneWidget,
      );
      expect(
        stepSemantics(3, english.cardImportStepImportLabel),
        findsOneWidget,
      );
      expect(find.text(english.cardImportStepSourceLabel), findsOneWidget);
    });

    testWidgets('preview, confirm and result survive 320dp at 2.0x', (
      tester,
    ) async {
      await h.pump(tester, surface: compact, textScale: 2);
      await h.pasteAndPreview(tester, 'front,back\n\uc0ac\uacfc,apple\n');
      expect(tester.takeException(), isNull);
      expect(find.text(english.cardImportStepPreviewLabel), findsOneWidget);

      await tester.ensureVisible(find.text(english.cardImportContinueAction));
      await tester.tap(find.text(english.cardImportContinueAction));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(english.cardImportSubmitAction(1)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(english.cardImportResultHeading), findsOneWidget);
    });

    testWidgets('Vietnamese labels make the same honest layout choice', (
      tester,
    ) async {
      await h.pump(
        tester,
        surface: compact,
        textScale: 2,
        locale: const Locale('vi'),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('preview step', () {
    testWidgets('an auto-mapped paste classifies rows and enables Continue', (
      tester,
    ) async {
      await h.pump(tester);
      await h.pasteAndPreview(tester, 'front,back\n사과,apple\n배,\n');

      expect(find.text(english.cardImportSummaryReadyLabel(1)), findsOneWidget);
      expect(
        find.text(english.cardImportSummaryInvalidLabel(1)),
        findsOneWidget,
      );
      final action = tester.widget<FilledButton>(
        h.button(english.cardImportContinueAction),
      );
      expect(action.onPressed, isNotNull);
    });

    testWidgets('unmapped required fields disable Continue and say so', (
      tester,
    ) async {
      await h.pump(tester);
      await h.pasteAndPreview(tester, 'a,b\n사과,apple\n');

      expect(find.text(english.cardImportMappingRequiredNote), findsOneWidget);
      final action = tester.widget<FilledButton>(
        h.button(english.cardImportContinueAction),
      );
      expect(action.onPressed, isNull);
      // The header cells name the mapping rows while the toggle is on…
      expect(find.text('a'), findsOneWidget);

      // …and turning it off swaps in the stable positional names (UC-10 A3).
      await tester.tap(find.text(english.cardImportHeaderToggleLabel));
      await tester.pumpAndSettle();
      expect(
        find.text(english.cardImportColumnFallbackLabel('A')),
        findsOneWidget,
      );
    });

    testWidgets('an all-duplicate source disables Continue until Include '
        'duplicates', (tester) async {
      h.importer.existingKeys = <CardImportDuplicateKey>{
        cardImportDuplicateKey(frontFolded: '사과', backFolded: 'apple'),
      };
      await h.pump(tester);
      await h.pasteAndPreview(tester, 'front,back\n사과,apple\n');

      expect(
        find.text(english.cardImportRowStatusDuplicateExistingLabel),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(h.button(english.cardImportContinueAction))
            .onPressed,
        isNull,
      );

      // The toggle sits below the fold; an off-screen tap would land on the
      // sticky bar instead and silently navigate.
      await tester.ensureVisible(
        find.text(english.cardImportIncludeDuplicatesLabel),
      );
      await tester.tap(find.text(english.cardImportIncludeDuplicatesLabel));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(h.button(english.cardImportContinueAction))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('a parse failure shows the typed copy, and Back keeps the '
        'pasted text', (tester) async {
      h.transfer.nextParseFailure = const ValidationFailure(
        message: 'bad encoding',
        problems: <Enum>{CardTransferProblem.invalidEncoding},
      );
      await h.pump(tester);
      await h.pasteAndPreview(tester, 'front,back\n사과,apple');

      expect(find.text(english.cardImportErrorInvalidEncoding), findsOneWidget);

      await tester.tap(find.text(english.cardImportBackAction));
      await tester.pumpAndSettle();

      expect(find.text('front,back\n사과,apple'), findsOneWidget);
    });
  });

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
      expect(
        find.text(
          english.cardImportFileMetaLabel(
            'CSV',
            english.cardImportFileSizeKilobytes(1),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(english.cardImportReplaceFileAction), findsOneWidget);
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
      expect(find.text(english.cardImportSummaryReadyLabel(1)), findsOneWidget);

      await tester.tap(find.text('Nouns'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verbs').last);
      await tester.pumpAndSettle();

      // The other sheet's rows, re-classified under its own header row.
      expect(find.text(english.cardImportSummaryReadyLabel(2)), findsOneWidget);
    });
  });
}
