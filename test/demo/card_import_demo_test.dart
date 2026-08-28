@Tags(<String>['golden', 'review'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/di/card_import_repository_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/card/domain/failures/card_transfer_failure.dart';
import 'package:memox/features/card/domain/models/card_import_preview_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_source_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../features/card/presentation/support/fake_card_repository.dart';
import '../features/card/presentation/support/fake_card_transfer_repositories.dart';
import '../support/study_render.dart';

/// DEMO renders (not assertions) of the import wizard (UC-10, M4.12):
/// device-faithful PNGs for design review, driven through the real screen
/// with the three transfer contracts faked. Korean sample content, same
/// reasoning as `card_screens_demo_test.dart`. Run with:
///   flutter test --update-goldens --tags golden test/demo/card_import_demo_test.dart
const DeckContextModel _demoContext = DeckContextModel(
  deckName: 'Korean · TOPIK I',
  ancestors: <DeckBreadcrumbSegment>[
    DeckBreadcrumbSegment(id: 'lang', name: 'Languages'),
    DeckBreadcrumbSegment(id: 'ko', name: 'Korean'),
  ],
);

const String _demoRows =
    'front,back,tags\n'
    '사과,apple,fruit\n'
    '바다,sea,nature;water\n'
    '감사합니다,,polite\n'
    '산,mountain,nature\n'
    '산,mountain,nature\n';

/// The all-valid variant: every row imports, so Preview reads "4 of 4 ready"
/// (state 3) and the result is the plain success face (state 6).
const String _validRows =
    'front,back,tags\n'
    '사과,apple,fruit\n'
    '바다,sea,nature;water\n'
    '감사합니다,thank you,polite\n'
    '산,mountain,nature\n';

void main() {
  final english = AppLocalizationsEn();

  late FakeCardRepository cards;
  late FakeCardTransferRepository transfer;
  late FakeCardImportSourceRepository picker;
  late FakeCardImportCommitRepository importer;

  setUp(() {
    cards = FakeCardRepository.loaded(
      <dynamic>[FakeCardRepository().listItem('c1', front: '기존')].cast(),
      total: 142,
    )..deckContextToShow = _demoContext;
    transfer = FakeCardTransferRepository();
    picker = FakeCardImportSourceRepository();
    importer = FakeCardImportCommitRepository();
  });

  tearDown(() => cards.dispose());

  Widget scope(Brightness brightness) => ProviderScope(
    overrides: [
      cardRepositoryProvider.overrideWithValue(cards),
      cardTransferRepositoryProvider.overrideWithValue(transfer),
      cardImportSourceRepositoryProvider.overrideWithValue(picker),
      cardImportRepositoryProvider.overrideWithValue(importer),
    ],
    child: ReviewApp(
      home: const CardImportScreen(deckId: 'demo'),
      brightness: brightness,
    ),
  );

  Future<void> pasteAndPreview(
    WidgetTester tester, {
    String rows = _demoRows,
  }) async {
    await tester.tap(find.text(english.cardImportPasteOptionTitle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), rows);
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardImportPreviewAction));
    await tester.pumpAndSettle();
  }

  Future<void> submitFromPreview(WidgetTester tester, int count) async {
    await tester.tap(find.text(english.cardImportContinueAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardImportSubmitAction(count)));
    await tester.pumpAndSettle();
  }

  testWidgets('source — idle, light', (tester) async {
    await pumpReview(tester, scope(Brightness.light));
    await matchesReviewGolden('goldens/card_import_source_light.png');
  });

  testWidgets('source — idle, dark', (tester) async {
    await pumpReview(tester, scope(Brightness.dark));
    await matchesReviewGolden('goldens/card_import_source_dark.png');
  });

  testWidgets('source — file ready with the compact summary (state 1)', (
    tester,
  ) async {
    picker.fileToPick = CardTransferFileSource(
      name: 'topik_vocab_week3.csv',
      bytes: Uint8List.fromList(utf8.encode(_demoRows)),
      format: CardTransferFormat.csv,
    );
    await pumpReview(tester, scope(Brightness.light));
    await tester.tap(find.text(english.cardImportChooseFileAction));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_import_source_ready_light.png');
  });

  testWidgets('source — paste selected with rows typed', (tester) async {
    await pumpReview(tester, scope(Brightness.light));
    await tester.tap(find.text(english.cardImportPasteOptionTitle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), _demoRows);
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_import_paste_light.png');
  });

  testWidgets('preview — every row ready (state 3)', (tester) async {
    await pumpReview(tester, scope(Brightness.light));
    await pasteAndPreview(tester, rows: _validRows);

    await matchesReviewGolden('goldens/card_import_preview_valid_light.png');
  });

  testWidgets('preview — mixed ready, invalid and duplicates', (tester) async {
    // One row already lives in the deck, one repeats inside the paste, one
    // is missing its back — the full status vocabulary on one screen.
    importer.existingKeys = <CardImportDuplicateKey>{
      cardImportDuplicateKey(frontFolded: '사과', backFolded: 'apple'),
    };
    await pumpReview(tester, scope(Brightness.light));
    await pasteAndPreview(tester);

    await matchesReviewGolden('goldens/card_import_preview_light.png');
  });

  testWidgets('preview — parsing in flight (state 2)', (tester) async {
    // **The one phase golden the wizard never had.** The gate holds the
    // decode open so the panel is on screen; the spinner is an animation, so
    // the frame is pinned by pumping a fixed duration from mount rather than
    // settling — the same clock every run of this test starts at zero.
    transfer.parseGate = Completer<void>();
    await pumpReview(tester, scope(Brightness.light));
    await tester.tap(find.text(english.cardImportPasteOptionTitle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), _validRows);
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardImportPreviewAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await matchesReviewGolden('goldens/card_import_parsing_light.png');

    transfer.parseGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('import — submitting in flight (state 5)', (tester) async {
    // Same shape as the parsing render: the commit gate holds the atomic
    // batch open, the confirm panel has been replaced by the submit panel at
    // the same rect, and the footer reads Importing… with no second spinner.
    importer.commitGate = Completer<void>();
    await pumpReview(tester, scope(Brightness.light));
    await pasteAndPreview(tester, rows: _validRows);
    await tester.tap(find.text(english.cardImportContinueAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardImportSubmitAction(4)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await matchesReviewGolden('goldens/card_import_submitting_light.png');

    importer.commitGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('preview — parse error with typed recovery copy', (tester) async {
    transfer.nextParseFailure = const ValidationFailure(
      message: 'demo',
      problems: <Enum>{CardTransferProblem.invalidEncoding},
    );
    await pumpReview(tester, scope(Brightness.light));
    await pasteAndPreview(tester);

    await matchesReviewGolden('goldens/card_import_parse_error_light.png');
  });

  testWidgets('import — confirmation summary', (tester) async {
    await pumpReview(tester, scope(Brightness.light));
    await pasteAndPreview(tester);
    await tester.tap(find.text(english.cardImportContinueAction));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_import_confirm_light.png');
  });

  testWidgets('result — import complete (state 6)', (tester) async {
    await pumpReview(tester, scope(Brightness.light));
    await pasteAndPreview(tester, rows: _validRows);
    await submitFromPreview(tester, 4);

    await matchesReviewGolden('goldens/card_import_result_complete_light.png');
  });

  testWidgets('result — imported with skips, dark (state 7)', (tester) async {
    // The mixed paste: one invalid row and one in-file duplicate skipped —
    // the tertiary hero, the per-cause rows, and the fix-it hint.
    await pumpReview(tester, scope(Brightness.dark));
    await pasteAndPreview(tester);
    await submitFromPreview(tester, 3);

    await matchesReviewGolden('goldens/card_import_result_skips_dark.png');
  });

  testWidgets('result — no new cards added (edge case)', (tester) async {
    await pumpReview(tester, scope(Brightness.light));
    await pasteAndPreview(tester, rows: _validRows);
    await tester.tap(find.text(english.cardImportContinueAction));
    await tester.pumpAndSettle();
    // Every row landed through another writer between preview and commit;
    // the in-transaction recheck skips them all (BR-170).
    importer.existingKeys = <CardImportDuplicateKey>{
      cardImportDuplicateKey(frontFolded: '사과', backFolded: 'apple'),
      cardImportDuplicateKey(frontFolded: '바다', backFolded: 'sea'),
      cardImportDuplicateKey(frontFolded: '감사합니다', backFolded: 'thank you'),
      cardImportDuplicateKey(frontFolded: '산', backFolded: 'mountain'),
    };
    await tester.tap(find.text(english.cardImportSubmitAction(4)));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_import_result_zero_light.png');
  });

  testWidgets('result — commit failure (state 8)', (tester) async {
    importer.nextCommitFailure = const DatabaseFailure(message: 'demo');
    await pumpReview(tester, scope(Brightness.light));
    await pasteAndPreview(tester, rows: _validRows);
    await submitFromPreview(tester, 4);

    await matchesReviewGolden('goldens/card_import_failure_light.png');
  });
}
