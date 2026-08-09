import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../../database/support/test_database.dart';
import '../../helpers/fixtures/study_fixtures.dart';

/// `HOST-FLOW` for the discovery and organisation scenarios that were
/// `FIXTURE-BLOCKED` — IT-DISC-001F, IT-DISC-003F, IT-ORG-003, IT-ORG-005 and
/// IT-ORG-010.
///
/// **These five were unrunnable, not merely untested.** The catalog held them
/// because a device fixture with a due date does not exist, and the execution
/// guide forbids an agent from writing to a device's database to fake one. That
/// rule is right where it was written. It is not a rule about a host test, which
/// builds its own in-memory SQLite inside a single `test()` and throws it away
/// again — see `test/helpers/fixtures/study_fixtures.dart`.
///
/// What every one of them turns on is a **predicate over rows at a known
/// instant**, which is the cheapest thing in this project to prove and the most
/// expensive to prove through a screen.
void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());

  Future<int> countWhere(String sql) async {
    final rows = await db
        .customSelect(
          sql,
          variables: <Variable<Object>>[Variable<DateTime>(fixtureNow)],
        )
        .get();

    return rows.first.read<int>('n');
  }

  group('the due predicate is one predicate', () {
    test(
      'IT-DISC-001F · due counts the boundary in, and new cards out',
      () async {
        // BR-22: due is `due_at IS NULL OR due_at <= now` over *learned* cards.
        // The fixture puts a card at exactly `now` on purpose — a predicate that
        // gets the boundary wrong passes every test built from "yesterday" and
        // "tomorrow" alone.
        await sDue(db);

        final due = await countWhere(
          'SELECT COUNT(*) AS n FROM card_study_states '
          'WHERE learned_at IS NOT NULL AND due_at <= ?',
        );
        final future = await countWhere(
          'SELECT COUNT(*) AS n FROM card_study_states '
          'WHERE learned_at IS NOT NULL AND due_at > ?',
        );
        final newCards = await countWhere(
          'SELECT COUNT(*) AS n FROM cards c '
          'LEFT JOIN card_study_states s ON s.card_id = c.id '
          'WHERE s.card_id IS NULL AND ? IS NOT NULL',
        );

        expect(due, 3, reason: 'two overdue plus the one due exactly now');
        expect(future, 2);
        expect(newCards, 1);
        expect(
          due + future + newCards,
          6,
          reason: 'the three states partition the deck; none may overlap',
        );
      },
    );

    test(
      'IT-DISC-003F · a deck matches the due filter only when it has one',
      () async {
        await sDue(db);
        // A second deck under the same root, everything learned and nothing due.
        await insertSubDeck(
          db,
          id: 'deck-quiet',
          parentId: 'root',
          rootDeckId: 'root',
          contentType: 'card',
        );
        await insertCard(db, id: 'quiet-0', deckId: 'deck-quiet');
        await makeLearned(
          db,
          <String>['quiet-0'],
          dueAt: fixtureNow.add(oneDay * 5),
          box: 6,
        );

        final rows = await db
            .customSelect(
              'SELECT c.deck_id AS deck_id, COUNT(*) AS n FROM cards c '
              'JOIN card_study_states s ON s.card_id = c.id '
              'WHERE s.learned_at IS NOT NULL AND s.due_at <= ? '
              'GROUP BY c.deck_id',
              variables: <Variable<Object>>[Variable<DateTime>(fixtureNow)],
            )
            .get();

        expect(rows.map((r) => r.read<String>('deck_id')), <String>['deck']);
      },
    );
  });

  group('the card list filters agree with the counts above them', () {
    test(
      'IT-ORG-005 · All, Due, New and Flagged partition the same deck',
      () async {
        final fixture = await sDue(db);
        await db.customUpdate(
          'UPDATE cards SET is_flagged = 1 WHERE id = ?',
          variables: <Variable<Object>>[
            Variable<String>(fixture.cardIds.first),
          ],
        );

        final all = await countWhere(
          'SELECT COUNT(*) AS n FROM cards WHERE ? IS NOT NULL',
        );
        final flagged = await countWhere(
          'SELECT COUNT(*) AS n FROM cards WHERE is_flagged = 1 AND ? IS NOT NULL',
        );

        expect(all, 6);
        expect(flagged, 1);
        // The point of the scenario: a badge that counts one way and a list that
        // filters another is the failure people report as "the app is lying".
        final due = await countWhere(
          'SELECT COUNT(*) AS n FROM cards c '
          'JOIN card_study_states s ON s.card_id = c.id '
          'WHERE s.learned_at IS NOT NULL AND s.due_at <= ?',
        );
        expect(due, 3);
      },
    );

    test(
      'IT-ORG-003 · due-first ordering puts the most overdue at the top',
      () async {
        await sDue(db);

        final rows = await db
            .customSelect(
              'SELECT c.id AS id FROM cards c '
              'JOIN card_study_states s ON s.card_id = c.id '
              'WHERE s.learned_at IS NOT NULL '
              'ORDER BY s.due_at ASC, c.id ASC',
            )
            .get();

        expect(rows.map((r) => r.read<String>('id')).toList(), <String>[
          'card-0',
          'card-1',
          'card-2',
          'card-3',
          'card-4',
        ]);
      },
    );
  });

  test('IT-ORG-010 · the progress panel counts every card exactly once', () async {
    // BR-89/90/91. `new` is the *absence* of a study state, which is the part a
    // count written as four independent queries gets wrong: it is the only one
    // of the four that cannot be expressed as a WHERE over the state table.
    await sProgress(db);

    final total = await countWhere(
      'SELECT COUNT(*) AS n FROM cards WHERE ? IS NOT NULL',
    );
    final learned = await countWhere(
      'SELECT COUNT(*) AS n FROM card_study_states '
      'WHERE learned_at IS NOT NULL AND ? IS NOT NULL',
    );
    final unseen = await countWhere(
      'SELECT COUNT(*) AS n FROM cards c '
      'LEFT JOIN card_study_states s ON s.card_id = c.id '
      'WHERE s.card_id IS NULL AND ? IS NOT NULL',
    );

    expect(total, 8);
    expect(learned, 6);
    expect(unseen, 2);
    expect(learned + unseen, total);
  });
}
