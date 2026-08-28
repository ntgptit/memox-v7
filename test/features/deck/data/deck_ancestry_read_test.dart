import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../../../database/support/test_database.dart';
import 'support/deck_repository_harness.dart';

/// The path back up, read from real SQLite.
///
/// Split from `deck_level_read_test.dart`, which owns what is *inside* a level.
/// This file owns what is above it — the chain the breadcrumb renders — and it is
/// worth its own file because the failure modes are different: the chain is
/// produced by a recursive walk upwards and carried in the one JSON column in the
/// deck reads, so an off-by-one in the walk or a lost entry in the encoding are
/// the risks, not a miscounted aggregate.
///
/// The mapper's own contract — ordering, malformed input, partial damage — is in
/// `deck_mapper_test.dart` against literal strings. What only a database can
/// answer is whether SQLite produces that string correctly at every depth, which
/// is what is below.
void main() {
  final harness = installDeckRepositoryHarness();
  final now = testNow;

  Future<DeckListSnapshot> levelUnder(String deckId) => harness.deckRepository
      .watchDeckList(parentDeckId: deckId, now: now, utcOffset: Duration.zero)
      .first;

  Future<List<String>> pathNamesUnder(String deckId) async => (await levelUnder(
    deckId,
  )).ancestors.map((DeckPathSegment segment) => segment.name).toList();

  /// A chain of [depth] decks, root first. BR-55 owns the maximum.
  Future<List<DeckEntity>> seedChain(int depth) async {
    final decks = <DeckEntity>[
      await harness.deckRepository.createRootDeck(
        name: DeckName.parse('L1').name!,
        schedulerType: SchedulerType.eightBox,
      ),
    ];
    for (var level = 2; level <= depth; level++) {
      decks.add(
        await harness.deckRepository.createSubDeck(
          name: DeckName.parse('L$level').name!,
          parentDeckId: decks.last.id,
        ),
      );
    }

    return decks;
  }

  group('what the chain contains', () {
    test('a root deck has no ancestors', () async {
      // Level 2 in the UI sense — you are inside a root deck — and there is
      // genuinely nothing above it. The screen renders no breadcrumb here, and
      // this is the read that says so.
      final chain = await seedChain(1);

      expect(await pathNamesUnder(chain.single.id), isEmpty);
    });

    test('a level-3 deck names its root', () async {
      final chain = await seedChain(3);

      expect(await pathNamesUnder(chain[2].id), <String>['L1', 'L2']);
    });

    test('the deck being viewed is not in its own chain', () async {
      // It is `snapshot.parent`, and carrying it twice would let one read
      // disagree with itself the moment a rename lands between the two copies.
      final chain = await seedChain(3);
      final level = await levelUnder(chain[2].id);

      expect(level.parent?.name, 'L3');
      expect(
        level.ancestors.map((DeckPathSegment segment) => segment.id),
        isNot(contains(chain[2].id)),
      );
    });

    test('at the deepest level BR-55 allows, the chain is complete', () async {
      // Ten levels, so nine ancestors, root first. A walk that stopped one short
      // would look correct at every shallower depth.
      final chain = await seedChain(DeckEntity.maxTreeDepth);

      expect(await pathNamesUnder(chain.last.id), <String>[
        'L1',
        'L2',
        'L3',
        'L4',
        'L5',
        'L6',
        'L7',
        'L8',
        'L9',
      ]);
    });

    test('a cyclic parent chain terminates and leaves SQLite usable', () async {
      // Only corrupt data can make this shape (invariant Q8 catches it), but the
      // read still must terminate: an unbounded ancestry CTE holds the database
      // isolate and blocks every later statement in the app.
      final chain = await seedChain(3);
      await harness.db.customUpdate(
        'UPDATE decks SET parent_deck_id = ? WHERE id = ?',
        variables: <Variable<Object>>[
          Variable<String>(chain[2].id),
          Variable<String>(chain[1].id),
        ],
        updates: <TableInfo<Table, Object?>>{harness.db.decks},
      );

      final level = await levelUnder(
        chain[2].id,
      ).timeout(const Duration(seconds: 5));

      expect(level.parent?.id, chain[2].id);
      expect(
        level.ancestors,
        hasLength(lessThanOrEqualTo(DeckEntity.maxTreeDepth + 1)),
      );

      final nextQuery = await harness.db
          .customSelect('SELECT COUNT(*) AS deck_count FROM decks')
          .getSingle()
          .timeout(const Duration(seconds: 5));
      expect(nextQuery.read<int>('deck_count'), chain.length);
    });

    test('each segment carries the id the breadcrumb navigates to', () async {
      final chain = await seedChain(4);
      final level = await levelUnder(chain[3].id);

      expect(
        level.ancestors.map((DeckPathSegment segment) => segment.id),
        <String>[chain[0].id, chain[1].id, chain[2].id],
      );
    });

    test('a sibling branch is not in the chain', () async {
      // The walk goes up by `parent_deck_id`. A join one degree too loose would
      // pull in cousins, and a single-branch fixture would never notice.
      final chain = await seedChain(3);
      await harness.deckRepository.createSubDeck(
        name: DeckName.parse('Cousin').name!,
        parentDeckId: chain[0].id,
      );

      expect(await pathNamesUnder(chain[2].id), <String>['L1', 'L2']);
    });
  });

  group('the chain moves with the data', () {
    test('renaming an ancestor renames it in the chain', () async {
      // The reason this is in the level's own statement rather than a second
      // query: the title and the breadcrumb have to move in the same frame.
      final chain = await seedChain(3);
      await harness.deckRepository.renameDeck(
        deckId: chain[0].id,
        name: DeckName.parse('Renamed root').name!,
      );

      expect(await pathNamesUnder(chain[2].id), <String>['Renamed root', 'L2']);
    });

    test('moving the deck rewrites its chain', () async {
      final chain = await seedChain(3);
      final elsewhere = await harness.deckRepository.createSubDeck(
        name: DeckName.parse('Elsewhere').name!,
        parentDeckId: chain[0].id,
      );

      await harness.deckRepository.moveDeck(
        deckId: chain[2].id,
        targetParentDeckId: elsewhere.id,
      );

      expect(await pathNamesUnder(chain[2].id), <String>['L1', 'Elsewhere']);
    });

    test('a name with JSON punctuation survives the round trip', () async {
      // The reason the column is JSON rather than two delimited strings: BR-01
      // lets a deck be called anything, so no separator is safe. This is that
      // claim through a real encoder and a real decoder.
      const awkward = 'N5, N4 | "quoted" \\ and more';
      final chain = await seedChain(2);
      await harness.deckRepository.renameDeck(
        deckId: chain[0].id,
        name: DeckName.parse(awkward).name!,
      );
      final leaf = await harness.deckRepository.createSubDeck(
        name: DeckName.parse('Leaf').name!,
        parentDeckId: chain[1].id,
      );

      expect(await pathNamesUnder(leaf.id), <String>[awkward, 'L2']);
    });
  });
}
