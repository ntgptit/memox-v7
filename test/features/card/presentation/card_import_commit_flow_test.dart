import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/card_import_wizard_harness.dart';

/// The wizard's confirm/commit step (UC-10 steps 6–8) and the close/discard
/// contract (W5). The source and preview steps live in
/// `card_import_wizard_test.dart`.
void main() {
  final h = installCardImportWizardHarness();
  final AppLocalizationsEn english = h.english;

  group('import step', () {
    Future<void> toConfirm(WidgetTester tester) async {
      await h.pasteAndPreview(tester, 'front,back\n사과,apple\n배,pear\n');
      await tester.tap(find.text(english.cardImportContinueAction));
      await tester.pumpAndSettle();
    }

    testWidgets('the confirmation names the target and the counts', (
      tester,
    ) async {
      await h.pump(tester);
      await toConfirm(tester);

      expect(
        find.text(english.cardImportConfirmHeading.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(english.cardImportConfirmTargetLabel('TOPIK I')),
        findsOneWidget,
      );
      // The plan as summary rows: the will-write count on the trailing edge
      // of its own labelled row, the same language the result faces speak.
      expect(
        find.text(english.cardImportConfirmImportRowLabel),
        findsOneWidget,
      );
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('a successful commit is one batch and shows the result', (
      tester,
    ) async {
      await h.pump(tester);
      await toConfirm(tester);

      await tester.tap(find.text(english.cardImportSubmitAction(2)));
      await tester.pumpAndSettle();

      expect(h.importer.commits, hasLength(1));
      expect(h.importer.commits.single.records, hasLength(2));
      // The outcome mode (state 6): the hero names the count and the deck,
      // the summary card carries the Added row, and the wizard chrome is
      // gone — the stepper with it.
      expect(find.text(english.cardImportSuccessTitle), findsOneWidget);
      expect(
        find.text(english.cardImportSuccessBody(2, 'TOPIK I')),
        findsOneWidget,
      );
      expect(find.text(english.cardImportAddedRowLabel), findsOneWidget);
      expect(find.text(english.cardImportResultsTitle), findsOneWidget);
      expect(find.text(english.cardImportStepSourceLabel), findsNothing);
      // The commit latched: no second batch is reachable from here.
      expect(find.text(english.cardImportAnotherAction), findsOneWidget);
    });

    testWidgets('a failed commit keeps the draft and offers Try again', (
      tester,
    ) async {
      h.importer.nextCommitFailure = const DatabaseFailure(message: 'disk');
      await h.pump(tester);
      await toConfirm(tester);

      await tester.tap(find.text(english.cardImportSubmitAction(2)));
      await tester.pumpAndSettle();

      // The failure face (state 8): outcome layout, the deck-untouched
      // reassurance, and the two ways forward.
      expect(find.text(english.cardImportFailureTitle), findsOneWidget);
      expect(find.text(english.cardImportFailureBody), findsOneWidget);
      expect(find.text(english.cardImportTryAgainAction), findsOneWidget);
      expect(find.text(english.cardImportBackToPreviewAction), findsOneWidget);

      // Try again succeeds without re-picking or re-mapping anything.
      h.importer.nextCommitFailure = null;
      await tester.tap(find.text(english.cardImportTryAgainAction));
      await tester.pumpAndSettle();

      expect(h.importer.commits, hasLength(2));
      expect(find.text(english.cardImportSuccessTitle), findsOneWidget);
    });

    testWidgets('Import another file resets the draft and returns to '
        'Source', (tester) async {
      await h.pump(tester);
      await toConfirm(tester);
      await tester.tap(find.text(english.cardImportSubmitAction(2)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(english.cardImportAnotherAction));
      await tester.pumpAndSettle();

      expect(find.text(english.cardImportChoosePrompt), findsOneWidget);
      final action = tester.widget<FilledButton>(
        h.button(english.cardImportPreviewAction),
      );
      expect(action.onPressed, isNull, reason: 'the draft is gone');
    });
  });

  group('navigation locks while the commit is in flight (F)', () {
    Future<void> toConfirm(WidgetTester tester) async {
      await h.pasteAndPreview(tester, 'front,back\n사과,apple\n배,pear\n');
      await tester.tap(find.text(english.cardImportContinueAction));
      await tester.pumpAndSettle();
    }

    testWidgets('Close, system Back and a second submit are all inert until '
        'the transaction resolves', (tester) async {
      final gate = Completer<void>();
      h.importer.commitGate = gate;
      await h.pump(tester);
      await toConfirm(tester);

      await tester.tap(find.text(english.cardImportSubmitAction(2)));
      await tester.pump();

      // Mid-commit the submit panel is on screen (state 5): the count, the
      // don't-close line, and Close disabled — tapping it opens nothing.
      expect(find.text(english.cardImportSubmittingTitle(2)), findsOneWidget);
      expect(find.text(english.cardImportSubmittingBody), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close), warnIfMissed: false);
      await tester.pump();
      expect(find.text(english.cardImportDiscardTitle), findsNothing);
      expect(find.text(english.cardImportSubmittingTitle(2)), findsOneWidget);

      // System Back neither steps back nor leaves.
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      // ignore: avoid_dynamic_calls
      await widgetsAppState.didPopRoute();
      await tester.pump();
      expect(find.text(english.cardImportSubmittingTitle(2)), findsOneWidget);
      expect(
        find.text(english.cardImportMappingHeading.toUpperCase()),
        findsNothing,
      );

      // A second press cannot start a second batch: the primary is in its
      // loading state, and canSubmit is latched until the commit resolves.
      await tester.tap(find.byType(FilledButton).last, warnIfMissed: false);
      await tester.pump();
      expect(h.importer.commits, hasLength(1));

      // The transaction resolves; the result appears and navigation is
      // alive again.
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text(english.cardImportSuccessTitle), findsOneWidget);
      expect(h.importer.commits, hasLength(1));
    });
  });

  group('Import another file resets everything (G)', () {
    testWidgets('the pasted text is gone from the reopened paste box, and '
        'Preview is disabled until a new source exists', (tester) async {
      await h.pump(tester);
      await h.pasteAndPreview(tester, 'front,back\n사과,apple\n');
      await tester.tap(find.text(english.cardImportContinueAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.cardImportSubmitAction(1)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(english.cardImportAnotherAction));
      await tester.pumpAndSettle();

      // Back on Source with an empty draft…
      expect(find.text(english.cardImportChoosePrompt), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(h.button(english.cardImportPreviewAction))
            .onPressed,
        isNull,
      );

      // …and the paste box itself is empty — the controller was cleared with
      // the providers, not left holding the old rows.
      await tester.tap(find.text(english.cardImportPasteOptionTitle));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      // The exact rows that were pasted are gone; the placeholder's sample
      // (which shares vocabulary by design) is all that may remain.
      expect(find.text('front,back\n사과,apple\n'), findsNothing);
    });
  });

  group('close and back', () {
    testWidgets('a dirty draft asks before discarding', (tester) async {
      await h.pump(tester);
      await tester.tap(find.text(english.cardImportPasteOptionTitle));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '사과,apple');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text(english.cardImportDiscardTitle), findsOneWidget);

      await tester.tap(find.text(english.commonCancelAction));
      await tester.pumpAndSettle();

      expect(find.text('사과,apple'), findsOneWidget);
    });
  });
}
