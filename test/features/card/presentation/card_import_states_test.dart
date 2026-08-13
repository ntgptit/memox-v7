import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_import_preview_model.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/card_import_wizard_harness.dart';

/// The wizard's presentation state matrix (wireframe M4.12 states 2–8):
/// the parsing face, the stepper's earned checks, and the four outcome
/// faces. Source/preview interactions live in
/// `card_import_wizard_test.dart`, the commit lock and reset in
/// `card_import_commit_flow_test.dart`, the upload summary and sheets in
/// `card_import_upload_test.dart` — the four split at the 400-line guard.
void main() {
  final h = installCardImportWizardHarness();
  final AppLocalizationsEn english = h.english;

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

      // The panel: what is being read, and the no-writes reassurance — under
      // the step's own heading, which never leaves while the decode runs.
      expect(find.text(english.cardImportPreviewHeading), findsOneWidget);
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
      // no step change and no layout reset. The context line counts *data*
      // rows — one, not two — so it agrees with the headline's total.
      expect(find.text(english.cardImportParsingPasteTitle), findsNothing);
      expect(find.text(english.cardImportFileRowsDetected(1)), findsOneWidget);
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
      // The skipped count comes from the transaction's own recheck — the
      // preview classified this row Ready, so only the commit source can
      // put this row on screen (BR-170).
      expect(
        find.text(english.cardImportDuplicatesSkippedRowLabel),
        findsOneWidget,
      );
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

    testWidgets('system Back on the failure face asks to discard — never a '
        'silent step walk under an unchanged screen', (tester) async {
      h.importer.nextCommitFailure = const DatabaseFailure(message: 'disk');
      await h.pump(tester);
      await submitFromPaste(tester, 'front,back\n사과,apple\n');
      expect(find.text(english.cardImportFailureTitle), findsOneWidget);

      // Android Back. Stepping the wizard back here would change nothing on
      // screen (the phase is derived from the failure before the step), so
      // Back must mean what Close means: the discard question (W8).
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      // ignore: avoid_dynamic_calls
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(find.text(english.cardImportDiscardTitle), findsOneWidget);

      // Declining keeps the failure face and the retained plan untouched.
      await tester.tap(find.text(english.commonCancelAction).last);
      await tester.pumpAndSettle();
      expect(find.text(english.cardImportFailureTitle), findsOneWidget);
      expect(find.text(english.cardImportTryAgainAction), findsOneWidget);
      expect(h.importer.commits, hasLength(1));
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
