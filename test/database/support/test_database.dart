import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/query_log_interceptor.dart';

/// A real SQLite database, in memory, one per test.
///
/// Not a mock. Everything these tests are for — `ON DELETE CASCADE`, the foreign
/// key pragma, a `WITH RECURSIVE` cycle check, the exact NULL semantics of the
/// due predicate — is behaviour of SQLite itself. A mocked executor would assert
/// that the code calls the API it was written to call, which is the one thing
/// nobody doubts.
///
/// In memory, and torn down per test, so nothing can leak between them and no
/// file survives the run.
/// [log], when given, receives one line per statement — the production
/// [QueryLogInterceptor], used here for what it can prove rather than for what
/// it prints. "This read does not scale with the number of rows" is a claim
/// about how many statements ran, and it is invisible to any assertion on the
/// *result*: a repository that issued one query per card returns exactly the
/// same records as one that issued a single query, so a test written against
/// the records alone passes either way and pins nothing.
AppDatabase openTestDatabase({QueryLogSink? log}) {
  final executor = NativeDatabase.memory();
  final db = AppDatabase(
    log == null
        ? executor
        : executor.interceptWith(QueryLogInterceptor(sink: log)),
  );
  addTearDown(db.close);

  return db;
}

/// A fixed instant. Tests never read the wall clock.
///
/// `now` is a parameter everywhere it matters, so a boundary case — a card due
/// at exactly this instant — can actually be constructed. A query that reads the
/// SQL clock itself cannot be tested at its boundary at all.
final DateTime testNow = DateTime.utc(2026, 7, 29, 12);

/// Inserts a root deck. Roots carry the scheduler; sub-decks leave it NULL.
Future<String> insertRootDeck(
  AppDatabase db, {
  required String id,
  String contentType = 'deck',
  String? schedulerType = 'eight_box',
  int? schedulerGeneration = 1,
  String? rootDeckId,
}) async {
  await db.customInsert(
    'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, content_type, '
    'scheduler_type, scheduler_version, scheduler_generation, created_at, '
    'updated_at) VALUES (?, ?, NULL, ?, ?, ?, ?, ?, ?, ?)',
    variables: <Variable<Object>>[
      Variable<String>(id),
      Variable<String>('deck $id'),
      Variable<String>(rootDeckId ?? id),
      Variable<String>(contentType),
      if (schedulerType == null)
        const Variable<String>(null)
      else
        Variable<String>(schedulerType),
      const Variable<int>(1),
      if (schedulerGeneration == null)
        const Variable<int>(null)
      else
        Variable<int>(schedulerGeneration),
      Variable<DateTime>(testNow),
      Variable<DateTime>(testNow),
    ],
  );

  return id;
}

/// Inserts a sub-deck. Scheduler columns stay NULL by default (BR-06).
Future<String> insertSubDeck(
  AppDatabase db, {
  required String id,
  required String parentId,
  required String rootDeckId,
  String contentType = 'unset',
  String? schedulerType,
  int? schedulerGeneration,
}) async {
  await db.customInsert(
    'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, content_type, '
    'scheduler_type, scheduler_generation, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    variables: <Variable<Object>>[
      Variable<String>(id),
      Variable<String>('deck $id'),
      Variable<String>(parentId),
      Variable<String>(rootDeckId),
      Variable<String>(contentType),
      if (schedulerType == null)
        const Variable<String>(null)
      else
        Variable<String>(schedulerType),
      if (schedulerGeneration == null)
        const Variable<int>(null)
      else
        Variable<int>(schedulerGeneration),
      Variable<DateTime>(testNow),
      Variable<DateTime>(testNow),
    ],
  );

  return id;
}

Future<String> insertCard(
  AppDatabase db, {
  required String id,
  required String deckId,
  String? front,
  String? back,
}) async {
  // ** is written, not left to its default.** BR-123 measures two
  // meanings as different by the folded form, so a fixture whose cards all fold
  // to the empty string makes every `guess` question unbuildable — for a reason
  // that has nothing to do with the scenario under test.
  final backText = back ?? 'back $id';
  await db.customInsert(
    'INSERT INTO cards (id, deck_id, front, back, back_folded, created_at, '
    'updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
    variables: <Variable<Object>>[
      Variable<String>(id),
      Variable<String>(deckId),
      Variable<String>(front ?? 'front $id'),
      Variable<String>(backText),
      Variable<String>(backText.trim().toLowerCase()),
      Variable<DateTime>(testNow),
      Variable<DateTime>(testNow),
    ],
  );

  return id;
}

