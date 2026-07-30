import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/card_mapper.dart';
import 'package:memox/features/card/data/card_review_state_mapper.dart';
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
    firstReviewAt: localInstant,
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
      expect(entity.firstReviewAt, utcInstant);
    });

    test('maps a sub-deck, nullable fields staying null', () {
      final entity = deckEntityFromRow(
        Deck(
          id: 'child',
          name: 'Child',
          parentDeckId: 'root',
          rootDeckId: 'root',
          contentType: 'unset',
          createdAt: localInstant,
          updatedAt: localInstant,
        ),
      );

      expect(entity.isRoot, isFalse);
      expect(entity.contentType, DeckContentType.unset);
      expect(entity.schedulerType, isNull);
      expect(entity.schedulerGeneration, isNull);
      expect(entity.firstReviewAt, isNull);
    });

    test('timestamps come out in UTC even when the row is local time', () {
      final entity = deckEntityFromRow(buildRootRow());

      expect(entity.createdAt.isUtc, isTrue);
      expect(entity.updatedAt.isUtc, isTrue);
      expect(entity.firstReviewAt!.isUtc, isTrue);
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
          front: 'front text',
          back: 'back text',
          createdAt: localInstant,
          updatedAt: localInstant,
        ),
      );

      expect(entity.id, 'card-1');
      expect(entity.deckId, 'leaf');
      expect(entity.front, 'front text');
      expect(entity.back, 'back text');
      expect(entity.createdAt.isUtc, isTrue);
      expect(entity.updatedAt, utcInstant);
    });
  });

  group('card review state rows', () {
    test('maps an eight_box state', () {
      final entity = cardReviewStateEntityFromRow(
        const CardReviewState(
          cardId: 'card-1',
          schedulerType: 'eight_box',
          schedulerVersion: 1,
          schedulerGeneration: 1,
          reviewCount: 0,
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
      expect(entity.lastReviewedAt, isNull);
    });

    test('maps an sm2 state, and due_at in UTC', () {
      final entity = cardReviewStateEntityFromRow(
        CardReviewState(
          cardId: 'card-2',
          schedulerType: 'sm2',
          schedulerVersion: 1,
          schedulerGeneration: 2,
          dueAt: localInstant,
          reviewCount: 4,
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
      final entity = cardReviewStateEntityFromRow(
        const CardReviewState(
          cardId: 'card-3',
          schedulerType: 'leitner9',
          schedulerVersion: 9,
          schedulerGeneration: 1,
          reviewCount: 0,
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
}
