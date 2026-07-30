import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/query_log_interceptor.dart';

/// The query log, driven through real SQLite.
///
/// A mocked executor would prove the interceptor forwards the calls it was
/// written to forward. What is actually in doubt is the *output*: whether a real
/// insert of a real card puts that card's text into the log. So the database is
/// real and the card content is deliberately unmistakable.
void main() {
  /// Content that would be impossible to miss in a log line.
  const String front = 'ほんやくする';
  const String back = 'to translate — private card content';

  late List<String> lines;

  AppDatabase openLoggedDatabase() {
    final db = AppDatabase(
      NativeDatabase.memory().interceptWith(
        QueryLogInterceptor(sink: lines.add),
      ),
    );
    addTearDown(db.close);

    return db;
  }

  Future<void> insertDeckAndCard(AppDatabase db) async {
    final now = DateTime.utc(2026, 7, 30, 12);

    await db.customInsert(
      'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
      'content_type, scheduler_type, scheduler_version, scheduler_generation, '
      'created_at, updated_at) '
      'VALUES (?, ?, NULL, ?, ?, ?, 1, 1, ?, ?)',
      variables: <Variable<Object>>[
        const Variable<String>('d1'),
        const Variable<String>('Japanese'),
        const Variable<String>('d1'),
        const Variable<String>('card'),
        const Variable<String>('eight_box'),
        Variable<DateTime>(now),
        Variable<DateTime>(now),
      ],
    );

    await db.customInsert(
      'INSERT INTO cards (id, deck_id, front, back, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      variables: <Variable<Object>>[
        const Variable<String>('c1'),
        const Variable<String>('d1'),
        const Variable<String>(front),
        const Variable<String>(back),
        Variable<DateTime>(now),
        Variable<DateTime>(now),
      ],
    );
  }

  setUp(() {
    lines = <String>[];
  });

  group('AD-08: card content never reaches the log', () {
    test('an insert logs the statement but not the arguments', () async {
      final db = openLoggedDatabase();

      await insertDeckAndCard(db);

      final log = lines.join('\n');
      // The rule this file exists for. `driftRuntimeOptions.debugPrint` would
      // fail exactly here, which is why it stays off.
      expect(log, isNot(contains(front)));
      expect(log, isNot(contains(back)));
      // The statement itself is present, with `?` where the content went.
      expect(log, contains('INSERT INTO cards'));
      expect(log, contains('?'));
    });

    test('a select logs the row count but not the rows', () async {
      final db = openLoggedDatabase();
      await insertDeckAndCard(db);
      lines.clear();

      final rows = await db
          .customSelect(
            'SELECT * FROM cards WHERE deck_id = ?',
            variables: <Variable<Object>>[const Variable<String>('d1')],
          )
          .get();

      expect(rows, hasLength(1));
      final log = lines.join('\n');
      expect(log, isNot(contains(front)));
      expect(log, isNot(contains(back)));
      expect(log, contains('1 rows'));
    });

    test('an update logs neither the old nor the new content', () async {
      final db = openLoggedDatabase();
      await insertDeckAndCard(db);
      lines.clear();

      await db.customUpdate(
        'UPDATE cards SET front = ? WHERE id = ?',
        variables: <Variable<Object>>[
          const Variable<String>('replacement content'),
          const Variable<String>('c1'),
        ],
        updates: <TableInfo<Table, dynamic>>{db.cards},
      );

      final log = lines.join('\n');
      expect(log, isNot(contains('replacement content')));
      expect(log, contains('1 updated'));
    });
  });

  group('what it does report', () {
    test('every statement, with an elapsed time', () async {
      final db = openLoggedDatabase();

      await insertDeckAndCard(db);

      // Two inserts, plus whatever opening the database ran.
      expect(
        lines.where((line) => line.contains('INSERT INTO cards')),
        hasLength(1),
      );
      expect(lines.every((line) => line.contains('us')), isTrue);
    });

    test('multi-line .drift SQL collapses to one greppable line', () async {
      final db = openLoggedDatabase();
      await insertDeckAndCard(db);
      lines.clear();

      await db
          .customSelect(
            'SELECT *\n  FROM cards\n  WHERE deck_id = ?',
            variables: <Variable<Object>>[const Variable<String>('d1')],
          )
          .get();

      expect(lines.single, contains('SELECT * FROM cards WHERE deck_id = ?'));
      expect(lines.single, isNot(contains('\n')));
    });

    test('but NOT the statements drift runs while opening', () async {
      // A limitation, asserted so that nobody spends an afternoon on it. Drift
      // runs `onCreate` and `beforeOpen` through its own opening executor, which
      // wraps the delegate underneath the interceptor — so `CREATE TABLE` and
      // `PRAGMA foreign_keys = ON` never reach this log even though they
      // certainly ran.
      //
      // Nothing is lost: `test/database/migration_test.dart` reads the pragma
      // back and asserts the table list, which is stronger evidence than a log
      // line anyway.
      final db = openLoggedDatabase();

      await db.customSelect('SELECT 1 AS one').getSingle();

      expect(lines, hasLength(1));
      expect(lines.single, contains('SELECT 1 AS one'));
      expect(lines.any((line) => line.contains('foreign_keys')), isFalse);
      expect(lines.any((line) => line.contains('CREATE TABLE')), isFalse);
    });

    test('a failing statement is not logged twice', () async {
      // The failure travels to the repository, which maps it to a `Failure`.
      // Logging it here as well would make one problem look like two.
      final db = openLoggedDatabase();
      await insertDeckAndCard(db);
      lines.clear();

      await expectLater(
        db.customInsert(
          'INSERT INTO cards (id, deck_id, front, back, created_at, '
          'updated_at) VALUES (?, ?, ?, ?, ?, ?)',
          variables: <Variable<Object>>[
            const Variable<String>('c1'), // duplicate primary key
            const Variable<String>('d1'),
            const Variable<String>(front),
            const Variable<String>(back),
            Variable<DateTime>(DateTime.utc(2026, 7, 30, 12)),
            Variable<DateTime>(DateTime.utc(2026, 7, 30, 12)),
          ],
        ),
        throwsA(isA<Exception>()),
      );

      expect(
        lines.where((line) => line.contains('INSERT INTO cards')),
        isEmpty,
      );
    });
  });
}
