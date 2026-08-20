// Plausible decks and summaries, so a test states only what it cares about.
//
// Split from `fake_deck_repository.dart` at the file-size guard. They were
// together because both are test support; they are apart because one is a
// contract double and the other is data.

import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

/// A root deck with plausible values, so a test states only what it cares about.
///
/// The timestamps are a fixed instant rather than the wall clock: a test that
/// depends on when it runs is the classic suite that fails once a month at
/// midnight.
DeckEntity fakeRootDeck({
  required String id,
  required String name,
  SchedulerType schedulerType = SchedulerType.eightBox,
  int schedulerGeneration = 1,
  DeckContentType contentType = DeckContentType.deck,
  DateTime? createdAt,
}) {
  final at = createdAt ?? DateTime.utc(2026);

  return DeckEntity(
    id: id,
    name: name,
    parentDeckId: null,
    rootDeckId: id,
    contentType: contentType,
    schedulerType: schedulerType,
    schedulerGeneration: schedulerGeneration,
    firstAnsweredAt: null,
    createdAt: at,
    updatedAt: at,
  );
}

/// A sub-deck. Scheduler columns are null, as BR-06 requires of anything that is
/// not a root.
DeckEntity fakeSubDeck({
  required String id,
  required String name,
  required String parentId,
  String? rootId,
  DeckContentType contentType = DeckContentType.unset,
  DateTime? createdAt,
}) {
  final at = createdAt ?? DateTime.utc(2026);

  return DeckEntity(
    id: id,
    name: name,
    parentDeckId: parentId,
    rootDeckId: rootId ?? parentId,
    contentType: contentType,
    schedulerType: null,
    schedulerGeneration: null,
    firstAnsweredAt: null,
    createdAt: at,
    updatedAt: at,
  );
}

/// The list read's snapshot, for a test that drives the stream directly.
///
/// [nextDueAt] defaults to null — nothing scheduled to come due — because that is
/// what most tests are about. The ones about the due-boundary timer pass it.
DeckListSnapshot fakeListSnapshot(
  List<DeckSummary> summaries, {
  DeckEntity? parent,
  List<DeckPathSegment> ancestors = const <DeckPathSegment>[],
  DateTime? nextDueAt,
  DateTime? nextOverdueTickAt,
}) => DeckListSnapshot(
  parent: parent,
  ancestors: ancestors,
  decks: summaries,
  nextDueAt: nextDueAt,
  nextOverdueTickAt: nextOverdueTickAt,
);

/// An ancestor chain from names alone, ordered root first.
///
/// The ids are positional — `path-0` is the root — because nothing in the
/// breadcrumb cares what they are beyond being distinct and navigable, and a test
/// that had to invent nine uuids to assert a path would bury the one thing it is
/// checking. Positional rather than derived from the name, so a name with a space
/// in it does not turn into a percent-encoded route in the assertion.
List<DeckPathSegment> fakePath(List<String> names) => <DeckPathSegment>[
  for (final (int index, String name) in names.indexed)
    DeckPathSegment(id: 'path-$index', name: name),
];

/// A root deck's summary with explicit counts.
DeckSummary fakeSummary({
  required String id,
  required String name,
  int totalCardCount = 0,
  int newCardCount = 0,
  int dueCardCount = 0,
  int overdueCardCount = 0,
  int overdueDayCount = 0,
  int learnedCardCount = 0,
  int subDeckCount = 0,
  SchedulerType schedulerType = SchedulerType.eightBox,
  DeckContentType contentType = DeckContentType.deck,
  DateTime? createdAt,
}) => DeckSummary(
  deck: fakeRootDeck(
    id: id,
    name: name,
    contentType: contentType,
    schedulerType: schedulerType,
    createdAt: createdAt,
  ),
  totalCardCount: totalCardCount,
  newCardCount: newCardCount,
  dueCardCount: dueCardCount,
  overdueCardCount: overdueCardCount,
  overdueDayCount: overdueDayCount,
  learnedCardCount: learnedCardCount,
  subDeckCount: subDeckCount,
  schedulerType: schedulerType,
);

/// A sub-deck's summary — the same three facts a root's carries.
///
/// The scheduler is passed separately from the entity on purpose: a sub-deck's
/// own column is null by BR-06, and the value here is the one the query resolved
/// through `root_deck_id`. A helper that read it off the entity would quietly
/// make every child summary in the suite say "unknown".
DeckSummary fakeChildSummary({
  required String id,
  required String name,
  required String parentId,
  String? rootId,
  int totalCardCount = 0,
  int newCardCount = 0,
  int dueCardCount = 0,
  int overdueCardCount = 0,
  int overdueDayCount = 0,
  int learnedCardCount = 0,
  int subDeckCount = 0,
  SchedulerType schedulerType = SchedulerType.eightBox,
  DeckContentType contentType = DeckContentType.unset,
  DateTime? createdAt,
}) => DeckSummary(
  deck: fakeSubDeck(
    id: id,
    name: name,
    parentId: parentId,
    rootId: rootId,
    contentType: contentType,
    createdAt: createdAt,
  ),
  totalCardCount: totalCardCount,
  newCardCount: newCardCount,
  dueCardCount: dueCardCount,
  overdueCardCount: overdueCardCount,
  overdueDayCount: overdueDayCount,
  learnedCardCount: learnedCardCount,
  subDeckCount: subDeckCount,
  schedulerType: schedulerType,
);
