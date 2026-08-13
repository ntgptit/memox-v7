import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/card_export_failure.dart';
import 'package:memox/features/card/domain/models/card_export_scope_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_format_model.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_export_error_band_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_export_format_options_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/card_export_sheet_harness.dart';

/// The seven typed refusals and the two faces they wear (UC-11 E1-E6;
/// M4.13 W3 states 5-7, E8).
///
/// Third file of the export trio, split from `card_export_states_test.dart`
/// at the 400-line guard along the seam the group already had a name for:
/// `card_export_sheet_test.dart` proves what the sheet *is*, the states file
/// what it *does*, and this one what it says when it cannot.
void main() {
  final h = installCardExportSheetHarness();
  final AppLocalizationsEn english = h.english;

  Finder primary(String label) => find.widgetWithText(FilledButton, label);

  group('failures (UC-11 E1-E6, M4.13 W3 states 5-7)', () {
    /// Every reachable problem, with the failure the layer below throws for
    /// it, the copy it must print, and whether Try again is on offer.
    final cases =
        <
          ({
            String name,
            Failure failure,
            String Function() copy,
            bool isRetryable,
          })
        >[
          (
            name: 'share unavailable (E1)',
            failure: const UnknownFailure(
              message: 'no share sheet',
              reason: CardExportProblem.shareUnavailable,
            ),
            copy: () => english.cardExportErrorShareUnavailable,
            isRetryable: true,
          ),
          (
            name: 'platform channel threw (E2)',
            failure: const UnknownFailure(
              message: 'channel failed',
              reason: CardExportProblem.sharePlatformError,
            ),
            copy: () => english.cardExportErrorSharePlatformError,
            isRetryable: true,
          ),
          (
            name: 'read failed (E3)',
            failure: const DatabaseFailure(
              message: 'read failed',
              reason: CardExportProblem.readFailed,
            ),
            copy: () => english.cardExportErrorReadFailed,
            isRetryable: true,
          ),
          (
            name: 'deck missing (E3)',
            failure: const NotFoundFailure(
              message: 'deck gone',
              reason: CardExportProblem.deckMissing,
            ),
            copy: () => english.cardExportErrorDeckMissing,
            isRetryable: false,
          ),
          (
            name: 'empty scope (E5)',
            failure: const ValidationFailure(
              message: 'empty',
              problems: <Enum>{CardExportProblem.emptyScope},
            ),
            copy: () => english.cardExportErrorEmptyScope,
            isRetryable: false,
          ),
          (
            name: 'stale selection (E6)',
            failure: const ValidationFailure(
              message: 'stale',
              problems: <Enum>{CardExportProblem.staleSelection},
            ),
            copy: () => english.cardExportErrorStaleSelection,
            isRetryable: false,
          ),
        ];

    for (final testCase in cases) {
      testWidgets('${testCase.name} renders its own copy', (tester) async {
        final failure = testCase.failure;
        if (failure is UnknownFailure) {
          h.destination.nextShareFailure = failure;
        } else {
          h.exports.nextReadFailure = failure;
        }
        await h.pump(tester);
        await h.openWholeDeckExport(tester);
        await tester.tap(primary(english.cardExportSubmitAction(3)));
        await tester.pumpAndSettle();

        expect(find.byType(CardExportErrorBandWidget), findsOneWidget);
        expect(find.text(testCase.copy()), findsOneWidget);
        expect(
          find.text(
            testCase.isRetryable
                ? english.cardExportErrorTitle
                : english.cardExportScopeChangedTitle,
          ),
          findsOneWidget,
        );
        // A scope that no longer exists offers no retry — the primary is gone,
        // not greyed, and `Close` is the only way on (W3 state 7).
        expect(
          primary(english.cardExportRetryAction),
          testCase.isRetryable ? findsOneWidget : findsNothing,
        );
        expect(
          find.text(english.cardExportCloseAction),
          testCase.isRetryable ? findsNothing : findsOneWidget,
        );
      });
    }

    testWidgets('the error band announces itself (W6)', (tester) async {
      // The band appears while focus is still on the primary, which only
      // relabels itself. Without a live region the screen-reader user hears a
      // button change name and never hears that the export failed.
      h.exports.nextReadFailure = const DatabaseFailure(
        message: 'read failed',
        reason: CardExportProblem.readFailed,
      );
      final handle = tester.ensureSemantics();
      await h.pump(tester);
      await h.openWholeDeckExport(tester);
      await tester.tap(primary(english.cardExportSubmitAction(3)));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byType(CardExportErrorBandWidget)),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('the scope-changed face stops taking format taps (W3 state 7)', (
      tester,
    ) async {
      // A control that is interactive but can no longer affect anything is the
      // screen lying about what it can still do: the primary is gone, `Close`
      // is the only way on, and a format change has nothing left to apply to.
      h.exports.nextReadFailure = const ValidationFailure(
        message: 'stale',
        problems: <Enum>{CardExportProblem.staleSelection},
      );
      await h.pump(tester);
      await h.openWholeDeckExport(tester);
      await tester.tap(primary(english.cardExportSubmitAction(3)));
      await tester.pumpAndSettle();

      // Still readable — the options are the record of what was asked for.
      expect(find.byType(CardExportFormatOptionsWidget), findsOneWidget);
      await tester.tap(
        find.text(CardTransferFormat.tsv.fileExtension.toUpperCase()),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<CardExportFormatOptionsWidget>(
              find.byType(CardExportFormatOptionsWidget),
            )
            .selected,
        CardTransferFormat.csv,
        reason: 'the tap must not land once there is nothing to export',
      );
    });

    testWidgets('encode failure is its own reason (E4)', (tester) async {
      h.encoders.shouldFailEncode = true;
      await h.pump(tester);
      await h.openWholeDeckExport(tester);
      await tester.tap(primary(english.cardExportSubmitAction(3)));
      await tester.pumpAndSettle();

      expect(find.text(english.cardExportErrorEncodeFailed), findsOneWidget);
      expect(
        h.destination.shareCalls,
        0,
        reason: 'no partial artifact is ever handed on',
      );
    });

    testWidgets('Try again re-submits the same scope and format (E8)', (
      tester,
    ) async {
      h.exports.nextReadFailure = const DatabaseFailure(
        message: 'read failed',
        reason: CardExportProblem.readFailed,
      );
      await h.pump(tester);
      await h.selectCards(tester);
      await h.openSelectionExport(tester);
      await tester.tap(
        find.text(CardTransferFormat.xlsx.fileExtension.toUpperCase()),
      );
      await tester.pumpAndSettle();
      await tester.tap(primary(english.cardExportSubmitAction(2)));
      await tester.pumpAndSettle();

      h.exports.nextReadFailure = null;
      await tester.tap(primary(english.cardExportRetryAction));
      await tester.pumpAndSettle();

      expect(h.exports.scopes, hasLength(2));
      for (final scope in h.exports.scopes) {
        expect((scope as CardExportSelectionScope).cardIds, <String>{
          'c0',
          'c1',
        });
      }
      expect(h.encoders.formats, <CardTransferFormat>[CardTransferFormat.xlsx]);
      expect(find.text(english.cardExportSharedMessage), findsOneWidget);
    });
  });
}
