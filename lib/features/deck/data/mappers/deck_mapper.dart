import 'dart:convert';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/time/local_day_model.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/models/deck_content_type_model.dart';
import '../../domain/models/deck_list_snapshot_model.dart';
import '../../domain/models/deck_path_segment_model.dart';
import '../../domain/models/deck_summary_model.dart';
import '../../domain/models/scheduler_type_model.dart';

/// Maps a `decks` row to the domain entity.
///
/// The row is read tolerantly: an enum value this build has never seen maps to
/// `unknown` instead of crashing every list screen (the write direction fails
/// fast — see `SchedulerType.dbValue`). Timestamps come back in UTC, which is how
/// they were written and the only zone `due_at` maths is safe in.
DeckEntity deckEntityFromRow(Deck row) {
  final schedulerType = row.schedulerType;

  return DeckEntity(
    id: row.id,
    name: row.name,
    parentDeckId: row.parentDeckId,
    rootDeckId: row.rootDeckId,
    contentType: DeckContentType.fromDbValue(row.contentType),
    schedulerType: schedulerType == null
        ? null
        : SchedulerType.fromDbValue(schedulerType),
    schedulerGeneration: row.schedulerGeneration,
    firstAnsweredAt: row.firstAnsweredAt?.toUtc(),
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );
}

/// The root level: every root deck, and no parent.
///
/// The counts stop being SQL here: nothing above this line sees a
/// `RootDeckSummariesResult`, which is what keeps the aggregate replaceable
/// without touching presentation (AD-01).
///
/// A root's scheduler is its own column — it is the deck the rule attaches to
/// (BR-06), so there is nothing to resolve.
///
/// `nextDueAt` is the same scalar on every row: one subquery, evaluated once by
/// SQLite and repeated across the join, so reading it off the first row is not a
/// guess about which row to trust. No rows means no root decks, which means no
/// cards anywhere (a card's deck is a foreign key), which means nothing can become
/// due — so `null` there is the truth and not a missing value.
///
/// `.toUtc()` because drift reads a stored `DateTime` back through
/// `DateTime.fromMillisecondsSinceEpoch`, which produces a **local** value for the
/// right instant. The instant is correct either way, but a local `DateTime` in a
/// domain model breaks equality against the UTC values everything else uses.
DeckListSnapshot rootLevelFromRows(
  List<RootDeckSummariesResult> rows, {
  required DateTime now,
  required Duration utcOffset,
}) {
  final day = LocalDayModel(now: now, utcOffset: utcOffset);
  final decks = <DeckSummary>[
    for (final RootDeckSummariesResult row in rows)
      DeckSummary(
        deck: deckEntityFromRow(row.d),
        totalCardCount: row.totalCardCount,
        newCardCount: row.newCardCount,
        dueCardCount: row.dueCardCount,
        overdueCardCount: overdueCountOf(
          dueCardCount: row.dueCardCount,
          overdueCardCount: row.overdueCardCount,
        ),
        overdueDayCount: overdueDaysOf(
          day,
          dueCardCount: row.dueCardCount,
          oldestDueAt: row.oldestDueAt,
        ),
        learnedCardCount: row.learnedCardCount,
        subDeckCount: row.subDeckCount,
        schedulerType: SchedulerType.fromDbValue(row.d.schedulerType ?? ''),
      ),
  ];

  return DeckListSnapshot(
    parent: null,
    // The root level is the top: there is nothing above it to name.
    ancestors: const <DeckPathSegment>[],
    decks: decks,
    nextDueAt: rows.isEmpty ? null : rows.first.nextDueAt?.toUtc(),
    nextOverdueTickAt: overdueTickOf(day, decks),
  );
}

/// One deck and what is directly inside it, each child carrying its subtree's
/// aggregate.
///
/// The `LEFT JOIN` gives one row per child, or a single row with a null `child`
/// when there are none — so the two cases the screen must not confuse are
/// distinguishable here:
///
/// * **no rows at all** — the deck does not exist, which surfaces as
///   [NotFoundFailure]. The screen renders a way back, not a retry (UC-03 E1).
/// * **one row, `child` null** — the deck exists and is empty, so it renders
///   its empty state. Emptying it also unset its `content_type` inside the same
///   transaction that removed the last child (BR-163); nothing is offered here.
///
/// `rows.first.parent` is the same deck in every row by construction: the join is
/// keyed on `parent.id = :parentId`.
///
/// The scheduler comes from the row's `inheritedSchedulerType`, which the query
/// read from the child's **root**. A sub-deck's own column is NULL by rule (BR-06),
/// so using it would leave every deck below the first level with no study mode on
/// screen — which is exactly the kind of blank the unified list exists to remove.
DeckListSnapshot childLevelFromRows(
  List<ChildDeckLevelResult> rows, {
  required DateTime now,
  required Duration utcOffset,
}) {
  if (rows.isEmpty) {
    throw const NotFoundFailure(message: 'That deck no longer exists.');
  }

  final day = LocalDayModel(now: now, utcOffset: utcOffset);
  final decks = <DeckSummary>[
    for (final ChildDeckLevelResult row in rows)
      if (row.child case final Deck child)
        DeckSummary(
          deck: deckEntityFromRow(child),
          totalCardCount: row.totalCardCount,
          newCardCount: row.newCardCount,
          dueCardCount: row.dueCardCount,
          overdueCardCount: overdueCountOf(
            dueCardCount: row.dueCardCount,
            overdueCardCount: row.overdueCardCount,
          ),
          overdueDayCount: overdueDaysOf(
            day,
            dueCardCount: row.dueCardCount,
            oldestDueAt: row.oldestDueAt,
          ),
          learnedCardCount: row.learnedCardCount,
          subDeckCount: row.subDeckCount,
          schedulerType: SchedulerType.fromDbValue(
            row.inheritedSchedulerType ?? '',
          ),
        ),
  ];

  return DeckListSnapshot(
    parent: deckEntityFromRow(rows.first.parent),
    ancestors: deckPathFromJson(rows.first.ancestryJson),
    decks: decks,
    nextDueAt: rows.first.nextDueAt?.toUtc(),
    nextOverdueTickAt: overdueTickOf(day, decks),
  );
}

