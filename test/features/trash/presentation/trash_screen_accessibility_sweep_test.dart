import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/domain/entities/trash_batch_entity.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'support/fake_trash_repository.dart';

/// A20.1 P2-17 — the trash screen under the accessibility guidelines.
void main() {
  final now = DateTime.utc(2026, 8, 15, 12);

  Future<void> pumpTrash(
    WidgetTester tester,
    List<TrashBatchEntity> batches,
  ) async {
    final repository = FakeTrashRepository(batches: batches);
    addTearDown(repository.dispose);
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
  }

  Future<void> sweep(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    // Contrast is deliberately not swept here: `textContrastGuideline`
    // samples rendered pixels, and on a 12px line most glyph pixels are only
    // partially covered — `settings_accessibility_test.dart` records it
    // reporting 1.35:1 on a pair that measures 7.0:1. Every ink this screen
    // writes in is measured from the tokens by the contrast suites under
    // `test/core/theme/`.
    handle.dispose();
  }

  testWidgets('empty', (tester) async {
    await pumpTrash(tester, const <TrashBatchEntity>[]);
    await sweep(tester);
  });

  testWidgets('with batches', (tester) async {
    await pumpTrash(tester, <TrashBatchEntity>[
      fakeBatch(id: 'b1', name: 'Korean'),
      fakeBatch(id: 'b2', name: 'apple'),
    ]);
    await sweep(tester);
  });
}
