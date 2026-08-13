import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/data/repositories/card_export_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_export_failure.dart';
import 'package:memox/features/card/domain/models/card_export_scope_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_record_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';

import 'support/card_export_seed_fixture.dart';
import '../../deck/data/support/deck_repository_harness.dart';

/// Which rows an export scope reaches, and in what order (BR-174, BR-177).
///
/// Against real SQLite, because every claim here is a property of the
/// statement rather than of the Dart around it. BR-178's other half — that
/// reading changed nothing — is `card_export_read_only_test.dart`; split
/// so neither file outgrows the size limit, and along a real seam.
void main() {
  final h = installDeckRepositoryHarness();

  CardExportRepositoryImpl repository() => CardExportRepositoryImpl(h.db);

  Future<CardEntity> addCard(
    String deckId,
    String front, {
    Duration after = Duration.zero,
    String? example,
    String? hint,
    String? pronunciation,
    List<String> tags = const <String>[],
  }) => seedExportCard(
    h,
    deckId,
    front,
    after: after,
    example: example,
    hint: hint,
    pronunciation: pronunciation,
    tags: tags,
  );

  List<String> frontsOf(List<CardTransferRecord> records) => <String>[
    for (final record in records) record.front.value,
  ];

  group('scope all (BR-174)', () {
    test('returns every card held directly by the deck, with its deck '
        'name', () async {
      final tree = await h.seedTree();
      await addCard(tree.leaf.id, 'alpha', after: const Duration(minutes: 1));
      await addCard(tree.leaf.id, 'beta', after: const Duration(minutes: 1));

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: const CardExportWholeDeckScope(),
      );

      expect(snapshot.deckName, 'Leaf');
      expect(frontsOf(snapshot.records), <String>['alpha', 'beta']);
    });

    test('carries the six content fields and nothing else (BR-175)', () async {
      final tree = await h.seedTree();
      await addCard(
        tree.leaf.id,
        'alpha',
        example: 'an example',
        hint: 'a hint',
        pronunciation: 'aa-lfa',
        tags: <String>['noun'],
      );

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: const CardExportWholeDeckScope(),
      );

      final record = snapshot.records.single;
      expect(record.front.value, 'alpha');
      expect(record.back.value, 'alpha-back');
      expect(record.example?.value, 'an example');
      expect(record.hint?.value, 'a hint');
      expect(record.pronunciation?.value, 'aa-lfa');
      expect(record.tags.map((tag) => tag.value), <String>['noun']);
      // The canonical record has no id, timestamp or source row to leak.
      expect(record.sourceRowNumber, isNull);
    });

    test('an empty optional field arrives as null, not an empty '
        'string', () async {
      final tree = await h.seedTree();
      await addCard(tree.leaf.id, 'alpha');

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: const CardExportWholeDeckScope(),
      );

      final record = snapshot.records.single;
      expect(record.example, isNull);
      expect(record.hint, isNull);
      expect(record.pronunciation, isNull);
      expect(record.tags, isEmpty);
    });

    test('ignores the filter, search and sort the list happens to be '
        'showing', () async {
      final tree = await h.seedTree();
      final flagged = await addCard(
        tree.leaf.id,
        'alpha',
        after: const Duration(minutes: 1),
      );
      await addCard(tree.leaf.id, 'beta', after: const Duration(minutes: 1));
      // Whatever a Flagged/Due/search view would be showing, the scope has no
      // parameter for it — there is nothing to pass and nothing to forget.
      await h.cardRepository.setCardFlag(cardId: flagged.id, isFlagged: true);

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: const CardExportWholeDeckScope(),
      );

      expect(frontsOf(snapshot.records), <String>['alpha', 'beta']);
    });

    test('never reaches another deck of the same tree', () async {
      final tree = await h.seedTree();
      final sibling = await h.deckRepository.createSubDeck(
        name: DeckName.parse('Sibling').name!,
        parentDeckId: tree.branch.id,
      );
      await addCard(tree.leaf.id, 'mine', after: const Duration(minutes: 1));
      await addCard(sibling.id, 'theirs', after: const Duration(minutes: 1));

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: const CardExportWholeDeckScope(),
      );

      expect(frontsOf(snapshot.records), <String>['mine']);
    });

    test('a deck that holds sub-decks holds no cards of its own', () async {
      final tree = await h.seedTree();
      await addCard(tree.leaf.id, 'alpha');

      await expectLater(
        repository().readSnapshot(
          deckId: tree.branch.id,
          scope: const CardExportWholeDeckScope(),
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure failure) => failure.problems,
            'problems',
            contains(CardExportProblem.emptyScope),
          ),
        ),
      );
    });
  });

  group('order (BR-177)', () {
    test('created_at ascending, oldest first', () async {
      final tree = await h.seedTree();
      await addCard(tree.leaf.id, 'first', after: const Duration(minutes: 1));
      await addCard(tree.leaf.id, 'second', after: const Duration(minutes: 5));
      await addCard(tree.leaf.id, 'third', after: const Duration(minutes: 2));

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: const CardExportWholeDeckScope(),
      );

      expect(frontsOf(snapshot.records), <String>['first', 'second', 'third']);
    });

    test('cards sharing one instant fall back to id ascending', () async {
      final tree = await h.seedTree();
      // No clock advance: an import writes a whole batch at one timestamp, so
      // without the tie-break the order would be whatever SQLite felt like.
      final a = await addCard(tree.leaf.id, 'alpha');
      final b = await addCard(tree.leaf.id, 'beta');
      expect(a.id.compareTo(b.id), lessThan(0));

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: const CardExportWholeDeckScope(),
      );

      expect(frontsOf(snapshot.records), <String>['alpha', 'beta']);
    });

    test('the selection is ordered by created_at, not by tap order', () async {
      final tree = await h.seedTree();
      final first = await addCard(
        tree.leaf.id,
        'first',
        after: const Duration(minutes: 1),
      );
      final second = await addCard(
        tree.leaf.id,
        'second',
        after: const Duration(minutes: 1),
      );

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        // Tapped newest first.
        scope: CardExportSelectionScope(<String>[second.id, first.id]),
      );

      expect(frontsOf(snapshot.records), <String>['first', 'second']);
    });

    test('tags come back complete and folded-name ordered', () async {
      final tree = await h.seedTree();
      await addCard(
        tree.leaf.id,
        'alpha',
        tags: <String>['Zebra', 'apple', 'Noun'],
      );

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: const CardExportWholeDeckScope(),
      );

      expect(snapshot.records.single.tags.map((tag) => tag.value), <String>[
        'apple',
        'Noun',
        'Zebra',
      ]);
    });

    test('one snapshot serves however many cards — tags are not read per '
        'card (BR-177)', () async {
      // **Counted, not inferred.** This assertion used to be on the records
      // alone, and the records cannot show it: a repository issuing one tag
      // query per card returns exactly what a single grouped read returns, so
      // the test passed either way and the N+1 it was named for could have
      // walked in unnoticed. The statement log is the only witness.
      final tree = await h.seedTree();
      for (var i = 0; i < 30; i++) {
        await addCard(
          tree.leaf.id,
          'card $i',
          after: const Duration(minutes: 1),
          tags: <String>['shared', 'own $i'],
        );
      }
      h.clearStatements();

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: const CardExportWholeDeckScope(),
      );

      expect(snapshot.records, hasLength(30));
      expect(
        snapshot.records.every((record) => record.tags.length == 2),
        isTrue,
      );
      // Two reads for thirty cards: the deck's name, and the cards with their
      // tags folded in by the correlated `GROUP_CONCAT`. Thirty-one would be
      // the N+1; thirty-two would be one per card plus the two.
      expect(
        h.countStatements('FROM cards AS c'),
        1,
        reason: 'one statement reads the cards and their tags together',
      );
      expect(
        h.countStatements('FROM card_tags AS ct'),
        1,
        reason: 'the only card_tags read is the one inside that statement',
      );
      expect(h.countStatements('FROM decks'), 1, reason: 'the deck name');
    });
  });
}
