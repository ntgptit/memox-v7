import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'support/test_database.dart';

/// Writes database files for `check_docs.sh --db` to run against.
///
/// The script's job is to check a **real** database, so the fixture has to be
/// built by the production schema rather than typed out in the script. Two are
/// written: one clean, one with a single planted violation, because a checker
/// that has only ever been pointed at valid data has never been shown to say no.
///
/// Both land under `build/`, which is already ignored, and both are recreated on
/// every run.
void main() {
  const cleanPath = 'build/invariant_fixture_clean.db';
  const dirtyPath = 'build/invariant_fixture_dirty.db';

  Future<AppDatabase> openAt(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    if (file.existsSync()) file.deleteSync();

    return AppDatabase(NativeDatabase(file));
  }

  Future<void> seedValidTree(AppDatabase db) async {
    await insertRootDeck(db, id: 'root');
    await insertSubDeck(
      db,
      id: 'branch',
      parentId: 'root',
      rootDeckId: 'root',
      contentType: 'deck',
    );
    await insertSubDeck(
      db,
      id: 'leaf',
      parentId: 'branch',
      rootDeckId: 'root',
      contentType: 'card',
    );
    await insertCard(db, id: 'card-1', deckId: 'leaf');
    await insertReviewState(db, cardId: 'card-1');
    await insertSession(
      db,
      id: 'session-1',
      deckId: 'root',
      rootDeckId: 'root',
      status: 'completed',
      endedAt: testNow,
    );
    await insertHistory(
      db,
      id: 'history-1',
      cardId: 'card-1',
      sessionId: 'session-1',
    );
  }

  test('writes a clean fixture database', () async {
    final db = await openAt(cleanPath);
    await seedValidTree(db);
    await db.close();

    expect(File(cleanPath).existsSync(), isTrue);
  });

  test('writes a fixture with exactly one planted violation', () async {
    // A sub-deck carrying scheduler columns (BR-06, Q10) — one of the four the
    // script used to omit, so this doubles as proof they now run.
    final db = await openAt(dirtyPath);
    await seedValidTree(db);
    await db.customStatement(
      "UPDATE decks SET scheduler_type = 'sm2' WHERE id = 'branch'",
    );
    await db.close();

    expect(File(dirtyPath).existsSync(), isTrue);
  });
}
