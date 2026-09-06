import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_transfer_field_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_import_mapping_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_import_pair_widget.dart';
import 'package:memox/shared/widgets/mx_dropdown.dart';

import '../../../support/android_text_scaler.dart';
import '../../study/presentation/support/study_widget_harness.dart';

/// The destination dropdown keeps room for the destination.
///
/// **The half that was being cut is the half the step exists to decide**
/// (SC-C7-02). The mapping row split its line 50/50 with no fallback, so at
/// `textScaler` 2.0 the dropdown got half a phone: measured at 360×800, its box
/// was 144.0dp while the selected `Pronunciation` wanted 216.95 and
/// `RenderParagraph.didExceedMaxLines` was true. At 393×852 the same pair
/// measured 160.5 against 216.95. At scale 1.0 it fits at 109.45 and is not
/// clipped — which is why the fix is a measurement and not a redesign.
///
/// `wrapForTest` comes from the study feature's harness rather than the import
/// wizard's, deliberately: `card_import_wizard_harness.dart` replaces
/// `MediaQueryData` wholesale, so a test that asks what the layout does with a
/// real text scaler cannot use it.
void main() {
  Future<void> pumpRow(
    WidgetTester tester, {
    required double width,
    required TextScaler scaler,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrapForTest(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CardImportMappingRowWidget(
            column: 0,
            headerText: 'Front',
            field: CardTransferField.pronunciation,
            onAssign: (_) {},
          ),
        ),
        isScrollable: false,
        textScaler: scaler,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The paragraph the dropdown paints for its selected option.
  RenderParagraph selectedLabel(WidgetTester tester) {
    final finder = find.descendant(
      of: find.byType(MxDropdown<CardTransferField?>),
      matching: find.byType(RichText),
    );
    return tester.renderObject<RenderParagraph>(finder.first);
  }

  // **The non-linear scaler is the one that matters here** (final corrective
  // pass). The threshold used to be `textScalerOf(context).scale(240)`, and
  // under `TextScaler.linear(2.0)` that returns 480 — the row stacks and the
  // test passes over a broken layout. Android's table is flat past 100sp, so on
  // a real phone the same call returned **240 unchanged** and the row never
  // stacked. `AndroidTextScaler.largest` grows body rungs by exactly 2.0, so a
  // difference between the two harnesses is a difference in the *shape* of the
  // curve and nothing else.
  for (final width in <double>[320, 360, 393]) {
    testWidgets(
      '${width.toInt()}dp at Android 2.0: the destination is not clipped',
      (tester) async {
        await pumpRow(tester, width: width, scaler: AndroidTextScaler.largest);

        expect(selectedLabel(tester).didExceedMaxLines, isFalse);

        // Stacked: the control has the whole band rather than half of it.
        final row = tester.getRect(find.byType(CardImportPairWidget));
        final control = tester.getRect(
          find.byType(MxDropdown<CardTransferField?>),
        );
        expect(control.width, row.width);
      },
    );
  }

  for (final width in <double>[360, 393]) {
    testWidgets('${width.toInt()}dp at 2.0: the destination is not clipped', (
      tester,
    ) async {
      await pumpRow(tester, width: width, scaler: const TextScaler.linear(2));

      final label = selectedLabel(tester);
      expect(label.didExceedMaxLines, isFalse);

      // Stacked: the control has the whole band rather than half of it.
      final row = tester.getRect(find.byType(CardImportPairWidget));
      final control = tester.getRect(
        find.byType(MxDropdown<CardTransferField?>),
      );
      expect(control.width, row.width);
    });
  }

  testWidgets('393dp at 1.0: still two columns, and still not clipped', (
    tester,
  ) async {
    await pumpRow(tester, width: 393, scaler: TextScaler.noScaling);

    expect(selectedLabel(tester).didExceedMaxLines, isFalse);

    // The reference render must not move: at ordinary scale the pair is the
    // 50/50 row wireframe I6 draws, which is what the committed import
    // goldens show.
    final row = tester.getRect(find.byType(CardImportPairWidget));
    final control = tester.getRect(find.byType(MxDropdown<CardTransferField?>));
    expect(control.width, lessThan(row.width / 2 + 1));
    expect(control.right, row.right);
  });
}
