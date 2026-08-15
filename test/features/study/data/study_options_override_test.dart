import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_card_limit_model.dart';
import 'package:memox/features/study/domain/usecases/clear_study_options_override_use_case.dart';

import '../../../database/support/test_database.dart';

/// The root deck's override and the action that clears it (BR-212), against a
/// real database.
///
/// **Its own file rather than another group in `study_options_flow_test.dart`.**
/// That file is about the two tiers resolving; this one is about the *third*
/// state a deck can be in — carrying an override, and being put back — which is
/// what the app-wide settings screen made reachable.
void main() {
  late AppDatabase db;
  late StudyRepositoryImpl repository;

  setUp(() {
    db = openTestDatabase();
    repository = StudyRepositoryImpl(
      StudyDao(db),
      idGenerator: () => 'id-0',
      random: Random(11),
    );
  });

  tearDown(() => db.close());

  /// A root deck on `eight_box` with one sub-deck and one learned card.
  ///
  /// The learned card is not scenery: BR-212 says clearing an override must
  /// leave learning progress alone, and a fixture without any progress cannot
  /// tell a correct implementation from one that wiped it.
  Future<void> seed() async {
    await db.customStatement(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'first_answered_at, created_at, updated_at) '
      "VALUES ('d1', 'Korean', 'd1', 'deck', 'eight_box', 1, 1, 5, 0, 0)",
    );
    await db.customStatement(
      'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
      'content_type, created_at, updated_at) '
      "VALUES ('d1a', 'Unit 1', 'd1', 'd1', 'card', 0, 0)",
    );
    await db.customStatement(
      'INSERT INTO cards (id, deck_id, front, back, front_folded, back_folded, '
      "created_at, updated_at) VALUES ('c0', 'd1a', 'f', 'b', 'f', 'b', 0, 0)",
    );
    await db.customStatement(
      'INSERT INTO card_study_states (card_id, scheduler_type, '
      'scheduler_version, scheduler_generation, learned_at, due_at, '
      "answer_count, lapse_count, current_box) "
      "VALUES ('c0', 'eight_box', 1, 1, 5, 9, 3, 1, 4)",
    );
  }

  Future<String?> studyConfigOf(String deckId) async {
    final row = await db
        .customSelect(
          "SELECT study_config AS c FROM decks WHERE id = '$deckId'",
        )
        .getSingle();

    return row.read<String?>('c');
  }

  Future<Map<String, Object?>> stateOf(String cardId) async {
    final row = await db
        .customSelect(
          "SELECT * FROM card_study_states WHERE card_id = '$cardId'",
        )
        .getSingle();

    return row.data;
  }

  group('isRootOverride', () {
    test('is false when the deck follows the app defaults', () async {
      await seed();

      expect((await repository.effectiveOptions('d1')).isRootOverride, isFalse);
    });

    test('is true once the root carries an override, from any level', () async {
      // Read from the root, whichever deck was asked about — the same
      // resolution the values themselves go through (BR-147).
      await seed();
      await repository.saveStudyOptions(
        deckId: 'd1',
        cardLimit: StudyCardLimit.fromStored(30),
        newCardOrder: NewCardOrder.random,
      );

      expect((await repository.effectiveOptions('d1')).isRootOverride, isTrue);
      expect((await repository.effectiveOptions('d1a')).isRootOverride, isTrue);
    });

    test('a config that cannot be parsed reports no override', () async {
      // Read from the parsed result, not from `study_config != null`: a
      // malformed column resolves to the app defaults, and reporting an
      // override anyway would offer a `Use app defaults` that changes nothing
      // the user can see.
      await seed();
      await db.customStatement(
        "UPDATE decks SET study_config = 'not json' WHERE id = 'd1'",
      );

      final options = await repository.effectiveOptions('d1');

      expect(options.isRootOverride, isFalse);
      expect(options.cardLimit, kDefaultCardLimit);
    });
  });

  group('clearStudyOptionsOverride', () {
    test('puts the deck back on the app defaults', () async {
      await seed();
      await repository.saveStudyOptions(
        deckId: 'd1',
        cardLimit: StudyCardLimit.fromStored(30),
        newCardOrder: NewCardOrder.random,
      );

      await ClearStudyOptionsOverrideUseCase(repository).call('d1');

      final options = await repository.effectiveOptions('d1');
      expect(await studyConfigOf('d1'), isNull);
      expect(options.cardLimit, kDefaultCardLimit);
      expect(options.newCardOrder, NewCardOrder.created);
      expect(options.isRootOverride, isFalse);
    });

    test('clearing from a sub-deck lands on the root', () async {
      // The same resolution `saveStudyOptions` does. Without it, clearing from
      // one level down would write NULL onto a column that was already NULL and
      // leave the root's override standing.
      await seed();
      await repository.saveStudyOptions(
        deckId: 'd1',
        cardLimit: StudyCardLimit.fromStored(30),
        newCardOrder: NewCardOrder.random,
      );

      await ClearStudyOptionsOverrideUseCase(repository).call('d1a');

      expect(await studyConfigOf('d1'), isNull);
      expect(await studyConfigOf('d1a'), isNull);
    });

    test('it is not Reset learning progress', () async {
      // BR-212, and the negative half is the point: the two actions are one
      // word apart in English and nothing else in this app is.
      await seed();
      await repository.saveStudyOptions(
        deckId: 'd1',
        cardLimit: StudyCardLimit.fromStored(30),
        newCardOrder: NewCardOrder.random,
      );
      final before = await stateOf('c0');

      await ClearStudyOptionsOverrideUseCase(repository).call('d1');

      final deck = await db
          .customSelect("SELECT * FROM decks WHERE id = 'd1'")
          .getSingle();

      expect(await stateOf('c0'), before);
      expect(deck.data['scheduler_generation'], 1);
      expect(deck.data['first_answered_at'], 5);
      expect(deck.data['scheduler_type'], 'eight_box');
    });

    test(
      'clearing a deck that has no override is a no-op, not an error',
      () async {
        // The UI hides the action, so this is the lower layer holding for a deep
        // link and for a tree that changed after the screen opened.
        await seed();

        await ClearStudyOptionsOverrideUseCase(repository).call('d1');

        expect(await studyConfigOf('d1'), isNull);
      },
    );

    test(
      'a deck that no longer exists is refused with a typed failure',
      () async {
        await seed();

        await expectLater(
          ClearStudyOptionsOverrideUseCase(repository).call('gone'),
          throwsA(isA<NotFoundFailure>()),
        );
      },
    );
  });
}
