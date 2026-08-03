import 'dart:convert';

import '../../../../core/database/app_database.dart';
import '../../domain/models/deck_context_model.dart';

/// Builds the card list header's [DeckContextModel] from a `deckContextById` row.
///
/// The name comes straight off the row; the ancestry is a JSON scalar decoded
/// here so the string never escapes the boundary (AD-01).
DeckContextModel deckContextFromRow(DeckContextByIdResult row) =>
    DeckContextModel(
      deckName: row.deckName,
      ancestors: _ancestorsFromJson(row.ancestryJson),
    );

/// Decodes the ancestry JSON into breadcrumb segments, **root first**.
///
/// **Total, not throwing.** A breadcrumb is chrome. A malformed or absent scalar
/// — a SQLite build without JSON1, a corrupt row — yields no crumbs rather than a
/// card list the user can no longer open; the name and the rows in the same read
/// are unaffected.
///
/// Sorted by `distance` descending because the furthest ancestor is the root and
/// SQLite does not promise the order an aggregate consumes its input. Mirrors the
/// deck feature's `deckPathFromJson` without importing it (AD-13).
List<DeckBreadcrumbSegment> _ancestorsFromJson(String? encoded) {
  if (encoded == null) return const <DeckBreadcrumbSegment>[];
  final Object? decoded = _tryDecode(encoded);
  if (decoded is! List) return const <DeckBreadcrumbSegment>[];

  final entries = <({int distance, DeckBreadcrumbSegment segment})>[];
  for (final Object? element in decoded) {
    if (element is! Map<String, Object?>) continue;
    final Object? id = element['id'];
    final Object? name = element['name'];
    final Object? distance = element['distance'];
    if (id is! String || name is! String || distance is! int) continue;

    entries.add((
      distance: distance,
      segment: DeckBreadcrumbSegment(id: id, name: name),
    ));
  }

  entries.sort((a, b) => b.distance.compareTo(a.distance));

  return <DeckBreadcrumbSegment>[for (final entry in entries) entry.segment];
}

/// `jsonDecode` throws on malformed input, and this is the one place that is a
/// recoverable state rather than a bug. Caught narrowly: a `FormatException` is
/// the documented failure, and anything else is not.
Object? _tryDecode(String encoded) {
  try {
    return jsonDecode(encoded);
  } on FormatException {
    return null;
  }
}
