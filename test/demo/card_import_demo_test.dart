@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/di/card_import_repository_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/card/domain/failures/card_transfer_failure.dart';
import 'package:memox/features/card/domain/models/card_import_preview_model.dart';
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

  Future<void> pasteAndPreview(WidgetTester tester) async {
    await tester.tap(find.text(english.cardImportPasteOptionTitle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), _demoRows);
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardImportPreviewAction));
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

  testWidgets('source — paste selected with rows typed', (tester) async {
    await pumpReview(tester, scope(Brightness.light));
    await tester.tap(find.text(english.cardImportPasteOptionTitle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), _demoRows);
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_import_paste_light.png');
  });

  testWidgets('preview — mixed ready, invalid and duplicates', (tester) async {
    // One row already lives in the deck, one repeats inside the paste, one
    // is missing its back — the full status vocabulary on one screen.
    importer.existingKeys = <String>{
      cardImportDuplicateKey(frontFolded: '사과', backFolded: 'apple'),
    };
    await pumpReview(tester, scope(Brightness.light));
    await pasteAndPreview(tester);

    await matchesReviewGolden('goldens/card_import_preview_light.png');
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

  testWidgets('import — result, dark', (tester) async {
    await pumpReview(tester, scope(Brightness.dark));
    await pasteAndPreview(tester);
    await tester.tap(find.text(english.cardImportContinueAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardImportSubmitAction(3)));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_import_result_dark.png');
  });
}
