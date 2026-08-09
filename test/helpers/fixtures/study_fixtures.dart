/// The scenario fixtures the IT catalog names, built directly on a test
/// database (§13 of the pyramid refactor).
///
/// **Named after the catalog's `Chuẩn bị` codes on purpose.** A scenario row
/// says `S-DUE`; the test that proves it calls [sDue]. One name, two places,
/// no translation step — and when a fixture changes shape there is exactly one
/// definition to change.
///
/// **This is what unblocked `FIXTURE-BLOCKED`.** Forty-two scenarios were held
/// because "an approved fixture does not exist yet", and the guide forbids an
/// agent from writing to the database to fake one. That rule is right *for a
/// device*: a fixture with no artifact path and no version is not reproducible,
/// and the next run is not the same run. It was never a rule for a host test,
/// which creates its own in-memory database, fills it, asserts, and throws it
/// away inside one `test()`. Nothing here touches a machine anyone uses.
///
/// **Deterministic, and that is not a style choice.** Every instant is derived
/// from [testNow] and every id is fixed, so a fixture is the same on the tenth
/// run as on the first. A fixture built from `DateTime.now()` produces tests
/// that pass all day and fail at midnight.
library;

import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

import '../../database/support/test_database.dart';

/// The reference instant every fixture is built around.
///
/// Re-exported so a test never has to know which file `testNow` lives in — and
/// so nothing is tempted to declare a second one.
DateTime get fixtureNow => testNow;

/// One day, as the study day counts it.
const Duration oneDay = Duration(days: 1);

/// A root deck holding one card deck holding [cardCount] cards.
///
/// The shape almost every study fixture needs, and the shape BR-58/59 forces: a
/// root holds only sub-decks, so cards live one level down. Returns the ids in
/// insertion order so a caller can address a specific card.
Future<StudyFixture> deckWithCards(
  AppDatabase db, {
  required int cardCount,
  String rootId = 'root',
  String deckId = 'deck',
  String scheduler = 'eight_box',
}) async {
  await insertRootDeck(db, id: rootId, schedulerType: scheduler);
  await insertSubDeck(
    db,
    id: deckId,
    parentId: rootId,
    rootDeckId: rootId,
    contentType: 'card',
  );

  final cardIds = <String>[];
  for (var i = 0; i < cardCount; i++) {
    final id = 'card-$i';
    await insertCard(
      db,
      id: id,
      deckId: deckId,
      // Distinct fronts *and* distinct backs: `guess` refuses two options that
      // fold to the same meaning (BR-123), and a fixture whose cards all say
      // "back" would make every question unbuildable for reasons that have
      // nothing to do with the scenario under test.
      front: 'front-$i',
      back: 'back-$i',
    );
    cardIds.add(id);
  }

  return StudyFixture(rootId: rootId, deckId: deckId, cardIds: cardIds);
}

/// What a fixture hands back: the ids a test needs to address what it built.
class StudyFixture {
  const StudyFixture({
    required this.rootId,
    required this.deckId,
    required this.cardIds,
  });

  final String rootId;
  final String deckId;
  final List<String> cardIds;
}

/// Marks [cardIds] as learned and due at [dueAt].
///
/// **`learned_at` travels with `due_at`** (BR-90, BR-149). A card with a
/// schedule finished the learning chain; one without did not. Splitting the two
/// is how a fixture ends up describing a state the app cannot produce — and it
/// is exactly the drift that broke the integration suite once already.
Future<void> makeLearned(
  AppDatabase db,
  Iterable<String> cardIds, {
  required DateTime dueAt,
  DateTime? learnedAt,
  String scheduler = 'eight_box',
  int generation = 1,
  int? box,
  double? easeFactor,
  int? intervalDays,
  int? repetitions,
}) async {
  for (final cardId in cardIds) {
    await insertReviewState(
      db,
      cardId: cardId,
      dueAt: dueAt,
      learnedAt: learnedAt ?? dueAt,
      schedulerType: scheduler,
      schedulerGeneration: generation,
    );
    if (box == null &&
        easeFactor == null &&
        intervalDays == null &&
        repetitions == null) {
      continue;
    }
    await _setSchedulerColumns(
      db,
      cardId: cardId,
      box: box,
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      repetitions: repetitions,
    );
  }
}

/// The per-scheduler columns, written after the shared row exists.
///
/// Separate from [insertReviewState] rather than folded into it: that helper is
/// shared with the invariant tests, and every one of them would have to learn
/// two schedulers' worth of parameters it does not use.
Future<void> _setSchedulerColumns(
  AppDatabase db, {
  required String cardId,
  int? box,
  double? easeFactor,
  int? intervalDays,
  int? repetitions,
}) async {
  await db.customUpdate(
    'UPDATE card_study_states SET current_box = ?, ease_factor = ?, '
    'interval_days = ?, repetitions = ? WHERE card_id = ?',
    variables: <Variable<Object>>[
      if (box == null) const Variable<int>(null) else Variable<int>(box),
      if (easeFactor == null)
        const Variable<double>(null)
      else
        Variable<double>(easeFactor),
      if (intervalDays == null)
        const Variable<int>(null)
      else
        Variable<int>(intervalDays),
      if (repetitions == null)
        const Variable<int>(null)
      else
        Variable<int>(repetitions),
      Variable<String>(cardId),
    ],
  );
}

