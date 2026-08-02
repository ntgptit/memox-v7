import '../../../../core/database/app_database.dart';
import '../../domain/entities/tag_entity.dart';

/// Maps a `tags` row to the domain entity. Only `id` and the display `name`
/// cross the boundary; `name_folded` and `owner_id` are the data layer's own —
/// the fold is how uniqueness is enforced, not something the domain compares.
TagEntity tagEntityFromRow(Tag row) => TagEntity(id: row.id, name: row.name);
