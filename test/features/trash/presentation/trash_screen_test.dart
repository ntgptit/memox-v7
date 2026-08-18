import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/domain/entities/trash_batch_entity.dart';
import 'package:memox/features/trash/domain/failures/trash_conflict_failure.dart';
import 'package:memox/features/trash/domain/models/trash_item_type_model.dart';
import 'package:memox/features/trash/domain/models/trash_restore_target_model.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/fake_trash_repository.dart';

/// The Trash screen's state matrix (UC-21 UI states).
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

  group('the list', () {
    testWidgets('empty says what Trash is for', (tester) async {
      await pumpTrash(tester, batches: const <TrashBatchEntity>[]);

      expect(find.text(english.trashEmptyTitle), findsOneWidget);
      expect(find.text(english.trashEmptyMessage), findsOneWidget);
    });

    testWidgets('the sweep runs before the first emission (BR-264)', (
      tester,
    ) async {
      // Opening Trash is one of BR-264's three triggers, and it lives in the
      // provider rather than in the screen precisely so a test can see it.
      final repository = await pumpTrash(
        tester,
        batches: const <TrashBatchEntity>[],
      );

      expect(repository.sweeps, 1);
    });

    testWidgets('a row names the item, the age and the time left', (
      tester,
    ) async {
      await pumpTrash(
        tester,
        batches: <TrashBatchEntity>[
          fakeBatch(
            id: 'b1',
            name: 'give up',
            deletedAt: DateTime.utc(2026, 8, 13, 12),
          ),
        ],
      );

      expect(find.text('give up'), findsOneWidget);
      expect(
        find.text(english.trashDeletedDaysAgo(2), skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text(english.trashDaysLeft(28)), findsOneWidget);
    });

    testWidgets('the origin path reads as context, not as a destination', (
      tester,
    ) async {
      await pumpTrash(
        tester,
        batches: <TrashBatchEntity>[
          fakeBatch(
            id: 'b1',
            originDeckName: 'Phrasal verbs',
            originPath: const <TrashPathSegment>[
              TrashPathSegment(deckId: 'r', name: 'English'),
              TrashPathSegment(deckId: 'g', name: 'Grammar'),
            ],
          ),
        ],
      );

      // One line, prefixed and with no tap target of its own (BR-267, T5).
      expect(
        find.textContaining('English › Grammar › Phrasal verbs'),
        findsOneWidget,
      );
    });

    testWidgets('the Cards filter hides deck rows', (tester) async {
      await pumpTrash(
        tester,
        batches: <TrashBatchEntity>[
          fakeBatch(id: 'card', name: 'a card'),
          fakeBatch(
            id: 'deck',
            name: 'a deck',
            itemType: TrashItemType.deck,
            deckCount: 2,
            cardCount: 3,
          ),
        ],
      );

      await tester.tap(find.text(english.trashFilterCards));
      await tester.pumpAndSettle();

      expect(find.text('a card'), findsOneWidget);
      expect(find.text('a deck'), findsNothing);
    });

    testWidgets('a filter with nothing in it has its own empty state', (
      tester,
    ) async {
      await pumpTrash(
        tester,
        batches: <TrashBatchEntity>[fakeBatch(id: 'card', name: 'a card')],
      );

      await tester.tap(find.text(english.trashFilterDecks));
      await tester.pumpAndSettle();

      expect(find.text(english.trashEmptyDecksMessage), findsOneWidget);
    });
  });

  group('selection (BR-266)', () {
    Future<FakeTrashRepository> pumpMixed(WidgetTester tester) => pumpTrash(
      tester,
      batches: <TrashBatchEntity>[
        fakeBatch(id: 'card', name: 'a card'),
        fakeBatch(
          id: 'deck',
          name: 'a deck',
          itemType: TrashItemType.deck,
          deckCount: 1,
          cardCount: 0,
        ),
      ],
    );

    testWidgets('selecting a card locks the selection to cards', (
      tester,
    ) async {
      await pumpMixed(tester);

      await tester.longPress(find.text('a card'));
      await tester.pumpAndSettle();

      // The bar explains the restriction rather than leaving the user to
      // discover it by being refused at submit.
      expect(find.text(english.trashSelectionCardsOnly), findsOneWidget);

      await tester.longPress(find.text('a deck'));
      await tester.pumpAndSettle();

      // Still one selected: the deck row does not respond at all.
      expect(find.text(english.trashSelectionCardsOnly), findsOneWidget);
      expect(find.text(english.trashSelectionCount(2)), findsNothing);
    });

    testWidgets('permanent delete asks with the exact count', (tester) async {
      final repository = await pumpMixed(tester);

      await tester.longPress(find.text('a card'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.trashPurgeAction).last);
      await tester.pumpAndSettle();

      expect(find.text(english.trashPurgeConfirmTitle(1)), findsOneWidget);
      expect(find.text(english.trashPurgeConfirmMessage), findsOneWidget);

      // Cancel is the safe default, and cancelling writes nothing.
      await tester.tap(find.text(english.trashPurgeCancelAction));
      await tester.pumpAndSettle();
      expect(repository.purges, isEmpty);
    });

    testWidgets('a row narrates once: the composed sentence, not every '
        'fact again (R5)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTrash(
        tester,
        batches: <TrashBatchEntity>[fakeBatch(id: 'b1', name: 'a card')],
      );

      // The body's Texts are not semantics boundaries, so without the
      // ExcludeSemantics they merge INTO the row's container node — the node
      // count stays one, but its label grows every body line joined with
      // newlines. The mutation-holding assertion is therefore on the label's
      // content: the composed single sentence, and nothing appended.
      final SemanticsNode row = tester.getSemantics(
        find.bySemanticsLabel(RegExp('a card')),
      );
      expect(
        row.label,
        isNot(contains('\n')),
        reason:
            'the row narrates one composed sentence; a newline means a body '
            'Text merged in behind it',
      );
      expect(row.label, startsWith('a card, '));
      // The two per-row controls stay outside the exclusion, independently
      // findable and actionable.
      expect(find.bySemanticsLabel(english.trashRestoreAction), findsOneWidget);
      expect(find.bySemanticsLabel(english.trashRowMenuTitle), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a row purge costs one tap more than Restore: kebab, menu, '
        'then the dialog (T6)', (tester) async {
      final repository = await pumpMixed(tester);

      // The kebab opens a menu — it never fires the purge directly. The
      // rescue action stays cheaper than the destructive one.
      await tester.tap(find.bySemanticsLabel(english.trashRowMenuTitle).first);
      await tester.pumpAndSettle();
      expect(repository.purges, isEmpty);
      expect(find.text(english.trashRowMenuTitle), findsOneWidget);

      await tester.tap(find.text(english.trashPurgeAction).last);
      await tester.pumpAndSettle();
      expect(find.text(english.trashPurgeConfirmTitle(1)), findsOneWidget);

      await tester.tap(find.text(english.trashPurgeConfirmAction).last);
      await tester.pumpAndSettle();
      expect(repository.purges, hasLength(1));
    });

    testWidgets('confirming the dialog purges exactly the selection', (
      tester,
    ) async {
      final repository = await pumpMixed(tester);

      await tester.longPress(find.text('a card'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.trashPurgeAction).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.trashPurgeConfirmAction).last);
      await tester.pumpAndSettle();

      expect(repository.purges, <List<String>>[
        <String>['card'],
      ]);
      // **A purge says it purged.** One shared listener over three commands
      // once announced "Restored" here — on the single path in the app that
      // cannot be undone.
      expect(find.text(english.trashPurgedMessage(1)), findsOneWidget);
      expect(find.text(english.trashRestoredMessage), findsNothing);
    });

    testWidgets('Select turns the mode on without a long press', (
      tester,
    ) async {
      // Long press is not a discoverable affordance and is not reachable from a
      // keyboard, which is the channel the web E2E suite drives (AD-04).
      await pumpMixed(tester);

      await tester.tap(find.bySemanticsLabel(english.trashSelectAction));
      await tester.pumpAndSettle();

      expect(find.text(english.trashSelectionCardsOnly), findsOneWidget);
    });
  });

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
