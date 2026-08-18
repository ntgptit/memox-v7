import 'dart:convert';

import '../../../../core/database/app_database.dart';
import '../../../deck/domain/entities/deck_entity.dart';
import '../../../deck/domain/models/deck_content_type_model.dart';
import '../../../deck/domain/models/scheduler_type_model.dart';
import '../../domain/entities/trash_batch_entity.dart';
import '../../domain/models/trash_item_type_model.dart';

/// Row → entity for Trash.
///
/// **A row that cannot be understood becomes null, not an exception.** Trash is
/// where a user goes when something has already gone wrong; a batch written by
/// a newer build, or one whose item root has vanished (invariant 35), must make
/// that row unreadable rather than make the screen uncloseable. The repository
/// drops the nulls.
TrashBatchEntity? trashBatchFromRow(TrashBatchRowsResult row) {
  final itemType = TrashItemType.fromDbValue(row.itemType);
  if (itemType == null) return null;

  final name = row.itemName;
  if (name == null) return null;

  return TrashBatchEntity(
    batchId: row.batchId,
    itemType: itemType,
    itemName: name,
    deletedAt: row.deletedAt,
    originDeckId: row.originDeckId,
    originDeckName: row.originDeckName,
    originPath: _pathFrom(row.originPathJson),
    deckCount: row.batchDeckCount,
    cardCount: row.batchCardCount,
  );
}

/// Decodes the ancestor chain and orders it **root first**.
///
/// `distance` rides inside each object rather than being implied by row order,
/// because SQLite promises nothing about the order `json_group_array` consumes
/// its input — the guarantee is made here, in Dart, where it is real. The same
/// deliberate hole `childDeckLevel.ancestryJson` opens, for the same reason.
///
/// A malformed or absent scalar reads as an empty path: the path is context
/// (BR-267), and a row worth restoring must not become unreadable because its
/// breadcrumb did.
List<TrashPathSegment> _pathFrom(String? json) {
  if (json == null || json.isEmpty) return const <TrashPathSegment>[];

  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    // Narrow, and ignorable on purpose: the path is decoration on a row whose
    // identity comes from columns that parsed fine.
    return const <TrashPathSegment>[];
  }
  if (decoded is! List) return const <TrashPathSegment>[];

  final segments = <({int distance, TrashPathSegment segment})>[];
  for (final entry in decoded) {
    if (entry is! Map<String, Object?>) continue;
    final id = entry['id'];
    final name = entry['name'];
    final distance = entry['distance'];
    if (id is! String || name is! String || distance is! int) continue;
    segments.add((
      distance: distance,
      segment: TrashPathSegment(deckId: id, name: name),
    ));
  }

  // Descending distance is root first: the furthest ancestor is the root.
  segments.sort((a, b) => b.distance.compareTo(a.distance));

  return List<TrashPathSegment>.unmodifiable(
    segments.map((entry) => entry.segment),
  );
}

/// Row → [DeckEntity], for the rules restore borrows from Deck's domain.
///
/// **A second mapper rather than an import.** `deck_mapper.dart` lives in the
/// Deck feature's `data/`, which no other feature may reach into (AD-13); the
/// *entity* is domain and shared. Mapping a row is data-layer work, so it
/// happens here, and the two mappers agreeing is what
/// `trash_restore_test.dart`'s scheduler and depth cases actually exercise.
DeckEntity trashDeckEntityFromRow(Deck row) => DeckEntity(
  id: row.id,
  name: row.name,
  parentDeckId: row.parentDeckId,
  rootDeckId: row.rootDeckId,
  contentType: DeckContentType.fromDbValue(row.contentType),
  schedulerType: row.schedulerType == null
      ? null
      : SchedulerType.fromDbValue(row.schedulerType!),
  schedulerGeneration: row.schedulerGeneration,
  firstAnsweredAt: row.firstAnsweredAt,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);
