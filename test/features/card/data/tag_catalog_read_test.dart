import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/data/repositories/card_import_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/tag_catalog_failure.dart';
import 'package:memox/features/card/domain/models/card_transfer_record_model.dart';
import 'package:memox/features/card/domain/repositories/card_import_repository.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart'
    show CardSide;
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';

import 'support/card_text_fixture.dart';
import '../../deck/data/support/deck_repository_harness.dart';

/// The tag catalog's **read** on a real SQLite database (UC-18, BR-230).
///
/// Split from the write tests so neither file outgrows the 400-line guard, and
/// along a real seam: everything here is one statement answering "what is in
/// the catalog", while the other file is transactions that change it.
///
/// **Real SQLite rather than a fake.** The ordering claim is about
/// `name_folded` versus `name` in an `ORDER BY`, and the live-count claim is
/// about whether drift saw a correlated subquery's table — a fake would answer
/// both from Dart it wrote itself.
void main() {
  final h = installDeckRepositoryHarness();

  TagName tagName(String raw) => TagName.parse(raw).name!;

  Future<DeckEntity> seedDeck() async => (await h.seedTree()).leaf;

  Future<CardEntity> seedCard(String deckId, String front) =>
      h.cardRepository.createCard(
        deckId: deckId,
        front: cardText(front),
        back: cardText('back of $front', side: CardSide.back),
      );

  /// The tag that owns [name]'s folded form, read straight out of the table.
  Future<String?> tagIdNamed(String name) async {
    final row = await h.db
        .customSelect(
          'SELECT id FROM tags WHERE name_folded = ?',
          variables: <Variable<Object>>[Variable<String>(TagName.fold(name))],
        )
        .getSingleOrNull();

    return row?.read<String>('id');
  }

  Future<List<TagCatalogEntry>> catalog({String? search}) =>
      h.tagCatalogRepository.watchTagCatalog(searchTerm: search).first;

  group('the catalog read (BR-230)', () {
    test('lists every tag with how many cards carry it', () async {
      final deck = await seedDeck();
      final one = await seedCard(deck.id, 'a');
      final two = await seedCard(deck.id, 'b');
      await h.cardRepository.addCardTag(cardId: one.id, name: tagName('noun'));
      await h.cardRepository.addCardTag(cardId: two.id, name: tagName('noun'));
      await h.cardRepository.addCardTag(cardId: two.id, name: tagName('verb'));

      final entries = await catalog();

      expect(
        entries.map((TagCatalogEntry e) => (e.name, e.cardCount)),
        <(String, int)>[('noun', 2), ('verb', 1)],
      );
    });

    test('keeps a tag no card carries, at zero (BR-230)', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      await h.cardRepository.addCardTag(
        cardId: card.id,
        name: tagName('orphan'),
      );
      await h.cardRepository.removeCardTag(
        cardId: card.id,
        tagId: (await tagIdNamed('orphan'))!,
      );

      final entries = await catalog();

      expect(entries.single.name, 'orphan');
      expect(entries.single.cardCount, 0);
    });

    test('orders by folded name, not by the stored spelling', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      for (final name in <String>['Verb', 'adjective', 'Noun']) {
        await h.cardRepository.addCardTag(cardId: card.id, name: tagName(name));
      }

      // Byte order on `name` would put every capitalised spelling first and
      // read as random to whoever typed both.
      expect((await catalog()).map((TagCatalogEntry e) => e.name), <String>[
        'adjective',
        'Noun',
        'Verb',
      ]);
    });

    test('searches with BR-93s fold, so Dong tu finds Động từ', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      await h.cardRepository.addCardTag(
        cardId: card.id,
        name: tagName('Động Từ'),
      );
      await h.cardRepository.addCardTag(cardId: card.id, name: tagName('noun'));

      expect(
        (await catalog(search: 'động')).map((TagCatalogEntry e) => e.name),
        <String>['Động Từ'],
        reason: 'SQLite lower() folds ASCII only; this must not depend on it',
      );
      expect((await catalog(search: 'ĐỘNG'))..toString(), hasLength(1));
      expect(await catalog(search: 'nothing here'), isEmpty);
    });

    test('a blank term is no search at all', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      await h.cardRepository.addCardTag(cardId: card.id, name: tagName('noun'));

      expect(await catalog(search: '   '), hasLength(1));
      expect(await catalog(), hasLength(1));
    });

    test('the stream re-emits when a card gains the tag', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      await h.cardRepository.addCardTag(cardId: card.id, name: tagName('noun'));

      final emissions = <List<TagCatalogEntry>>[];
      final subscription = h.tagCatalogRepository.watchTagCatalog().listen(
        emissions.add,
      );
      await pumpEventQueue();

      final second = await seedCard(deck.id, 'b');
      await h.cardRepository.addCardTag(
        cardId: second.id,
        name: tagName('noun'),
      );
      await pumpEventQueue();
      await subscription.cancel();

      // The count lives in a correlated subquery over `card_tags`; if drift
      // dropped that table from `readsFrom` the catalog would sit on 1 forever.
      expect(emissions.first.single.cardCount, 1);
      expect(emissions.last.single.cardCount, 2);
    });
  });

  group('tags from other paths are ordinary catalog rows (BR-238)', () {
    test('a tag created by an import appears with its count', () async {
      final tree = await h.seedTree();
      final importer = CardImportRepositoryImpl(
        h.db,
        clock: () => h.currentInstant,
        idGenerator: () => 'imp-${++h.idCounter}',
      );

      await importer.commitImport(
        deckId: tree.leaf.id,
        plan: CardImportPlan(
          records: <CardTransferRecord>[
            CardTransferRecord(
              front: cardText('사과'),
              back: cardText('apple', side: CardSide.back),
              tags: <TagName>[tagName('Fruit')],
            ),
            CardTransferRecord(
              front: cardText('바다'),
              back: cardText('sea', side: CardSide.back),
              tags: <TagName>[tagName('fruit')],
            ),
          ],
          shouldIncludeDuplicates: false,
        ),
      );

      // One tag, not two: import reuses by folded name like every other path
      // (BR-93), and the catalog is the same read for every origin.
      final entries = await catalog();
      expect(entries.single.name, 'Fruit');
      expect(entries.single.cardCount, 2);
      // And it is renameable and deletable like any other row.
      expect(
        await h.tagCatalogRepository.renameTag(
          tagId: entries.single.id,
          name: tagName('fruits'),
        ),
        TagRenameOutcome.renamed,
      );
    });
  });
}