/// Queues [cardIds] for one stage of a session, in the order given.
///
/// `position` is the order the round serves them (BR-23, BR-117) and is
/// immutable once written — so a fixture that wants a particular order states
/// it here rather than hoping a shuffle produces it.
Future<void> queueStage(
  AppDatabase db, {
  required String sessionId,
  required String mode,
  required List<String> cardIds,
  int round = 1,
  String status = 'pending',
}) async {
  for (final (index, cardId) in cardIds.indexed) {
    await db.customInsert(
      'INSERT INTO study_queue_items (session_id, mode, round, card_id, '
      'position, status, available_at, answers_in_session) '
      'VALUES (?, ?, ?, ?, ?, ?, 0, 0)',
      variables: <Variable<Object>>[
        Variable<String>(sessionId),
        Variable<String>(mode),
        Variable<int>(round),
        Variable<String>(cardId),
        Variable<int>(index),
        Variable<String>(status),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// The catalog's named fixtures.
// ---------------------------------------------------------------------------

/// `S-DUE` — one deck holding three states at once: due, not yet due, and new.
///
/// The set every discovery and filter scenario needs, because the interesting
/// part of a due predicate is the boundary between the three, not any one of
/// them.
Future<StudyFixture> sDue(AppDatabase db) async {
  final fixture = await deckWithCards(db, cardCount: 6);

  // Two overdue, one due at exactly `now` — the boundary BR-22 includes — two
  // due tomorrow, and one left new.
  await makeLearned(
    db,
    fixture.cardIds.take(2),
    dueAt: fixtureNow.subtract(oneDay),
    box: 3,
  );
  await makeLearned(
    db,
    <String>[fixture.cardIds[2]],
    dueAt: fixtureNow,
    box: 4,
  );
  await makeLearned(
    db,
    fixture.cardIds.skip(3).take(2),
    dueAt: fixtureNow.add(oneDay),
    box: 5,
  );

  return fixture;
}

/// `S-PROGRESS` — a deck spread across the four card states a progress panel
/// reports (BR-89, BR-90, BR-91).
Future<StudyFixture> sProgress(AppDatabase db) async {
  final fixture = await deckWithCards(db, cardCount: 8);

  // `new` is the absence of a row, so two cards get nothing at all.
  await makeLearned(
    db,
    fixture.cardIds.skip(2).take(2),
    dueAt: fixtureNow.add(oneDay),
    box: 1,
  );
  await makeLearned(
    db,
    fixture.cardIds.skip(4).take(2),
    dueAt: fixtureNow.add(oneDay * 3),
    box: 4,
  );
  await makeLearned(
    db,
    fixture.cardIds.skip(6).take(2),
    dueAt: fixtureNow.add(oneDay * 30),
    box: 8,
  );

  return fixture;
}

/// `S-STUDY-REVIEW-EB-V2` — an Eight Box deck whose cards are all learned and
/// all due, which is what a review session needs to exist at all (BR-142).
Future<StudyFixture> sStudyReviewEightBox(
  AppDatabase db, {
  int cardCount = 5,
}) async {
  final fixture = await deckWithCards(db, cardCount: cardCount);
  await makeLearned(
    db,
    fixture.cardIds,
    dueAt: fixtureNow.subtract(oneDay),
    box: 2,
  );

  return fixture;
}

/// `S-STUDY-REVIEW-SM2-V2` — the same, on the other scheduler, with the SM-2
/// columns actually filled so an update has something to move.
Future<StudyFixture> sStudyReviewSm2(
  AppDatabase db, {
  int cardCount = 5,
}) async {
  final fixture = await deckWithCards(
    db,
    cardCount: cardCount,
    scheduler: 'sm2',
  );
  await makeLearned(
    db,
    fixture.cardIds,
    dueAt: fixtureNow.subtract(oneDay),
    scheduler: 'sm2',
    easeFactor: 2.5,
    intervalDays: 1,
    repetitions: 1,
  );

  return fixture;
}

/// `S-STUDY-MIXED-EB-V2` — new and due cards in one deck, which is the case
/// BR-142 keeps apart: a session takes one set, never both.
Future<StudyFixture> sStudyMixedEightBox(AppDatabase db) async {
  final fixture = await deckWithCards(db, cardCount: 8);
  await makeLearned(
    db,
    fixture.cardIds.take(3),
    dueAt: fixtureNow.subtract(oneDay),
    box: 2,
  );

  return fixture;
}

/// `S-STUDY-FUTURE-EB-V2` — everything learned, nothing due. The state that
/// must read as ordinary rather than as an error, and must not let anyone study
/// ahead (BR-29, BR-145).
Future<StudyFixture> sStudyFutureEightBox(AppDatabase db) async {
  final fixture = await deckWithCards(db, cardCount: 4);
  await makeLearned(
    db,
    fixture.cardIds,
    dueAt: fixtureNow.add(oneDay * 2),
    box: 5,
  );

  return fixture;
}

/// `S-STUDY-RESUME-V2` — a session left in progress with a queue behind it, so
/// resuming has something to resume to (BR-102, BR-103).
Future<({StudyFixture fixture, String sessionId})> sStudyResume(
  AppDatabase db, {
  String sessionId = 'session-resume',
  int answered = 2,
}) async {
  final fixture = await sStudyReviewEightBox(db);
  await insertSession(
    db,
    id: sessionId,
    deckId: fixture.deckId,
    rootDeckId: fixture.rootId,
  );
  await queueStage(
    db,
    sessionId: sessionId,
    mode: 'self_assess',
    cardIds: fixture.cardIds,
  );
  for (final cardId in fixture.cardIds.take(answered)) {
    await db.customUpdate(
      "UPDATE study_queue_items SET status = 'completed' "
      'WHERE session_id = ? AND card_id = ?',
      variables: <Variable<Object>>[
        Variable<String>(sessionId),
        Variable<String>(cardId),
      ],
    );
  }

  return (fixture: fixture, sessionId: sessionId);
}
