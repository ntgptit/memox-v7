import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_reorder_placement_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';

import 'support/deck_repository_harness.dart';
import '../../card/data/support/card_text_fixture.dart';

/// Persisted sibling-order tests on real SQLite. Every write is exercised
/// through the repository boundary, including the rollback injection.
void main() {
  final h = installDeckRepositoryHarness();

  Future<List<String>> rootNames() async =>
      (await h.deckRepository.watchRootDecks().first)
          .map((deck) => deck.name)
          .toList();

  Future<List<String>> rootIds() async =>
      (await h.deckRepository.watchRootDecks().first)
          .map((deck) => deck.id)
          .toList();

  Future<List<DeckEntity>> roots(String prefix, int count) async {
    final decks = <DeckEntity>[];
    for (var index = 0; index < count; index++) {
      decks.add(
        await h.deckRepository.createRootDeck(
          name: DeckName.parse('$prefix$index').name!,
          schedulerType: SchedulerType.eightBox,
        ),
      );
    }

    return decks;
  }

  test('moves the first root deck after the last sibling', () async {
    final decks = await roots('Root', 3);

    await h.deckRepository.reorderDeck(
      deckId: decks[0].id,
      targetSiblingDeckId: decks[2].id,
      placement: DeckReorderPlacement.after,
    );

    expect(await rootNames(), <String>['Root1', 'Root2', 'Root0']);
  });

  test('moves the last root deck before the first sibling', () async {
    final decks = await roots('Root', 3);

    await h.deckRepository.reorderDeck(
      deckId: decks[2].id,
      targetSiblingDeckId: decks[0].id,
      placement: DeckReorderPlacement.before,
    );

    expect(await rootNames(), <String>['Root2', 'Root0', 'Root1']);
  });

  test('moves a middle sibling to another middle position', () async {
    final decks = await roots('Root', 4);

    await h.deckRepository.reorderDeck(
      deckId: decks[1].id,
      targetSiblingDeckId: decks[3].id,
      placement: DeckReorderPlacement.before,
    );

    expect(await rootNames(), <String>['Root0', 'Root2', 'Root1', 'Root3']);
  });

  test(
    'reorders nested siblings and preserves the source subtree pointers',
    () async {
      final root = await h.deckRepository.createRootDeck(
        name: DeckName.parse('Root').name!,
        schedulerType: SchedulerType.eightBox,
      );
      final first = await h.deckRepository.createSubDeck(
        name: DeckName.parse('First').name!,
        parentDeckId: root.id,
      );
      final source = await h.deckRepository.createSubDeck(
        name: DeckName.parse('Source').name!,
        parentDeckId: root.id,
      );
      final target = await h.deckRepository.createSubDeck(
        name: DeckName.parse('Target').name!,
        parentDeckId: root.id,
      );
      final grandchild = await h.deckRepository.createSubDeck(
        name: DeckName.parse('Grandchild').name!,
        parentDeckId: source.id,
      );
      final card = await h.cardRepository.createCard(
        deckId: grandchild.id,
        front: cardText('front'),
        back: cardText('back', side: CardSide.back),
      );
      final beforeSource = (await h.rawDeck(source.id))!;
      final beforeGrandchild = (await h.rawDeck(grandchild.id))!;
      final beforeCard = (await h.rawCard(card.id))!;
      final beforeState = (await h.rawStates(card.id)).single;

      await h.deckRepository.reorderDeck(
        deckId: source.id,
        targetSiblingDeckId: target.id,
        placement: DeckReorderPlacement.after,
      );

      final level = await h.deckRepository
          .watchDeckList(
            parentDeckId: root.id,
            now: h.currentInstant,
            utcOffset: Duration.zero,
          )
          .first;
      expect(level.decks.map((summary) => summary.deck.id), <String>[
        first.id,
        target.id,
        source.id,
      ]);
      final afterSource = (await h.rawDeck(source.id))!;
      final afterGrandchild = (await h.rawDeck(grandchild.id))!;
      final afterCard = (await h.rawCard(card.id))!;
      final afterState = (await h.rawStates(card.id)).single;
      expect(
        afterSource.readNullable<String>('parent_deck_id'),
        beforeSource.readNullable<String>('parent_deck_id'),
      );
      expect(
        afterSource.read<String>('root_deck_id'),
        beforeSource.read<String>('root_deck_id'),
      );
      expect(
        afterGrandchild.readNullable<String>('parent_deck_id'),
        beforeGrandchild.readNullable<String>('parent_deck_id'),
      );
      expect(
        afterGrandchild.read<String>('root_deck_id'),
        beforeGrandchild.read<String>('root_deck_id'),
      );
      expect(
        afterCard.read<String>('deck_id'),
        beforeCard.read<String>('deck_id'),
      );
      expect(
        afterState.read<String>('scheduler_type'),
        beforeState.read<String>('scheduler_type'),
      );
      expect(
        afterState.read<int>('scheduler_generation'),
        beforeState.read<int>('scheduler_generation'),
      );
    },
  );

  test('one sibling and an already-adjacent placement are no-ops', () async {
    final only = (await roots('Only', 1)).single;
    await h.deckRepository.reorderDeck(
      deckId: only.id,
      targetSiblingDeckId: only.id,
      placement: DeckReorderPlacement.before,
    );
    expect(await rootIds(), <String>[only.id]);

    final decks = await roots('More', 2);
    await h.deckRepository.reorderDeck(
      deckId: decks[0].id,
      targetSiblingDeckId: decks[1].id,
      placement: DeckReorderPlacement.before,
    );
    expect(await rootNames(), <String>['Only0', 'More0', 'More1']);
  });

  test('a stale deck or stale target sibling is refused', () async {
    final decks = await roots('Root', 2);
    await expectLater(
      h.deckRepository.reorderDeck(
        deckId: 'missing',
        targetSiblingDeckId: decks[0].id,
        placement: DeckReorderPlacement.before,
      ),
      throwsA(isA<NotFoundFailure>()),
    );
    await expectLater(
      h.deckRepository.reorderDeck(
        deckId: decks[0].id,
        targetSiblingDeckId: 'missing',
        placement: DeckReorderPlacement.after,
      ),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test(
    'a target outside the sibling group is refused without moving either deck',
    () async {
      final root = (await roots('Root', 1)).single;
      final child = await h.deckRepository.createSubDeck(
        name: DeckName.parse('Child').name!,
        parentDeckId: root.id,
      );

      await expectLater(
        h.deckRepository.reorderDeck(
          deckId: root.id,
          targetSiblingDeckId: child.id,
          placement: DeckReorderPlacement.before,
        ),
        throwsA(isA<ConflictFailure>()),
      );
      expect(
        (await h.rawDeck(root.id))!.readNullable<String>('parent_deck_id'),
        isNull,
      );
      expect(
        (await h.rawDeck(child.id))!.readNullable<String>('parent_deck_id'),
        root.id,
      );
    },
  );

  test('a database failure rolls the entire sibling order back', () async {
    final decks = await roots('Root', 3);
    final before = await rootIds();
    await h.db.customStatement(
      'CREATE TRIGGER fail_reorder BEFORE UPDATE OF sibling_position ON decks '
      "WHEN NEW.id = '${decks[1].id}' "
      "BEGIN SELECT RAISE(ABORT, 'injected reorder failure'); END",
    );

    await expectLater(
      h.deckRepository.reorderDeck(
        deckId: decks[0].id,
        targetSiblingDeckId: decks[2].id,
        placement: DeckReorderPlacement.after,
      ),
      throwsA(isA<Failure>()),
    );

    expect(await rootIds(), before);
  });

  test('the root watch re-emits the persisted order after a reorder', () async {
    final decks = await roots('Root', 3);
    final emissions = <List<String>>[];
    final subscription = h.deckRepository.watchRootDecks().listen(
      (rows) => emissions.add(rows.map((deck) => deck.id).toList()),
    );
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await h.deckRepository.reorderDeck(
      deckId: decks[0].id,
      targetSiblingDeckId: decks[2].id,
      placement: DeckReorderPlacement.after,
    );
    await pumpEventQueue();

    expect(emissions.last, <String>[decks[1].id, decks[2].id, decks[0].id]);
  });
}
