import '../../../../core/database/app_database.dart';
import '../../domain/entities/card_entity.dart';

/// Maps a `cards` row to the domain entity. Content only — no schedule field
/// exists on either side of this mapping (BR-10).
CardEntity cardEntityFromRow(Card row) => CardEntity(
  id: row.id,
  deckId: row.deckId,
  front: row.front,
  back: row.back,
  createdAt: row.createdAt.toUtc(),
  updatedAt: row.updatedAt.toUtc(),
);
