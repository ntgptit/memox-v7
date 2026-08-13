import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/data/repositories/card_export_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_export_failure.dart';
import 'package:memox/features/card/domain/models/card_export_scope_model.dart';

import 'support/card_export_seed_fixture.dart';
import '../../deck/data/support/deck_repository_harness.dart';

/// What an export refuses, and what it leaves behind (BR-174, BR-178).
///
/// The half of the export read no fake can make a claim about: a successful
/// read that wrote nothing, and a refused one that wrote nothing either.
/// Which rows a scope reaches and in what order is
/// `card_export_repository_test.dart`.
void main() {
  final h = installDeckRepositoryHarness();

  CardExportRepositoryImpl repository() => CardExportRepositoryImpl(h.db);

  Future<CardEntity> addCard(
    String deckId,
    String front, {
    Duration after = Duration.zero,
    String? example,
    List<String> tags = const <String>[],
  }) => seedExportCard(
    h,
    deckId,
    front,
    after: after,
    example: example,
    tags: tags,
  );

  group('nothing to export, or nothing to export from', () {
    test('an empty deck is refused (UC-11 E5)', () async {
      final tree = await h.seedTree();

      await expectLater(
        repository().readSnapshot(
          deckId: tree.leaf.id,
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

    test('a deck that no longer exists is a different reason '
        '(UC-11 E3)', () async {
      await expectLater(
        repository().readSnapshot(
          deckId: 'no-such-deck',
          scope: const CardExportWholeDeckScope(),
        ),
        throwsA(
          isA<NotFoundFailure>().having(
            (NotFoundFailure failure) => failure.reason,
            'reason',
            CardExportProblem.deckMissing,
          ),
        ),
      );
    });

    test('a selection whose every id is stale reports the selection, not '
        'emptiness', () async {
      final tree = await h.seedTree();
      final card = await addCard(tree.leaf.id, 'alpha');
      await h.cardRepository.deleteCard(card.id);

      await expectLater(
        repository().readSnapshot(
          deckId: tree.leaf.id,
          scope: CardExportSelectionScope(<String>[card.id]),
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
  });

  group('stored text a current limit would refuse (BR-175)', () {
    test('a side longer than the limit still exports, verbatim', () async {
      final tree = await h.seedTree();
      final card = await addCard(tree.leaf.id, 'alpha');
      // A row written while BR-08 still said 2000. The change to 60/240 at
      // M4.10at truncated nothing and `cards.drift` carries no CHECK, so a
      // database can hold this — and export is the only way data leaves this
      // app, so refusing the whole deck over it is data loss, not validation.
      final long = 'x' * 200;
      await h.db.customStatement(
        'UPDATE cards SET front = ? WHERE id = ?',
        <Object?>[long, card.id],
      );

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: const CardExportWholeDeckScope(),
      );

      expect(snapshot.records.single.front.value, long);
    });

    test('an optional detail over its limit exports too', () async {
      final tree = await h.seedTree();
      final card = await addCard(tree.leaf.id, 'alpha');
      final long = 'y' * 500;
      await h.db.customStatement(
        'UPDATE cards SET example = ? WHERE id = ?',
        <Object?>[long, card.id],
      );

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: const CardExportWholeDeckScope(),
      );

      expect(snapshot.records.single.example?.value, long);
    });

    test(
      'a blank side is still refused — it cannot be imported back',
      () async {
        final tree = await h.seedTree();
        final card = await addCard(tree.leaf.id, 'alpha');
        await h.db.customStatement(
          'UPDATE cards SET back = ? WHERE id = ?',
          <Object?>['   ', card.id],
        );

        await expectLater(
          repository().readSnapshot(
            deckId: tree.leaf.id,
            scope: const CardExportWholeDeckScope(),
          ),
          throwsA(
            isA<DatabaseFailure>().having(
              (DatabaseFailure failure) => failure.reason,
              'reason',
              CardExportProblem.readFailed,
            ),
          ),
        );
      },
    );
  });

  group('read-only (BR-178)', () {
    /// Every column of every table an export could plausibly touch, rendered
    /// as text in a fixed order. Raw `customSelect` on purpose: asserting what
    /// is *in the table* must not go through the code under test.
    Future<String> dump() async {
      const tables = <String, String>{
        'decks': 'id',
        'cards': 'id',
        'card_study_states': 'card_id',
        'tags': 'id',
        'card_tags': 'card_id, tag_id',
        'study_sessions': 'id',
        'study_answers': 'id',
      };
      final buffer = StringBuffer();
      for (final entry in tables.entries) {
        buffer.writeln('-- ${entry.key}');
        final rows = await h.db
            .customSelect('SELECT * FROM ${entry.key} ORDER BY ${entry.value}')
            .get();
        for (final row in rows) {
          buffer.writeln(
            row.data.entries
                .map(
                  (MapEntry<String, Object?> cell) =>
                      '${cell.key}=${cell.value}',
                )
                .join('|'),
          );
        }
      }

      return buffer.toString();
    }

    test('a successful export changes not one byte', () async {
      final tree = await h.seedTree();
      await addCard(
        tree.leaf.id,
        'alpha',
        after: const Duration(minutes: 1),
        example: 'an example',
        tags: <String>['noun', 'verb'],
      );
      await addCard(
        tree.leaf.id,
        'beta',
        after: const Duration(minutes: 1),
        tags: <String>['noun'],
      );
      final before = await dump();
      // The clock moves, so a stray `updated_at` write would be visible rather
      // than coincidentally equal to what it replaced.
      h.currentInstant = h.currentInstant.add(const Duration(hours: 3));

      final snapshot = await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: const CardExportWholeDeckScope(),
      );

      expect(snapshot.records, hasLength(2));
      expect(await dump(), before);
    });

    test('a refused export changes nothing either', () async {
      final tree = await h.seedTree();
      final card = await addCard(tree.leaf.id, 'alpha');
      final before = await dump();

      await expectLater(
        repository().readSnapshot(
          deckId: tree.leaf.id,
          scope: CardExportSelectionScope(<String>[card.id, 'gone']),
        ),
        throwsA(isA<ValidationFailure>()),
      );

      expect(await dump(), before);
    });

    test('the deck keeps its content type — export is not a mutation '
        '(BR-163)', () async {
      final tree = await h.seedTree();
      await addCard(tree.leaf.id, 'alpha');

      await repository().readSnapshot(
        deckId: tree.leaf.id,
        scope: const CardExportWholeDeckScope(),
      );

      expect(await h.contentTypeOf(tree.leaf.id), 'card');
    });
  });
}
