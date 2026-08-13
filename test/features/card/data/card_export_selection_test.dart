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

/// The selected scope, against real SQLite (BR-174, UC-11 E6).
///
/// Its own file because its rule is its own: an exact id set, duplicates
/// collapsed, and the whole request refused the moment one id no longer
/// resolves inside this deck. `card_export_repository_test.dart` covers the
/// whole-deck scope and the order both share.
void main() {
  final h = installDeckRepositoryHarness();

  CardExportRepositoryImpl repository() => CardExportRepositoryImpl(h.db);

  Future<CardEntity> addCard(
    String deckId,
    String front, {
    Duration after = Duration.zero,
  }) => seedExportCard(h, deckId, front, after: after);

  List<String> frontsOf(List<CardTransferRecord> records) => <String>[
    for (final record in records) record.front.value,
  ];

  group('scope selected (BR-174)', () {
    test('returns exactly the requested ids', () async {
      final tree = await h.seedTree();
      final wanted = await addCard(
        tree.leaf.id,
        'wanted',
        after: const Duration(minutes: 1),
      );
      await addCard(tree.leaf.id, 'other', after: const Duration(minutes: 1));

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: CardExportSelectionScope(<String>[wanted.id]),
      );

      expect(frontsOf(snapshot.records), <String>['wanted']);
    });

    test('a repeated id produces one row, not two', () async {
      final tree = await h.seedTree();
      final card = await addCard(tree.leaf.id, 'alpha');

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: CardExportSelectionScope(<String>[card.id, card.id, card.id]),
      );

      expect(frontsOf(snapshot.records), <String>['alpha']);
    });

    test('a deleted id fails the whole request and returns nothing '
        'partial', () async {
      final tree = await h.seedTree();
      final kept = await addCard(
        tree.leaf.id,
        'kept',
        after: const Duration(minutes: 1),
      );
      final doomed = await addCard(
        tree.leaf.id,
        'doomed',
        after: const Duration(minutes: 1),
      );
      await h.cardRepository.deleteCard(doomed.id);

      await expectLater(
        repository().readSnapshot(
          deckId: tree.leaf.id,
          scope: CardExportSelectionScope(<String>[kept.id, doomed.id]),
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure failure) => failure.problems,
            'problems',
            contains(CardExportProblem.staleSelection),
          ),
        ),
      );
    });

    test('an id that moved to another deck fails the whole request', () async {
      final tree = await h.seedTree();
      final sibling = await h.deckRepository.createSubDeck(
        name: DeckName.parse('Sibling').name!,
        parentDeckId: tree.branch.id,
      );
      final kept = await addCard(
        tree.leaf.id,
        'kept',
        after: const Duration(minutes: 1),
      );
      final moved = await addCard(
        tree.leaf.id,
        'moved',
        after: const Duration(minutes: 1),
      );
      await h.cardRepository.moveCards(
        cardIds: <String>[moved.id],
        targetDeckId: sibling.id,
      );

      await expectLater(
        repository().readSnapshot(
          deckId: tree.leaf.id,
          scope: CardExportSelectionScope(<String>[kept.id, moved.id]),
        ),
        throwsA(
          isA<ValidationFailure>().having(
            (ValidationFailure failure) => failure.problems,
            'problems',
            contains(CardExportProblem.staleSelection),
          ),
        ),
      );
    });

    test('an id belonging to another deck all along is refused the same '
        'way', () async {
      final tree = await h.seedTree();
      final sibling = await h.deckRepository.createSubDeck(
        name: DeckName.parse('Sibling').name!,
        parentDeckId: tree.branch.id,
      );
      final mine = await addCard(
        tree.leaf.id,
        'mine',
        after: const Duration(minutes: 1),
      );
      final theirs = await addCard(
        sibling.id,
        'theirs',
        after: const Duration(minutes: 1),
      );

      await expectLater(
        repository().readSnapshot(
          deckId: tree.leaf.id,
          scope: CardExportSelectionScope(<String>[mine.id, theirs.id]),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('more ids than one statement may bind still come back whole and '
        'in order', () async {
      final tree = await h.seedTree();
      final ids = <String>[];
      for (var i = 0; i < 450; i++) {
        // Zero-padded so the front text sorts the same way created_at does,
        // which is what makes the assertion below about the *merge* of two
        // chunks rather than about one of them.
        ids.add(
          (await addCard(
            tree.leaf.id,
            'card ${i.toString().padLeft(3, '0')}',
            after: const Duration(seconds: 1),
          )).id,
        );
      }

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        // Reversed, so nothing about the request order can produce the answer.
        scope: CardExportSelectionScope(ids.reversed),
      );

      expect(snapshot.records, hasLength(450));
      final fronts = frontsOf(snapshot.records);
      expect(fronts.first, 'card 000');
      expect(fronts.last, 'card 449');
      expect(fronts, orderedEquals(<String>[...fronts]..sort()));
    });
  });
}
