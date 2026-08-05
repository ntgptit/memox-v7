import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/domain/repositories/deck_template_repository.dart';
import 'package:memox/features/deck/domain/usecases/install_deck_templates_use_case.dart';

import '../database/invariant_queries.dart';
import '../database/support/test_database.dart';
import 'seed.dart';

/// The seed helper, run against a real database with the app's real assets.
///
/// This is the acceptance check M4.12 asks for in test form: the app is
/// demoable without anyone editing a database by hand, loading twice does not
/// duplicate anything, and every data invariant holds afterwards.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  var idCounter = 0;

  setUp(() {
    db = openTestDatabase();
    idCounter = 0;
  });

  tearDown(() => db.close());

  Future<DeckTemplateInstallReport> seed() => seedFixtureDecks(
    db,
    clock: () => testNow,
    idGenerator: () => 'seed-${++idCounter}',
  );

  Future<int> count(String sql) async =>
      (await db.customSelect(sql).getSingle()).read<int>('c');

  test('one pass fills an empty database from the shipped assets', () async {
    final report = await seed();

    expect(report.length, 2);
    expect(
      report.map((entry) => entry.outcome),
      everyElement(DeckTemplateInstallOutcome.installed),
    );
    // One root per template: an `eight_box` tree and an `sm2` tree, which is
    // what makes a demo able to show both action sets.
    expect(
      await count(
        'SELECT COUNT(*) AS c FROM decks WHERE parent_deck_id IS NULL',
      ),
      2,
    );
    expect(
      await count(
        "SELECT COUNT(DISTINCT scheduler_type) AS c FROM decks "
        'WHERE parent_deck_id IS NULL',
      ),
      2,
    );
    expect(await count('SELECT COUNT(*) AS c FROM cards'), greaterThan(0));
    // BR-09: every card is born with exactly one review state, so these two
    // counts can never disagree.
    expect(
      await count('SELECT COUNT(*) AS c FROM card_review_states'),
      await count('SELECT COUNT(*) AS c FROM cards'),
    );
  });

  test('a second pass changes nothing (BR-37)', () async {
    await seed();
    final decks = await count('SELECT COUNT(*) AS c FROM decks');
    final cards = await count('SELECT COUNT(*) AS c FROM cards');

    final report = await seed();

    expect(
      report.map((entry) => entry.outcome),
      everyElement(DeckTemplateInstallOutcome.alreadyPresent),
    );
    expect(await count('SELECT COUNT(*) AS c FROM decks'), decks);
    expect(await count('SELECT COUNT(*) AS c FROM cards'), cards);
  });

  test('every data invariant holds after seeding twice', () async {
    await seed();
    await seed();

    for (final entry in invariantQueries.entries) {
      final violations = await db.customSelect(entry.value).get();
      expect(
        violations,
        isEmpty,
        reason:
            '${entry.key} fired after the seed: '
            '${violations.map((row) => row.data).toList()}',
      );
    }
  });

  test('the seeded tree is at least three levels deep', () async {
    await seed();

    // BR-55 allows ten, and BR-57 says the root is wrong from the third level
    // down if it is derived rather than carried. A fixture that stopped at two
    // levels would demo a tree that cannot expose either.
    final depth = await count('''
      WITH RECURSIVE walk(id, level) AS (
        SELECT id, 1 FROM decks WHERE parent_deck_id IS NULL
        UNION ALL
        SELECT d.id, walk.level + 1 FROM decks d JOIN walk ON d.parent_deck_id = walk.id
      )
      SELECT MAX(level) AS c FROM walk
    ''');

    expect(depth, greaterThanOrEqualTo(3));
  });
}
