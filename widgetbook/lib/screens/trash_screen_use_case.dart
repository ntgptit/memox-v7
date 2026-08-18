import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/domain/entities/trash_batch_entity.dart';
import 'package:memox/features/trash/domain/failures/trash_conflict_failure.dart';
import 'package:memox/features/trash/domain/models/trash_item_type_model.dart';
import 'package:memox/features/trash/domain/models/trash_restore_target_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:widgetbook/widgetbook.dart';

/// Trash (UC-21, M99.33), live.
///
/// The scenario knob stages what interaction alone cannot reach: an empty
/// Trash, a mixed list, a list where everything is about to expire, and a
/// restore that is refused. Everything else is real — pick rows, open the
/// target picker, read the purge confirmation.
///
/// **The clock is a knob because retention is the whole feature.** The rows
/// show "N days left" against an injected `now` (BR-264, AD-06), so a catalog
/// with the wall clock in it could never show the last day before a purge —
/// which is exactly the row worth looking at.
WidgetbookComponent trashScreenComponent() => WidgetbookComponent(
  name: 'TrashScreen',
  useCases: <WidgetbookUseCase>[
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) {
        final scenario = context.knobs.object.dropdown<TrashScenario>(
          label: 'scenario',
          options: TrashScenario.values,
          labelBuilder: (TrashScenario value) => value.label,
        );

        return _TrashDemo(
          key: ValueKey<TrashScenario>(scenario),
          scenario: scenario,
        );
      },
    ),
  ],
);

/// The states the catalog stages.
enum TrashScenario {
  mixed('Cards and decks'),
  cardsOnly('Cards only'),
  empty('Empty'),
  expiringToday('Expiring today'),
  restoreRefused('Restore refused');

  const TrashScenario(this.label);

  final String label;
}

class _TrashDemo extends StatelessWidget {
  const _TrashDemo({required this.scenario, super.key});

  final TrashScenario scenario;

  /// A fixed instant, so "N days left" is the same number on every reload and a
  /// screenshot means something.
  static final DateTime _now = DateTime.utc(2026, 8, 20, 9);

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      clockProvider.overrideWithValue(() => _now),
      trashRepositoryProvider.overrideWithValue(
        _CatalogTrashRepository(scenario: scenario, now: _now),
      ),
    ],
    child: const TrashScreen(),
  );
}

/// A repository that answers from the scenario and writes nothing.
final class _CatalogTrashRepository implements TrashRepository {
  _CatalogTrashRepository({required this.scenario, required this.now});

  final TrashScenario scenario;
  final DateTime now;

  @override
  Stream<List<TrashBatchEntity>> watchBatches() =>
      Stream<List<TrashBatchEntity>>.value(_batches());

  List<TrashBatchEntity> _batches() => switch (scenario) {
    TrashScenario.empty => const <TrashBatchEntity>[],
    TrashScenario.cardsOnly => <TrashBatchEntity>[
      _card('give up', daysAgo: 0),
      _card('look forward to', daysAgo: 4),
    ],
    TrashScenario.expiringToday => <TrashBatchEntity>[
      _card('run out of', daysAgo: 30),
      _deck('Idioms', daysAgo: 29),
    ],
    TrashScenario.mixed || TrashScenario.restoreRefused => <TrashBatchEntity>[
      _card('give up', daysAgo: 0),
      _deck('Phrasal verbs', daysAgo: 2, deckCount: 13, cardCount: 340),
      _card('look forward to', daysAgo: 11),
    ],
  };

  TrashBatchEntity _card(String name, {required int daysAgo}) =>
      TrashBatchEntity(
        batchId: 'card-$name',
        itemType: TrashItemType.card,
        itemName: name,
        deletedAt: now.subtract(Duration(days: daysAgo)),
        originDeckId: 'phrasal',
        originDeckName: 'Phrasal verbs',
        originPath: const <TrashPathSegment>[
          TrashPathSegment(deckId: 'english', name: 'English'),
          TrashPathSegment(deckId: 'grammar', name: 'Grammar'),
        ],
        deckCount: 0,
        cardCount: 1,
      );

  TrashBatchEntity _deck(
    String name, {
    required int daysAgo,
    int deckCount = 1,
    int cardCount = 0,
  }) => TrashBatchEntity(
    batchId: 'deck-$name',
    itemType: TrashItemType.deck,
    itemName: name,
    deletedAt: now.subtract(Duration(days: daysAgo)),
    originDeckId: 'grammar',
    originDeckName: 'Grammar',
    originPath: const <TrashPathSegment>[
      TrashPathSegment(deckId: 'english', name: 'English'),
    ],
    deckCount: deckCount,
    cardCount: cardCount,
  );

  @override
  Future<TrashBatchEntity> batch(String batchId) async =>
      _batches().firstWhere((batch) => batch.batchId == batchId);

  @override
  Stream<List<TrashRestoreTarget>> watchRestoreTargets(String batchId) =>
      Stream<List<TrashRestoreTarget>>.value(<TrashRestoreTarget>[
        const TrashDeckTarget(
          deckId: 'phrasal',
          name: 'Phrasal verbs',
          parentName: 'Grammar',
        ),
        const TrashDeckTarget(
          deckId: 'unit-2',
          name: 'Unit 2',
          parentName: 'Beginner',
        ),
      ]);

  @override
  Future<void> restore({
    required String batchId,
    required TrashRestoreTarget target,
  }) async {
    if (scenario != TrashScenario.restoreRefused) return;

    throw const ConflictFailure(
      message: 'catalog scenario',
      reason: TrashConflictReason.targetNoLongerValid,
    );
  }

  @override
  Future<void> undo(String batchId) async {}

  @override
  Future<void> purge(List<String> batchIds) async {}

  @override
  Future<int> purgeExpired(DateTime now) async => 0;
}