/// Creates the study state that BR-09 says is born with the card.
Future<void> insertReviewState(
  AppDatabase db, {
  required String cardId,
  DateTime? dueAt,
  DateTime? learnedAt,
  String schedulerType = 'eight_box',
  int schedulerGeneration = 1,
}) async {
  // `learned_at` travels with `due_at` (BR-149). Deriving it here rather than
  // taking a second argument is what keeps every fixture on the right side of
  // invariants 24 and 28 without each caller having to remember: a card with a
  // schedule finished the chain, and a card without one did not.
  await db.customInsert(
    'INSERT INTO card_study_states (card_id, scheduler_type, '
    'scheduler_version, scheduler_generation, learned_at, due_at) '
    'VALUES (?, ?, 1, ?, ?, ?)',
    variables: <Variable<Object>>[
      Variable<String>(cardId),
      Variable<String>(schedulerType),
      Variable<int>(schedulerGeneration),
      if (dueAt == null)
        const Variable<DateTime>(null)
      else
        Variable<DateTime>(learnedAt ?? dueAt),
      if (dueAt == null)
        const Variable<DateTime>(null)
      else
        Variable<DateTime>(dueAt),
    ],
  );
}

Future<void> insertSession(
  AppDatabase db, {
  required String id,
  required String deckId,
  required String rootDeckId,
  String status = 'in_progress',
  String? endReason,
  DateTime? endedAt,

  // Defaulted rather than required: every caller here is testing something
  // else — a cascade, an invariant, a tree read — and making them all name a
  // session kind would be ceremony that hides which one actually cares.
  String sessionKind = 'reviewing',
  String currentMode = 'self_assess',
  int cardLimit = 20,
}) async {
  await db.customInsert(
    'INSERT INTO study_sessions (id, deck_id, root_deck_id, '
    'scheduler_generation, status, end_reason, session_kind, current_mode, '
    'cursor, card_limit, started_at, ended_at) '
    'VALUES (?, ?, ?, 1, ?, ?, ?, ?, 0, ?, ?, ?)',
    variables: <Variable<Object>>[
      Variable<String>(id),
      Variable<String>(deckId),
      Variable<String>(rootDeckId),
      Variable<String>(status),
      if (endReason == null)
        const Variable<String>(null)
      else
        Variable<String>(endReason),
      Variable<String>(sessionKind),
      Variable<String>(currentMode),
      Variable<int>(cardLimit),
      Variable<DateTime>(testNow),
      if (endedAt == null)
        const Variable<DateTime>(null)
      else
        Variable<DateTime>(endedAt),
    ],
  );
}

Future<void> insertHistory(
  AppDatabase db, {
  required String id,
  required String cardId,
  required String sessionId,
  String kind = 'scheduled',

  // `self_assess` is the default because it is the one mode that predates the
  // column: every history row written before v5 was one (BR-98).
  String mode = 'self_assess',
  int? previousBox = 1,
  int? nextBox = 2,
}) async {
  await db.customInsert(
    'INSERT INTO study_answers (id, card_id, session_id, scheduler_type, '
    'scheduler_generation, kind, mode, action, answered_at, previous_box, '
    'next_box) VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?)',
    variables: <Variable<Object>>[
      Variable<String>(id),
      Variable<String>(cardId),
      Variable<String>(sessionId),
      const Variable<String>('eight_box'),
      Variable<String>(kind),
      Variable<String>(mode),
      const Variable<String>('remembered'),
      Variable<DateTime>(testNow),
      if (previousBox == null)
        const Variable<int>(null)
      else
        Variable<int>(previousBox),
      if (nextBox == null)
        const Variable<int>(null)
      else
        Variable<int>(nextBox),
    ],
  );
}

/// Rows returned by an invariant query. Empty means the data is clean.
Future<List<String>> violations(AppDatabase db, String sql) async {
  final rows = await db.customSelect(sql).get();

  return rows.map((row) => row.data.values.first.toString()).toList();
}
