import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/mappers/card_mapper.dart';
import 'package:memox/features/card/data/mappers/card_study_state_mapper.dart';
import 'package:memox/features/deck/data/mappers/deck_mapper.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

/// Row→entity mapping for the Deck/Card vertical.
///
/// The rows here are constructed directly — mapping is a pure function of the
/// row, and the repository integration tests already prove the rows themselves
/// come out of a real database.
void main() {
  final utcInstant = DateTime.utc(2026, 7, 29, 12);
  // What drift actually hands back: local-time DateTimes. The mapper must
  // hand out UTC regardless.
  final localInstant = utcInstant.toLocal();

  Deck buildRootRow({String schedulerType = 'eight_box'}) => Deck(
    id: 'root',
    name: 'Root',
    rootDeckId: 'root',
    contentType: 'deck',
    schedulerType: schedulerType,
    schedulerVersion: 1,
    schedulerGeneration: 3,
    siblingPosition: 0,
    firstAnsweredAt: localInstant,
    createdAt: localInstant,
    updatedAt: localInstant,
  );

  group('deck rows', () {
    test('maps a root deck', () {
      final entity = deckEntityFromRow(buildRootRow());

      expect(entity.id, 'root');
      expect(entity.name, 'Root');
      expect(entity.parentDeckId, isNull);
      expect(entity.isRoot, isTrue);
      expect(entity.rootDeckId, 'root');
      expect(entity.contentType, DeckContentType.deck);
      expect(entity.schedulerType, SchedulerType.eightBox);
      expect(entity.schedulerGeneration, 3);
      expect(entity.firstAnsweredAt, utcInstant);
    });

    test('maps a sub-deck, nullable fields staying null', () {
      final entity = deckEntityFromRow(
        Deck(
          id: 'child',
          name: 'Child',
          parentDeckId: 'root',
          rootDeckId: 'root',
          contentType: 'unset',
          siblingPosition: 0,
          createdAt: localInstant,
          updatedAt: localInstant,
        ),
      );

      expect(entity.isRoot, isFalse);
      expect(entity.contentType, DeckContentType.unset);
      expect(entity.schedulerType, isNull);
      expect(entity.schedulerGeneration, isNull);
      expect(entity.firstAnsweredAt, isNull);
    });

    test('timestamps come out in UTC even when the row is local time', () {
      final entity = deckEntityFromRow(buildRootRow());

      expect(entity.createdAt.isUtc, isTrue);
      expect(entity.updatedAt.isUtc, isTrue);
      expect(entity.firstAnsweredAt!.isUtc, isTrue);
      // Same instant — conversion must not shift the moment.
      expect(entity.createdAt, utcInstant);
    });

    test('an unknown scheduler type reads as unknown instead of crashing', () {
      final entity = deckEntityFromRow(buildRootRow(schedulerType: 'sm18'));

      expect(entity.schedulerType, SchedulerType.unknown);
    });

    test('an unknown content type reads as unknown instead of crashing', () {
      final entity = deckEntityFromRow(
        Deck(
          id: 'weird',
          name: 'Weird',
          parentDeckId: 'root',
          rootDeckId: 'root',
          contentType: 'mixed',
          siblingPosition: 0,
          createdAt: localInstant,
          updatedAt: localInstant,
        ),
      );

      expect(entity.contentType, DeckContentType.unknown);
    });
  });

  group('card rows', () {
    test('maps content and UTC timestamps', () {
      final entity = cardEntityFromRow(
        Card(
          id: 'card-1',
          deckId: 'leaf',
          front: 'Front Text',
          back: 'Back Text',
          // Folded columns exist from schema v3 and hold the search form. The
          // mapper must read the original columns, not these.
          frontFolded: 'front text',
          backFolded: 'back text',
          isFlagged: 0,
          createdAt: localInstant,
          updatedAt: localInstant,
        ),
      );

      expect(entity.id, 'card-1');
      expect(entity.deckId, 'leaf');
      expect(entity.front, 'Front Text');
      expect(entity.back, 'Back Text');
      expect(entity.createdAt.isUtc, isTrue);
      expect(entity.updatedAt, utcInstant);
    });
  });

  group('card study state rows', () {
    test('maps an eight_box state', () {
      final entity = cardStudyStateEntityFromRow(
        const CardStudyState(
          cardId: 'card-1',
          schedulerType: 'eight_box',
          schedulerVersion: 1,
          schedulerGeneration: 1,
          answerCount: 0,
          lapseCount: 0,
          currentBox: 1,
        ),
      );

      expect(entity.schedulerType, SchedulerType.eightBox);
      expect(entity.currentBox, 1);
      expect(entity.easeFactor, isNull);
      expect(entity.intervalDays, isNull);
      expect(entity.repetitions, isNull);
      expect(entity.dueAt, isNull);
      expect(entity.lastAnsweredAt, isNull);
    });

    test('maps an sm2 state, and due_at in UTC', () {
      final entity = cardStudyStateEntityFromRow(
        CardStudyState(
          cardId: 'card-2',
          schedulerType: 'sm2',
          schedulerVersion: 1,
          schedulerGeneration: 2,
          dueAt: localInstant,
          answerCount: 4,
          lapseCount: 1,
          easeFactor: 2.5,
          intervalDays: 0,
          repetitions: 0,
        ),
      );

      expect(entity.schedulerType, SchedulerType.sm2);
      expect(entity.schedulerGeneration, 2);
      expect(entity.currentBox, isNull);
      expect(entity.easeFactor, 2.5);
      expect(entity.intervalDays, 0);
      expect(entity.repetitions, 0);
      expect(entity.dueAt, utcInstant);
      expect(entity.dueAt!.isUtc, isTrue);
    });

    test('an unknown scheduler type reads as unknown', () {
      final entity = cardStudyStateEntityFromRow(
        const CardStudyState(
          cardId: 'card-3',
          schedulerType: 'leitner9',
          schedulerVersion: 9,
          schedulerGeneration: 1,
          answerCount: 0,
          lapseCount: 0,
        ),
      );

      expect(entity.schedulerType, SchedulerType.unknown);
    });
  });

  group('write direction refuses unknown', () {
    test('mapping unknown back to a database value fails fast', () {
      expect(() => SchedulerType.unknown.dbValue, throwsStateError);
      expect(() => DeckContentType.unknown.dbValue, throwsStateError);
    });

    test('no real enum value serialises to the literal string unknown', () {
      // Belt and braces for the fail-fast above: even if a write slipped
      // through, no storable value spells 'unknown'.
      final storable = <String>[
        SchedulerType.eightBox.dbValue,
        SchedulerType.sm2.dbValue,
        DeckContentType.unset.dbValue,
        DeckContentType.card.dbValue,
        DeckContentType.deck.dbValue,
      ];

      expect(storable, isNot(contains('unknown')));
    });
  });

  group('the ancestor chain', () {
    // The one untyped column in the deck reads. Its whole contract is here,
    // because a JSON string is exactly the shape the compiler cannot check.
    test('is ordered root first, whatever order the rows arrive in', () {
      // SQLite does not promise the order an aggregate consumes its input, so
      // the distance is what orders the chain — not the array. Fed backwards on
      // purpose.
      final path = deckPathFromJson(
        '[{"id":"b","name":"Branch","distance":1},'
        '{"id":"a","name":"Root","distance":2}]',
      );

      expect(path.map((s) => s.name), <String>['Root', 'Branch']);
    });

    test('an empty chain is a deck one level down, not a failure', () {
      // A root deck opened from the list: its ancestry is genuinely nothing.
      expect(deckPathFromJson('[]'), isEmpty);
    });

    test('malformed JSON yields no path rather than killing the level', () {
      // A breadcrumb is chrome. The counts, the rows and the title in the same
      // read are unaffected by whatever went wrong here, so failing the whole
      // level would throw away nine correct facts to punish one.
      expect(deckPathFromJson('not json at all'), isEmpty);
      expect(deckPathFromJson(''), isEmpty);
    });

    test('a valid JSON value of the wrong shape yields no path', () {
      expect(deckPathFromJson('{"id":"a"}'), isEmpty);
      expect(deckPathFromJson('null'), isEmpty);
      expect(deckPathFromJson('42'), isEmpty);
    });

    test('an unusable entry is dropped and the rest survive', () {
      // Partial damage should cost the damaged step, not the path. A missing
      // name is the realistic case: a column renamed under an old build.
      final path = deckPathFromJson(
        '[{"id":"a","name":"Root","distance":2},'
        '{"id":"b","distance":1},'
        '{"id":"c","name":"Leaf","distance":0}]',
      );

      expect(path.map((s) => s.id), <String>['a', 'c']);
    });

    test('a name is carried verbatim, delimiters and all', () {
      // The reason this column is JSON rather than two group_concat strings:
      // BR-01 lets a deck be called anything, so no separator is safe.
      final path = deckPathFromJson(
        '[{"id":"a","name":"N5, N4 | \\"quoted\\"","distance":1}]',
      );

      expect(path.single.name, 'N5, N4 | "quoted"');
    });
  });
}
