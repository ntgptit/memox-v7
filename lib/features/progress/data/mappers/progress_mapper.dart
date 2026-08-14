import 'dart:convert';

import '../../../../core/database/app_database.dart';
import '../../../../core/time/local_day_model.dart';
import '../../domain/models/deck_activity_metrics_model.dart';
import '../../domain/models/deck_activity_model.dart';
import '../../domain/models/deck_activity_snapshot_model.dart';
import '../../domain/models/progress_path_segment_model.dart';

/// The top level: every root deck, and the totals across all of them.
///
/// The aggregates stop being SQL here — nothing above this line sees a
/// `RootDeckActivityResult`, which is what keeps the statement replaceable
/// without touching `presentation/` (AD-01).
///
/// **No rows means no root decks**, which means no cards (a card's deck is a
/// foreign key) and therefore no answers: the empty snapshot with zero totals is
/// the truth here, not a missing value.
///
/// The scope totals are the same figures on every row — one uncorrelated
/// subquery, evaluated once by SQLite and repeated across the join — so reading
/// them off the first row is not a guess about which row to trust.
DeckActivitySnapshot rootActivityFromRows(
  List<RootDeckActivityResult> rows, {
  required LocalDayModel day,
}) {
  if (rows.isEmpty) {
    return DeckActivitySnapshot(
      scopeDeckId: null,
      scopeName: null,
      scopePath: const <ProgressPathSegment>[],
      decks: const <DeckActivity>[],
      scopeLast7Days: DeckActivityMetrics.zero,
      scopeLast30Days: DeckActivityMetrics.zero,
      nextDayBoundaryAt: day.startOfTomorrow,
    );
  }

  final first = rows.first;

  return DeckActivitySnapshot(
    scopeDeckId: null,
    scopeName: null,
    scopePath: const <ProgressPathSegment>[],
    decks: <DeckActivity>[
      for (final RootDeckActivityResult row in rows)
        DeckActivity(
          deckId: row.deckId,
          name: row.deckName,
          // A root deck has no ancestors, so its path is empty rather than
          // absent: the row renders its name and nothing above it.
          path: const <ProgressPathSegment>[],
          last7Days: DeckActivityMetrics(
            activeCardCount: row.activeCards7,
            activeDayCount: row.activeDays7,
            learningCardDayCount: row.learningCardDays7,
            reviewingCardDayCount: row.reviewingCardDays7,
          ),
          last30Days: DeckActivityMetrics(
            activeCardCount: row.activeCards30,
            activeDayCount: row.activeDays30,
            learningCardDayCount: row.learningCardDays30,
            reviewingCardDayCount: row.reviewingCardDays30,
          ),
        ),
    ],
    scopeLast7Days: DeckActivityMetrics(
      activeCardCount: first.scopeActiveCards7,
      activeDayCount: first.scopeActiveDays7,
      learningCardDayCount: first.scopeLearningCardDays7,
      reviewingCardDayCount: first.scopeReviewingCardDays7,
    ),
    scopeLast30Days: DeckActivityMetrics(
      activeCardCount: first.scopeActiveCards30,
      activeDayCount: first.scopeActiveDays30,
      learningCardDayCount: first.scopeLearningCardDays30,
      reviewingCardDayCount: first.scopeReviewingCardDays30,
    ),
    nextDayBoundaryAt: day.startOfTomorrow,
  );
}

/// One deck's level: the deck's own totals, and a row per direct child.
///
/// **A childless deck yields exactly one row with a null child**, which is what
/// keeps "nothing inside this deck" distinguishable from "this deck is gone" —
/// the latter produces no rows at all and the repository refuses it.
///
/// Each child's path is the scope's own path plus the scope itself, computed
/// once here rather than repeated per row in SQL. It is arithmetic over one
/// result set, not a second read.
DeckActivitySnapshot childActivityFromRows(
  List<ChildDeckActivityResult> rows, {
  required LocalDayModel day,
}) {
  final first = rows.first;
  final scopePath = progressPathFromJson(first.ancestryJson);
  final childPath = <ProgressPathSegment>[
    ...scopePath,
    ProgressPathSegment(id: first.scopeDeckId, name: first.scopeDeckName),
  ];

  return DeckActivitySnapshot(
    scopeDeckId: first.scopeDeckId,
    scopeName: first.scopeDeckName,
    scopePath: scopePath,
    decks: <DeckActivity>[
      for (final ChildDeckActivityResult row in rows)
        if (row.childDeckId != null && row.childDeckName != null)
          DeckActivity(
            deckId: row.childDeckId!,
            name: row.childDeckName!,
            path: childPath,
            last7Days: DeckActivityMetrics(
              activeCardCount: row.activeCards7,
              activeDayCount: row.activeDays7,
              learningCardDayCount: row.learningCardDays7,
              reviewingCardDayCount: row.reviewingCardDays7,
            ),
            last30Days: DeckActivityMetrics(
              activeCardCount: row.activeCards30,
              activeDayCount: row.activeDays30,
              learningCardDayCount: row.learningCardDays30,
              reviewingCardDayCount: row.reviewingCardDays30,
            ),
          ),
    ],
    scopeLast7Days: DeckActivityMetrics(
      activeCardCount: first.scopeActiveCards7,
      activeDayCount: first.scopeActiveDays7,
      learningCardDayCount: first.scopeLearningCardDays7,
      reviewingCardDayCount: first.scopeReviewingCardDays7,
    ),
    scopeLast30Days: DeckActivityMetrics(
      activeCardCount: first.scopeActiveCards30,
      activeDayCount: first.scopeActiveDays30,
      learningCardDayCount: first.scopeLearningCardDays30,
      reviewingCardDayCount: first.scopeReviewingCardDays30,
    ),
    nextDayBoundaryAt: day.startOfTomorrow,
  );
}

/// The ancestor chain, decoded from the one JSON column `childDeckActivity`
/// returns — the same shape and the same reasoning as `deckPathFromJson`.
///
/// **Total, not throwing.** A path is context. If the column is ever malformed —
/// a SQLite build without JSON1, a corrupt row — the right outcome is a level
/// with no path above it, not a level the user cannot open. The figures in the
/// same read are unaffected by whatever went wrong here, and failing the level
/// would discard every correct fact to punish one.
///
/// Sorted by `distance` **descending**, so the furthest ancestor — the root —
/// comes first and the path reads downwards. Sorted here rather than in SQL
/// because SQLite does not promise the order an aggregate consumes its input.
List<ProgressPathSegment> progressPathFromJson(String encoded) {
  final Object? decoded = _tryDecode(encoded);
  if (decoded is! List) return const <ProgressPathSegment>[];

  final entries = <({int distance, ProgressPathSegment segment})>[];
  for (final Object? element in decoded) {
    if (element is! Map<String, Object?>) continue;
    final Object? id = element['id'];
    final Object? name = element['name'];
    final Object? distance = element['distance'];
    if (id is! String || name is! String || distance is! int) continue;

    entries.add((
      distance: distance,
      segment: ProgressPathSegment(id: id, name: name),
    ));
  }

  entries.sort((a, b) => b.distance.compareTo(a.distance));

  return <ProgressPathSegment>[for (final entry in entries) entry.segment];
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
