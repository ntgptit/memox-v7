import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/drift_error_mapper.dart';
import 'package:memox/core/error/failure.dart';

/// The mapper against exceptions SQLite actually threw.
///
/// `failure_test.dart` covers the shapes as hand-written `Exception` objects,
/// which exercises the text fallback. This file provokes the real thing, because
/// the production path reads `SqliteException.extendedResultCode` and a
/// hand-written exception has none — so the two files cover two different halves
/// and neither is redundant.
///
/// Why the distinction is worth this much test: all three constraint kinds put the
/// literal `constraint failed` in their message, so the text they share cannot
/// separate the one the user can act on from the two they cannot. The codes can.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
  });

  final DateTime now = DateTime.utc(2026, 7, 30, 12);

  Future<void> insertRootDeck(String id) => db.customInsert(
    'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, content_type, '
    'scheduler_type, scheduler_version, scheduler_generation, created_at, '
    "updated_at) VALUES (?, 'deck', NULL, ?, 'card', 'eight_box', 1, 1, ?, ?)",
    variables: <Variable<Object>>[
      Variable<String>(id),
      Variable<String>(id),
      Variable<DateTime>(now),
      Variable<DateTime>(now),
    ],
  );

  /// Runs [write], expecting it to fail, and maps whatever it threw.
  Future<Failure> failureFrom(Future<void> Function() write) async {
    try {
      await write();
    } on Object catch (error) {
      return mapDatabaseError(error);
    }

    fail('the write was expected to violate a constraint');
  }

  test('a duplicate primary key is a conflict the user can act on', () async {
    // Extended code 1555. The repositories check for an existing row first, so
    // this only arrives on a race — and a race on uniqueness is the one case
    // where "choose a different name" is real advice.
    await insertRootDeck('r1');

    final failure = await failureFrom(() => insertRootDeck('r1'));

    expect(failure, isA<ConflictFailure>());
  });

  test('a foreign key violation is a missing row, not a conflict', () async {
    // Extended code 787. The parent was checked and then vanished, so the
    // truthful answer is that it is gone. This used to map to ConflictFailure
    // and told the user to pick a different value for a deck that no longer
    // existed.
    final failure = await failureFrom(
      () => db.customInsert(
        'INSERT INTO cards (id, deck_id, front, back, created_at, updated_at) '
        "VALUES ('c1', 'no-such-deck', 'f', 'b', ?, ?)",
        variables: <Variable<Object>>[
          Variable<DateTime>(now),
          Variable<DateTime>(now),
        ],
      ),
    );

    expect(failure, isA<NotFoundFailure>());
  });

  test('a NOT NULL violation is our defect, not a conflict', () async {
    // Extended code 1299. Every column is written from a typed source, so this
    // cannot be caused by anything the user did — and it must not produce advice
    // they can follow.
    await insertRootDeck('r2');

    final failure = await failureFrom(
      () => db.customInsert(
        'INSERT INTO cards (id, deck_id, front, back, created_at, updated_at) '
        "VALUES ('c2', 'r2', NULL, 'b', ?, ?)",
        variables: <Variable<Object>>[
          Variable<DateTime>(now),
          Variable<DateTime>(now),
        ],
      ),
    );

    expect(failure, isA<DatabaseFailure>());
  });

  test('a CHECK violation is our defect too', () async {
    // The schema has ten CHECK constraints holding enum columns to their allowed
    // values. Writing outside them means a Dart enum and a SQL check disagree,
    // which is a build-time mistake surfacing at runtime.
    final failure = await failureFrom(
      () => db.customInsert(
        'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
        'content_type, scheduler_version, created_at, updated_at) '
        "VALUES ('r3', 'deck', NULL, 'r3', 'not-a-content-type', 1, ?, ?)",
        variables: <Variable<Object>>[
          Variable<DateTime>(now),
          Variable<DateTime>(now),
        ],
      ),
    );

    expect(failure, isA<DatabaseFailure>());
  });

  test('a statement error is not a constraint violation at all', () async {
    // Result code 1, not 19. It must not be read as a constraint of any kind —
    // the check is on the primary code precisely so this cannot be.
    final failure = await failureFrom(
      () => db.customSelect('SELECT no_such_column FROM decks').get(),
    );

    expect(failure, isA<DatabaseFailure>());
  });

  group('no SQLite detail survives the boundary', () {
    test('the message names no table, column or exception class', () async {
      // The reason the mapper throws the text away: SQLite says
      // `UNIQUE constraint failed: decks.id`, which is a schema leak, and
      // `Failure.message` is safe to log.
      await insertRootDeck('r4');

      final failure = await failureFrom(() => insertRootDeck('r4'));

      expect(failure.message, isNot(contains('decks')));
      expect(failure.message, isNot(contains('SqliteException')));
      expect(failure.message, isNot(contains('1555')));
      expect(failure.message, isNot(contains('constraint')));
    });

    test('but the original survives in cause, for the log', () async {
      await insertRootDeck('r5');

      final failure = await failureFrom(() => insertRootDeck('r5'));

      // `isA<Exception>` rather than `isNotNull`: drift exports its own
      // `isNotNull` for SQL expressions and it shadows matcher's.
      expect(failure.cause, isA<Exception>());
      expect(failure.cause.toString(), contains('constraint'));
    });
  });
}
