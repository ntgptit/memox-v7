import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/datasources/deck_template_dao.dart';
import 'package:memox/features/deck/data/repositories/deck_template_repository_impl.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_template_repository.dart';
import 'package:memox/features/deck/domain/usecases/install_deck_templates_use_case.dart';

import '../../../database/invariant_queries.dart';
import '../../../database/support/test_database.dart';
import 'support/deck_template_fixture.dart';

/// Copying a starter template into the user's decks, on a real SQLite database
/// (AD-07, BR-33…BR-39).
void main() {
  late AppDatabase db;
  late DeckTemplateRepositoryImpl repository;
  var idCounter = 0;

  setUp(() {
    db = openTestDatabase();
    idCounter = 0;
    repository = DeckTemplateRepositoryImpl(
      DeckTemplateDao(db),
      idGenerator: () => 'gen-${++idCounter}',
      clock: () => testNow,
    );
  });

  tearDown(() => db.close());

  Future<int> countRows(String table) async {
    final row = await db
        .customSelect('SELECT COUNT(*) AS c FROM $table')
        .getSingle();

    return row.read<int>('c');
  }

  Future<List<Map<String, Object?>>> rows(String sql) async {
    final result = await db.customSelect(sql).get();

    return result.map((row) => row.data).toList();
  }

  test(
    'a copy writes the whole tree, its cards and their review states',
    () async {
      final outcome = await repository.installTemplate(
        eightBoxFixtureTemplate(),
      );

      expect(outcome, DeckTemplateInstallOutcome.installed);
      // root + branch + two leaves.
      expect(await countRows('decks'), 4);
      expect(await countRows('cards'), 3);
      // BR-09: exactly one review state per card, born with it.
      expect(await countRows('card_review_states'), 3);

      final root = (await rows(
        "SELECT * FROM decks WHERE parent_deck_id IS NULL",
      )).single;
      expect(root['name'], 'Fixture deck');
      // BR-58: a root holds sub-decks only, so it is `deck` from birth.
      expect(root['content_type'], 'deck');
      // BR-56: a root carries its own id.
      expect(root['root_deck_id'], root['id']);
      // BR-34: the copy records where it came from, which is what makes the next
      // install idempotent.
      expect(root['source_template_id'], 'fixture.test.tree');
      expect(root['source_template_version'], 1);
      expect(root['scheduler_type'], 'eight_box');
      expect(root['scheduler_generation'], 1);

      // BR-06: only the root carries scheduler columns.
      final children = await rows(
        'SELECT * FROM decks WHERE parent_deck_id IS NOT NULL',
      );
      for (final child in children) {
        expect(
          child['scheduler_type'],
          isNull,
          reason: 'child ${child['name']}',
        );
        expect(child['root_deck_id'], root['id']);
      }
    },
  );

  test('a leaf with cards is `card`, an empty leaf stays `unset`', () async {
    await repository.installTemplate(eightBoxFixtureTemplate());

    final withCards = (await rows(
      "SELECT * FROM decks WHERE name = 'Words'",
    )).single;
    expect(withCards['content_type'], 'card');

    // BR-62: an empty deck has not been committed to a kind yet, and a copied
    // one must be in the same state as one the user just created — otherwise the
    // copy hands them a deck they cannot put sub-decks in for no visible reason.
    final empty = (await rows(
      "SELECT * FROM decks WHERE name = 'Empty'",
    )).single;
    expect(empty['content_type'], 'unset');
  });

  test('installing twice writes nothing the second time (BR-37)', () async {
    final first = await repository.installTemplate(eightBoxFixtureTemplate());
    final decksAfterFirst = await countRows('decks');
    final cardsAfterFirst = await countRows('cards');

    final second = await repository.installTemplate(eightBoxFixtureTemplate());

    expect(first, DeckTemplateInstallOutcome.installed);
    expect(second, DeckTemplateInstallOutcome.alreadyPresent);
    expect(await countRows('decks'), decksAfterFirst);
    expect(await countRows('cards'), cardsAfterFirst);
  });

  test('a new template version installs beside the old copy (BR-36)', () async {
    await repository.installTemplate(eightBoxFixtureTemplate());
    // The same template id, one version on. BR-36 forbids touching the existing
    // copy, and BR-37's key is the pair — so this is a second install, not a
    // duplicate.
    await repository.installTemplate(eightBoxFixtureTemplate(version: 2));

    final roots = await rows(
      'SELECT * FROM decks WHERE parent_deck_id IS NULL ORDER BY source_template_version',
    );
    expect(roots.length, 2);
    expect(roots.first['source_template_version'], 1);
    expect(roots.last['source_template_version'], 2);
  });

  test(
    'the scheduler decides which review-state columns are filled (BR-09)',
    () async {
      await repository.installTemplate(
        eightBoxFixtureTemplate(scheduler: SchedulerType.sm2),
      );

      final state = (await rows(
        'SELECT * FROM card_review_states LIMIT 1',
      )).single;
      expect(state['scheduler_type'], 'sm2');
      expect(state['ease_factor'], 2.5);
      expect(state['interval_days'], 0);
      expect(state['repetitions'], 0);
      expect(state['current_box'], isNull);
      // A copied card has never been reviewed, so it has no date yet — the same
      // state a card the user just typed is in.
      expect(state['due_at'], isNull);
      expect(state['review_count'], 0);
    },
  );

  test(
    'the caller may override the template\'s suggested scheduler (BR-34)',
    () async {
      await repository.installTemplate(
        eightBoxFixtureTemplate(),
        schedulerType: SchedulerType.sm2,
      );

      final root = (await rows(
        'SELECT * FROM decks WHERE parent_deck_id IS NULL',
      )).single;
      expect(root['scheduler_type'], 'sm2');
    },
  );

  test('every data invariant holds after a seed', () async {
    await repository.installTemplate(eightBoxFixtureTemplate());
    await repository.installTemplate(
      eightBoxFixtureTemplate(
        templateId: 'fixture.test.second',
        scheduler: SchedulerType.sm2,
      ),
    );

    // The whole set, not a chosen few: a seed writes decks, cards and review
    // states in one transaction, which is exactly the shape that can violate
    // several at once — a wrong `root_deck_id` three levels down, a card in a
    // `deck`-typed parent, a state whose generation does not match its root.
    for (final entry in invariantQueries.entries) {
      final violations = await db.customSelect(entry.value).get();
      expect(
        violations,
        isEmpty,
        reason:
            '${entry.key} fired after seeding: '
            '${violations.map((row) => row.data).toList()}',
      );
    }
  });

  test('the use case reports what it did per template', () async {
    final useCase = InstallDeckTemplatesUseCase(repository);
    final templates = <DeckTemplate>[
      eightBoxFixtureTemplate(),
      eightBoxFixtureTemplate(templateId: 'fixture.test.second'),
    ];

    final first = await useCase(templates);
    final second = await useCase(templates);

    expect(
      first.map((entry) => entry.outcome),
      everyElement(DeckTemplateInstallOutcome.installed),
    );
    // The second pass is the one every launch after the first runs, and it has
    // to be visibly a no-op rather than indistinguishable from a failure.
    expect(
      second.map((entry) => entry.outcome),
      everyElement(DeckTemplateInstallOutcome.alreadyPresent),
    );
  });

  test('a failed copy leaves nothing behind (BR-39)', () async {
    // A duplicate deck id forces the second insert of the tree to fail. The
    // whole copy is one transaction, so the root written moments earlier must
    // roll back with it — a half-copied deck looks real and is not.
    await db.customStatement(
      'INSERT INTO decks (id, name, root_deck_id, content_type, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      <Object?>[
        'gen-2',
        'squatter',
        'gen-2',
        'deck',
        testNow.millisecondsSinceEpoch ~/ 1000,
        testNow.millisecondsSinceEpoch ~/ 1000,
      ],
    );

    await expectLater(
      repository.installTemplate(eightBoxFixtureTemplate()),
      throwsA(anything),
    );

    // Only the squatter survives: the root the copy wrote as `gen-1` is gone.
    final decks = await rows('SELECT id FROM decks');
    expect(decks.map((row) => row['id']), <String>['gen-2']);
  });
}
