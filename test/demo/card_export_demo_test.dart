@Tags(<String>['golden', 'review'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/card/di/card_export_repository_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/failures/card_export_failure.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_record_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/widgets/items/card_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';

import '../features/card/data/support/card_export_fixture.dart';
import '../features/card/presentation/support/fake_card_export_repositories.dart';
import '../features/card/presentation/support/fake_card_repository.dart';
import '../support/study_render.dart';

/// DEMO renders (not assertions) of the export sheet (UC-11, M4.13):
/// device-faithful PNGs for design review, driven through the real card list
/// and the real entry points with the four export seams faked. Run with:
///   flutter test --update-goldens --tags golden test/demo/card_export_demo_test.dart
///
/// **The generating face is captured too, and the argument for leaving it out
/// was wrong.** It read "a spinner mid-animation is a flaky baseline that tells
/// a reviewer nothing", and the cost of believing it was two defects that only
/// an image could show: the `Exporting…` label shipped at alpha 0, and once it
/// was painted the button turned out to wear `disabledSurface`, printing the
/// one sentence that says what is happening at 2.29:1 — with a `primary`
/// spinner invisible on a `primary` fill. `pump` at a fixed offset is not
/// flaky: the arc lands at the same angle every run.
const DeckContextModel _demoContext = DeckContextModel(
  deckName: 'Korean · TOPIK I',
  ancestors: <DeckBreadcrumbSegment>[
    DeckBreadcrumbSegment(id: 'lang', name: 'Languages'),
    DeckBreadcrumbSegment(id: 'ko', name: 'Korean'),
  ],
);

void main() {
  final english = AppLocalizationsEn();

  late FakeCardRepository cards;
  late FakeCardExportRepository exports;
  late FakeCardExportDestinationRepository destination;
  late FakeCardExportEncoders encoders;

  setUp(() {
    cards = FakeCardRepository.loaded(
      List<CardListItemModel>.generate(
        4,
        (index) => FakeCardRepository().listItem(
          'c$index',
          front: <String>['사과', '바다', '감사합니다', '산'][index],
          back: <String>['apple', 'sea', 'thank you', 'mountain'][index],
        ),
      ),
      total: 128,
    )..deckContextToShow = _demoContext;
    exports = FakeCardExportRepository()
      ..records = <CardTransferRecord>[
        exportRecord(front: '사과', back: 'apple', tags: <String>['fruit']),
        exportRecord(front: '바다', back: 'sea'),
      ];
    destination = FakeCardExportDestinationRepository();
    encoders = FakeCardExportEncoders();
  });

  tearDown(() => cards.dispose());

  Widget scope(
    Brightness brightness, {
    Locale? locale,
    double textScale = 1,
  }) => ProviderScope(
    overrides: [
      cardRepositoryProvider.overrideWithValue(cards),
      cardExportRepositoryProvider.overrideWithValue(exports),
      cardExportDestinationRepositoryProvider.overrideWithValue(destination),
      cardTransferEncoderResolverProvider.overrideWithValue(encoders.resolver),
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 8, 13)),
    ],
    child: ReviewApp(
      home: const CardListScreen(deckId: 'demo'),
      brightness: brightness,
      locale: locale,
      textScale: textScale,
    ),
  );

  Future<void> openWholeDeckExport(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardExportEntryAction).last);
    await tester.pumpAndSettle();
  }

  Future<void> openSelectionExport(WidgetTester tester) async {
    await tester.longPress(find.byType(CardTileWidget).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CardTileWidget).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardExportSelectionAction).last);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, int count) async {
    await tester.tap(
      find.widgetWithText(FilledButton, english.cardExportSubmitAction(count)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sheet — whole deck, initial, light', (tester) async {
    await pumpReview(tester, scope(Brightness.light));
    await openWholeDeckExport(tester);

    await matchesReviewGolden('goldens/card_export_sheet_light.png');
  });

  testWidgets('sheet — whole deck, initial, dark', (tester) async {
    await pumpReview(tester, scope(Brightness.dark));
    await openWholeDeckExport(tester);

    await matchesReviewGolden('goldens/card_export_sheet_dark.png');
  });

  testWidgets('sheet — the selection scope, with the bar still behind it', (
    tester,
  ) async {
    await pumpReview(tester, scope(Brightness.light));
    await openSelectionExport(tester);

    await matchesReviewGolden('goldens/card_export_selection_light.png');
  });

  testWidgets('sheet — a retryable failure keeps scope, format and Try again', (
    tester,
  ) async {
    exports.nextReadFailure = const DatabaseFailure(
      message: 'demo',
      reason: CardExportProblem.readFailed,
    );
    await pumpReview(tester, scope(Brightness.light));
    await openWholeDeckExport(tester);
    await submit(tester, 128);

    await matchesReviewGolden('goldens/card_export_error_light.png');
  });

  testWidgets('sheet — the scope itself is gone, so there is no primary', (
    tester,
  ) async {
    exports.nextReadFailure = const ValidationFailure(
      message: 'demo',
      problems: <Enum>{CardExportProblem.staleSelection},
    );
    await pumpReview(tester, scope(Brightness.light));
    await openSelectionExport(tester);
    await submit(tester, 2);

    await matchesReviewGolden('goldens/card_export_scope_changed_light.png');
  });

  testWidgets('sheet — generating, with Exporting… readable (W6)', (
    tester,
  ) async {
    // **The one moving state that is worth a baseline after all.** It was left
    // out as "a spinner mid-animation would be flaky", and the cost of that
    // was a review finding: the label rendered at alpha 0 for a whole
    // milestone and no image existed to notice. `pump` at a fixed offset
    // instead of `pumpAndSettle` — which never returns while a spinner turns —
    // puts the arc at the same angle every run, so the frame is stable and the
    // words beside it are what the render is for.
    final gate = Completer<void>();
    destination.shareGate = gate;
    await pumpReview(tester, scope(Brightness.light));
    await openWholeDeckExport(tester);
    await tester.tap(
      find.widgetWithText(FilledButton, english.cardExportSubmitAction(128)),
    );
    // **Two pumps, and the second one is the whole point.** One `pump(d)` both
    // builds the generating face and schedules its frame, so the indicator's
    // controller is still at t=0 when it paints and the arc has no length —
    // three renders in a row showed a four-pixel dot and looked like a bug in
    // the spinner. Build first, then advance to the phase where the arc is
    // longest: Flutter's indeterminate cycle is ~1975ms and the head reaches 1
    // while the tail is still 0 at half of it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 990));

    await matchesReviewGolden('goldens/card_export_generating_light.png');
    gate.complete();
  });

  testWidgets('sheet — a retryable failure in dark', (tester) async {
    // The error band's only previous render was light, so nothing showed what
    // `errorContainer` does against the dark sheet it sits on.
    exports.nextReadFailure = const DatabaseFailure(
      message: 'demo',
      reason: CardExportProblem.readFailed,
    );
    await pumpReview(tester, scope(Brightness.dark));
    await openWholeDeckExport(tester);
    await submit(tester, 128);

    await matchesReviewGolden('goldens/card_export_error_dark.png');
  });

  testWidgets('sheet — Vietnamese, where every string is longer', (
    tester,
  ) async {
    await pumpReview(
      tester,
      scope(Brightness.light, locale: const Locale('vi')),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(AppLocalizationsVi().cardExportEntryAction).last,
    );
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/card_export_sheet_vi_light.png');
  });

  testWidgets('sheet — 320x568 at 2.0x, the smallest screen at the largest '
      'type', (tester) async {
    // The combination W6 now names explicitly: a sheet grows until it hits the
    // screen, so this is where the body has to start scrolling and the action
    // row has to stay in reach. `card_export_alignment_test.dart` asserts both;
    // this is what they look like.
    await pumpReview(
      tester,
      scope(Brightness.light, textScale: 2),
      surface: const Size(320, 568),
    );
    await openWholeDeckExport(tester);

    await matchesReviewGolden('goldens/card_export_compact_2x_light.png');
  });
}
