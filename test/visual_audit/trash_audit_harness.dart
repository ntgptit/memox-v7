import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/domain/entities/trash_batch_entity.dart';
import 'package:memox/features/trash/domain/models/trash_item_type_model.dart';

import '../features/trash/presentation/support/fake_trash_repository.dart';

/// The instant every Trash audit renders at.
///
/// Fixed, and it has to be: every row shows "N days left" measured against the
/// clock (BR-190), so an audit that left it real would render a different
/// screen every day and no golden could tell that from a regression.
final DateTime kTrashAuditNow = DateTime.utc(2026, 8, 20, 9);

/// Wraps the Trash screen in a `ProviderScope` over a fake repository.
///
/// **No `MaterialApp` here** — `auditMemoxScreen` supplies one, with the theme
/// for the brightness it is testing. A second one would pin the screen to a
/// single theme and hide exactly the dark-mode drift the audit exists to catch.
Widget trashScreenWith(FakeTrashRepository repository, Widget screen) {
  return ProviderScope(
    overrides: [
      trashRepositoryProvider.overrideWithValue(repository),
      clockProvider.overrideWithValue(() => kTrashAuditNow),
    ],
    child: screen,
  );
}

/// One card and one deck, so the audit sees both row shapes and the deck row's
/// extra "N decks, N cards" line.
List<TrashBatchEntity> trashAuditBatches() => <TrashBatchEntity>[
  fakeBatch(
    id: 'card-1',
    name: 'give up',
    deletedAt: kTrashAuditNow.subtract(const Duration(days: 2)),
    originDeckName: 'Phrasal verbs',
    originPath: const <TrashPathSegment>[
      TrashPathSegment(deckId: 'english', name: 'English'),
      TrashPathSegment(deckId: 'grammar', name: 'Grammar'),
    ],
  ),
  fakeBatch(
    id: 'deck-1',
    name: 'Idioms',
    itemType: TrashItemType.deck,
    deletedAt: kTrashAuditNow.subtract(const Duration(days: 11)),
    originDeckName: 'Grammar',
    originPath: const <TrashPathSegment>[
      TrashPathSegment(deckId: 'english', name: 'English'),
    ],
    deckCount: 4,
    cardCount: 37,
  ),
];
