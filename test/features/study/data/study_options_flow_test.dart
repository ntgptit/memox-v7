import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/domain/models/study_card_limit_model.dart';
import 'package:memox/features/study/domain/models/study_session_kind_model.dart';
import 'package:memox/features/study/domain/models/study_session_status_model.dart';
import 'package:memox/features/study/domain/usecases/start_study_session_use_case.dart';

import '../../../database/support/test_database.dart';

/// The two tiers of study options, against a real database (BR-147, BR-148).
///
/// **Its own file rather than another group in `study_flow_test.dart`.** That
/// file is about one session running end to end; this one is about a preference
/// that outlives every session, and the two share only a seeded deck. Splitting
/// at the 400-line guard is what prompted it, but the seam was already there.
void main() {
  final now = DateTime.utc(2026, 8, 7, 2); // 09:00 in Hanoi.
  const vietnam = Duration(hours: 7);

  late AppDatabase db;
  late StudyRepositoryImpl repository;
  var idCounter = 0;

  setUp(() {
    db = openTestDatabase();
    idCounter = 0;
    repository = StudyRepositoryImpl(
      StudyDao(db),
      idGenerator: () => 'id-${idCounter++}',
      random: Random(11),
    );
  });

  tearDown(() => db.close());

  /// A root deck on `eight_box`, and [cardCount] cards.
  Future<void> seed({required int cardCount}) async {
    await db.customStatement(
      'INSERT INTO decks (id, name, root_deck_id, content_type, '
      'scheduler_type, scheduler_version, scheduler_generation, '
      'created_at, updated_at) '
      "VALUES ('d1', 'Korean', 'd1', 'card', 'eight_box', 1, 1, 0, 0)",
    );

    for (var i = 0; i < cardCount; i++) {
      await db.customStatement(
        'INSERT INTO cards (id, deck_id, front, back, front_folded, '
        'back_folded, example, created_at, updated_at) '
        "VALUES ('c$i', 'd1', 'f$i', 'b$i', 'f$i', 'b$i', 'ex$i', $i, $i)",
      );
      await db.customStatement(
        'INSERT INTO card_study_states (card_id, scheduler_type, '
        'scheduler_version, scheduler_generation, answer_count, lapse_count, '
        "current_box) VALUES ('c$i', 'eight_box', 1, 1, 0, 0, 1)",
      );
    }
  }

  group('the two tiers of study options', () {
    /// A sub-deck under `d1`, which is where BR-147 is actually tested: a deck
    /// one level down must carry no options of its own and resolve to the root.
    Future<void> seedSubDeck() => db.customStatement(
      'INSERT INTO decks (id, name, parent_deck_id, root_deck_id, '
      'content_type, created_at, updated_at) '
      "VALUES ('d1a', 'Unit 1', 'd1', 'd1', 'card', 0, 0)",
    );

    Future<String?> studyConfigOf(String deckId) async {
      final row = await db
          .customSelect(
            "SELECT study_config AS c FROM decks WHERE id = '$deckId'",
          )
          .getSingle();

      return row.read<String?>('c');
    }

    test('with no override the app defaults are in force', () async {
      await seed(cardCount: 1);

      final options = await repository.effectiveOptions('d1');

      expect(options.cardLimit, kDefaultCardLimit);
      expect(options.newCardOrder, NewCardOrder.created);
    });

    test('saving from a sub-deck writes on the root (BR-147)', () async {
      // The invariant that would otherwise depend on which screen the user had
      // open: options belong to the root, so a sub-deck must be left NULL no
      // matter where the edit came from.
      await seed(cardCount: 1);
      await seedSubDeck();

      await repository.saveStudyOptions(
        deckId: 'd1a',
        cardLimit: StudyCardLimit.fromStored(30),
        newCardOrder: NewCardOrder.random,
      );

      expect(await studyConfigOf('d1a'), isNull);
      expect(await studyConfigOf('d1'), isNotNull);
    });

    test('a sub-deck reads the root-s override, not nothing', () async {
      await seed(cardCount: 1);
      await seedSubDeck();

      await repository.saveStudyOptions(
        deckId: 'd1',
        cardLimit: StudyCardLimit.fromStored(30),
        newCardOrder: NewCardOrder.random,
      );

      final options = await repository.effectiveOptions('d1a');

      expect(options.cardLimit, 30);
      expect(options.newCardOrder, NewCardOrder.random);
    });

    test(
      'a config that cannot be read falls back, and studying still works',
      () async {
        // The whole point of the tolerant parse: a malformed preference is not a
        // reason a deck cannot be opened.
        await seed(cardCount: 2);
        await db.customStatement(
          "UPDATE decks SET study_config = 'not json' WHERE id = 'd1'",
        );

        final options = await repository.effectiveOptions('d1');
        final session = await StartStudySessionUseCase(repository).call(
          deckId: 'd1',
          kind: StudySessionKind.learning,
          now: now,
          utcOffset: vietnam,
        );

        expect(options.cardLimit, kDefaultCardLimit);
        expect(session.session.cardLimit, kDefaultCardLimit);
      },
    );

    test('the session keeps the ceiling it opened with (BR-139)', () async {
      // Changing the preference mid-session must not move the finish line the
      // user is already walking towards.
      await seed(cardCount: 3);

      final session = await StartStudySessionUseCase(repository).call(
        deckId: 'd1',
        kind: StudySessionKind.learning,
        now: now,
        utcOffset: vietnam,
      );

      await repository.saveStudyOptions(
        deckId: 'd1',
        cardLimit: StudyCardLimit.fromStored(1),
        newCardOrder: NewCardOrder.created,
      );

      final stored = await db
          .customSelect(
            "SELECT card_limit AS l FROM study_sessions WHERE id = '"
            "${session.session.id}'",
          )
          .getSingle();

      expect(stored.read<int>('l'), kDefaultCardLimit);
      expect((await repository.effectiveOptions('d1')).cardLimit, 1);
    });

    test('random picks a different set than created (BR-148)', () async {
      // **Selection, not presentation order** — and the difference is the rule,
      // not the test-s convenience. BR-113 gives every stage its own shuffle,
      // so the order of the session card list never reaches the user. The only
      // thing `new_card_order` can decide is which new cards enter the session
      // when the deck has more than the ceiling.
      //
      // A limit below the card count is therefore the only setup in which this
      // option is observable at all. With ten cards and a ceiling of twenty,
      // both orderings take the same ten and the assertion would pass on an
      // implementation that ignored the option entirely — which is exactly what
      // the first version of this test did.
      await seed(cardCount: 10);
      await repository.saveStudyOptions(
        deckId: 'd1',
        cardLimit: StudyCardLimit.fromStored(3),
        newCardOrder: NewCardOrder.created,
      );

      final inOrder = await StartStudySessionUseCase(repository).call(
        deckId: 'd1',
        kind: StudySessionKind.learning,
        now: now,
        utcOffset: vietnam,
      );
      final createdIds = (await repository.sessionCards(
        inOrder.session.id,
      )).map((card) => card.id).toSet();

      await repository.endSession(
        sessionId: inOrder.session.id,
        status: StudySessionStatus.abandoned,
        reason: StudySessionEndReason.userExit,
        endedAt: now,
      );
      await repository.saveStudyOptions(
        deckId: 'd1',
        cardLimit: StudyCardLimit.fromStored(3),
        newCardOrder: NewCardOrder.random,
      );

      final shuffled = await StartStudySessionUseCase(repository).call(
        deckId: 'd1',
        kind: StudySessionKind.learning,
        now: now,
        utcOffset: vietnam,
      );
      final randomIds = (await repository.sessionCards(
        shuffled.session.id,
      )).map((card) => card.id).toSet();

      // `created` always takes the three oldest.
      expect(createdIds, <String>{'c0', 'c1', 'c2'});
      expect(randomIds, hasLength(3));
      expect(randomIds, isNot(createdIds));
    });
  });
}
