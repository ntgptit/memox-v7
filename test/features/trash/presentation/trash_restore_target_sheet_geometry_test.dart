import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/domain/entities/trash_batch_entity.dart';
import 'package:memox/features/trash/domain/models/trash_restore_target_model.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';

import 'support/fake_trash_repository.dart';

/// Where the restore picker's own parts sit (SC-C2-16).
///
/// A separate file rather than another case inside
/// `trash_screen_restore_test.dart`, which is already at its group boundary —
/// and the two measure different things: that one asks what the sheet *does*,
/// this one asks where its edges land.
///
/// **The two gaps are not the same rank and must not be the same number.** The
/// gap under the title is an internal label step (`md`); the gap over the
/// primary is the sheet's terminal boundary (`lg`). They read as one gap when
/// they are one value, which is what shipped until this test.
void main() {
  final english = AppLocalizationsEn();
  final now = DateTime.utc(2026, 8, 15, 12);

  Future<void> pumpRestoreSheet(WidgetTester tester) async {
    // Two targets, neither of them the batch's origin, so the list is short
    // enough not to scroll: `Flexible(ListView)` takes the extra space out of
    // the list's height when it does, and a `getRect` on the last tile then
    // measures a clipped edge rather than the gap.
    final repository = FakeTrashRepository(
      batches: <TrashBatchEntity>[
        fakeBatch(id: 'b1', name: 'a card', originDeckId: 'elsewhere'),
      ],
      targets: <TrashRestoreTarget>[
        const TrashDeckTarget(deckId: 'a', name: 'A', parentName: null),
        const TrashDeckTarget(deckId: 'b', name: 'B', parentName: null),
      ],
    );
    addTearDown(repository.dispose);

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trashRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TrashScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(english.trashRestoreAction));
    await tester.pumpAndSettle();
  }

  /// The sheet's own primary. Named rather than `find.byType`, because the
  /// selection bar behind the sheet carries an `MxActionButton` too.
  final Finder primaryFinder = find.widgetWithText(
    MxActionButton,
    english.trashRestoreConfirmAction,
  );

  /// Rounded, because layout arithmetic lands on values like 15.999999999999998
  /// and a contract about a gap is not a contract about a float.
  double gap(double value) => double.parse(value.toStringAsFixed(1));

  group('the restore target sheet', () {
    testWidgets('ends at a section step, not at the title step', (
      tester,
    ) async {
      await pumpRestoreSheet(tester);

      final Rect lastTile = tester.getRect(find.byType(MxListTile).last);
      final Rect primary = tester.getRect(primaryFinder);

      expect(
        gap(primary.top - lastTile.bottom),
        AppSpacing.lg,
        reason:
            'the control that ends the sheet is separated from the list by '
            'the section step, not by the inside-a-control step it used to '
            'share with the title',
      );
    });

    testWidgets('keeps the title step tighter than the terminal step', (
      tester,
    ) async {
      await pumpRestoreSheet(tester);

      final Rect title = tester.getRect(
        find.text(english.trashRestoreTargetTitle),
      );
      final Rect firstTile = tester.getRect(find.byType(MxListTile).first);
      final Rect lastTile = tester.getRect(find.byType(MxListTile).last);
      final Rect primary = tester.getRect(primaryFinder);

      // The title gap stays `md`, matching the two sibling picker sheets
      // (card_bulk_overlays_widget.dart:95, move_deck_sheet_widget.dart:84).
      expect(gap(firstTile.top - title.bottom), AppSpacing.md);
      expect(
        gap(firstTile.top - title.bottom),
        lessThan(gap(primary.top - lastTile.bottom)),
        reason:
            'a label gap inside the sheet must not equal the gap that closes '
            'it, or the primary reads as one more row of the list',
      );
    });
  });
}
