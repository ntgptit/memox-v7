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

      expect(find.text(english.cardImportConfirmHeading), findsOneWidget);
      expect(
        find.text(english.cardImportConfirmTargetLabel('TOPIK I')),
        findsOneWidget,
      );
      expect(find.text(english.cardImportConfirmWriteLabel(2)), findsOneWidget);
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
      expect(find.text(english.cardImportResultHeading), findsOneWidget);
      expect(
        find.text(english.cardImportResultImportedLabel(2)),
        findsOneWidget,
      );
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

      expect(find.text(english.cardImportTryAgainAction), findsOneWidget);
      expect(find.text(english.cardImportConfirmHeading), findsOneWidget);

      // Try again succeeds without re-picking or re-mapping anything.
      h.importer.nextCommitFailure = null;
      await tester.tap(find.text(english.cardImportTryAgainAction));
      await tester.pumpAndSettle();

      expect(h.importer.commits, hasLength(2));
      expect(find.text(english.cardImportResultHeading), findsOneWidget);
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