/// The badge's day count for one row (BR-161).
///
/// **Zero without due cards, and never silent about a broken aggregate.** The
/// query computes `oldestDueAt` in the same grouped pass as `dueCardCount`, so
/// a positive count with no instant cannot come from production SQL — only
/// from a hand-built fixture that skipped half the aggregate. Inventing a
/// zero for it would render a healthy-looking deck over an inconsistent read.
int overdueDaysOf(
  LocalDayModel day, {
  required int dueCardCount,
  required DateTime? oldestDueAt,
}) {
  if (dueCardCount == 0) return 0;
  if (oldestDueAt == null) {
    throw StateError(
      'dueCardCount is $dueCardCount but the aggregate carried no '
      'oldestDueAt — the two come from one grouped subquery, so this read '
      'is inconsistent.',
    );
  }

  return day.completedDaysSince(oldestDueAt.toUtc());
}

/// The overdue half of the due partition, checked at the boundary (BR-162).
///
/// The query counts both halves in one grouped pass, so production SQL cannot
/// return an overdue count outside `[0, dueCardCount]` — only a hand-built
/// fixture that set the two independently can, and letting it through would
/// hand the hero a negative "due today" to render.
int overdueCountOf({required int dueCardCount, required int overdueCardCount}) {
  if (overdueCardCount < 0 || overdueCardCount > dueCardCount) {
    throw StateError(
      'overdueCardCount is $overdueCardCount against dueCardCount '
      '$dueCardCount — the two are one partition from one grouped subquery, '
      'so this read is inconsistent.',
    );
  }

  return overdueCardCount;
}

/// When this level's overdue badges next move: local midnight, if anything is
/// due at all (BR-161).
DateTime? overdueTickOf(LocalDayModel day, List<DeckSummary> decks) =>
    decks.any((DeckSummary summary) => summary.dueCardCount > 0)
    ? day.startOfTomorrow
    : null;

/// The ancestor chain, decoded from the one JSON column `childDeckLevel` returns.
///
/// **This is the only untyped column in the deck reads, and it stops here.** The
/// query's own comment explains why the alternatives (a join that multiplies rows,
/// or a compound select drift silently mis-compiles) are worse. What matters at
/// this boundary is that the string never escapes it: everything above the
/// repository receives `List<DeckPathSegment>` or nothing.
///
/// **Total, not throwing.** A breadcrumb is chrome. If this column is ever
/// malformed — a schema change, a SQLite build without JSON1, a corrupt row — the
/// right outcome is a screen with no breadcrumb, not a deck the user can no longer
/// open. The counts, the rows and the title in the same read are unaffected by
/// whatever went wrong here, so failing the whole level would throw away nine
/// correct facts to punish one.
///
/// Sorted by `distance` **descending** — the furthest ancestor is the root, and
/// the path reads downwards from it. The sort is done here rather than in SQL
/// because SQLite does not promise the order an aggregate consumes its input, so
/// the column's order is not a guarantee to lean on.
List<DeckPathSegment> deckPathFromJson(String encoded) {
  final Object? decoded = _tryDecode(encoded);
  if (decoded is! List) return const <DeckPathSegment>[];

  final entries = <({int distance, DeckPathSegment segment})>[];
  for (final Object? element in decoded) {
    if (element is! Map<String, Object?>) continue;
    final Object? id = element['id'];
    final Object? name = element['name'];
    final Object? distance = element['distance'];
    if (id is! String || name is! String || distance is! int) continue;

    entries.add((
      distance: distance,
      segment: DeckPathSegment(id: id, name: name),
    ));
  }

  entries.sort((a, b) => b.distance.compareTo(a.distance));

  return <DeckPathSegment>[for (final entry in entries) entry.segment];
}

/// `jsonDecode` throws on malformed input, and this is the one place that is a
/// recoverable state rather than a bug — see [deckPathFromJson]. Caught narrowly:
/// a `FormatException` is the documented failure, and anything else is not.
Object? _tryDecode(String encoded) {
  try {
    return jsonDecode(encoded);
  } on FormatException {
    return null;
  }
}
