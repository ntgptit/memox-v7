import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/domain/entities/trash_batch_entity.dart';
import 'package:memox/features/trash/domain/failures/trash_conflict_failure.dart';
import 'package:memox/features/trash/domain/models/trash_restore_target_model.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/fake_trash_repository.dart';

/// The Trash screen's state matrix (UC-21 UI states).
/// The restore flow of the Trash screen, split from `trash_screen_test.dart`
/// at the 400-line guard on its own group boundary. The pump helper is
/// duplicated on purpose: each file stands alone.
void main() {
  final english = AppLocalizationsEn();
  final now = DateTime.utc(2026, 8, 15, 12);

  Future<FakeTrashRepository> pumpTrash(
    WidgetTester tester, {
    required List<TrashBatchEntity> batches,
    List<TrashRestoreTarget> targets = const <TrashRestoreTarget>[],
  }) async {
    final repository = FakeTrashRepository(batches: batches, targets: targets);
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trashRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          // The real theme, because `MxTextButton`'s destructive role reads
          // `AppSemanticColors` from `ThemeData.extensions` — a bare
          // `MaterialApp` has none, and the selection bar throws on build.
          theme: buildLightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TrashScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return repository;
  }

  group('restore', () {
    testWidgets('the picker asks, and the answer reaches the repository', (
      tester,
    ) async {
      final repository = await pumpTrash(
        tester,
        batches: <TrashBatchEntity>[fakeBatch(id: 'b1', name: 'a card')],
        targets: <TrashRestoreTarget>[
          const TrashDeckTarget(
            deckId: 'origin',
            name: 'Origin',
            parentName: 'Parent',
          ),
        ],
      );

      await tester.tap(find.byTooltip(english.trashRestoreAction));
      await tester.pumpAndSettle();

      expect(find.text(english.trashRestoreTargetTitle), findsOneWidget);
      // Nothing is written by opening the sheet — the user still confirms
      // (BR-262), even though the origin is preselected.
      expect(repository.restores, isEmpty);

      await tester.tap(find.text(english.trashRestoreConfirmAction));
      await tester.pumpAndSettle();

      expect(repository.restores, hasLength(1));
      expect(repository.restores.single.batchId, 'b1');
      expect(repository.restores.single.target.deckId, 'origin');
    });

    testWidgets('a failed targets read shows a compact retryable face', (
      tester,
    ) async {
      final repository = await pumpTrash(
        tester,
        batches: <TrashBatchEntity>[fakeBatch(id: 'b1', name: 'a card')],
      );
      repository.targetsFailure = const DatabaseFailure(message: 'read lost');

      await tester.tap(find.byTooltip(english.trashRestoreAction));
      await tester.pumpAndSettle();

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.retryAction), findsOneWidget);
      expect(repository.restores, isEmpty);

      // The compact sheet must not balloon to the whole screen the moment
      // the read fails: the error face shrink-wraps inside a min Column.
      // Measured on the sheet itself, not the error widget: the error face
      // shrink-wraps whenever its Column parent exists, but only
      // `mainAxisSize: min` keeps the *sheet* from stretching to the loose
      // height — so this is the box that must stay small.
      final Size sheet = tester.getSize(find.byType(BottomSheet));
      final Size screen = tester.getSize(find.byType(MaterialApp));
      expect(
        sheet.height,
        lessThan(screen.height * 0.6),
        reason: 'the sheet hugs its content instead of filling the screen',
      );

      // Retry re-reads: heal the fake, tap, and the targets arrive.
      repository.targetsFailure = null;
      repository.targets = <TrashRestoreTarget>[
        const TrashDeckTarget(
          deckId: 'origin',
          name: 'Origin',
          parentName: 'Parent',
        ),
      ];
      await tester.tap(find.text(english.retryAction));
      await tester.pumpAndSettle();

      expect(find.byType(MxErrorState), findsNothing);
      expect(find.text('Origin'), findsOneWidget);
    });

    testWidgets('no eligible target shows why, with nothing to tap', (
      tester,
    ) async {
      await pumpTrash(
        tester,
        batches: <TrashBatchEntity>[fakeBatch(id: 'b1', name: 'a card')],
      );

      await tester.tap(find.byTooltip(english.trashRestoreAction));
      await tester.pumpAndSettle();

      expect(find.text(english.trashRestoreTargetEmpty), findsOneWidget);
      // No disabled rows: the picker draws only what would be accepted (T8).
      expect(find.text(english.trashRestoreConfirmAction), findsNothing);
    });

    testWidgets('the primary is inert until a target is chosen', (
      tester,
    ) async {
      // Two targets and no origin among them, so nothing is preselected. The
      // button used to be live and do nothing at all when tapped.
      await pumpTrash(
        tester,
        batches: <TrashBatchEntity>[
          fakeBatch(id: 'b1', name: 'a card', originDeckId: 'elsewhere'),
        ],
        targets: <TrashRestoreTarget>[
          const TrashDeckTarget(deckId: 'a', name: 'A', parentName: null),
          const TrashDeckTarget(deckId: 'b', name: 'B', parentName: null),
        ],
      );

      await tester.tap(find.byTooltip(english.trashRestoreAction));
      await tester.pumpAndSettle();

      final primary = tester.widget<MxActionButton>(
        find.widgetWithText(MxActionButton, english.trashRestoreConfirmAction),
      );
      expect(primary.onPressed, isNull);
    });

    testWidgets('a refusal is reported with its own reason', (tester) async {
      final repository = await pumpTrash(
        tester,
        batches: <TrashBatchEntity>[fakeBatch(id: 'b1', name: 'a card')],
        targets: <TrashRestoreTarget>[
          const TrashDeckTarget(
            deckId: 'origin',
            name: 'Origin',
            parentName: null,
          ),
        ],
      );
      repository.nextFailure = const ConflictFailure(
        message: 'diagnostic only',
        reason: TrashConflictReason.targetNoLongerValid,
      );

      await tester.tap(find.byTooltip(english.trashRestoreAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.trashRestoreConfirmAction));
      await tester.pumpAndSettle();

      // The reason, not `Failure.message`, which the UI must never render.
      expect(
        find.text(english.trashConflictTargetNoLongerValid),
        findsOneWidget,
      );
      expect(find.text('diagnostic only'), findsNothing);
    });
  });
}
